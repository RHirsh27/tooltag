import Foundation
import Combine

typealias SOPDTO = LLMGenerationResponse

protocol LLMService {
    func request(
        rawText: String,
        titleHint: String?,
        includeTools: Bool,
        maxSteps: Int,
        tone: String
    ) async -> Result<SOPDTO, LLMError>

    func generateSOP(from request: LLMGenerationRequest) async throws -> LLMGenerationResponse
}

struct LLMGenerationRequest: Sendable {
    let rawText: String
    let titleHint: String?
    let includeTools: Bool
    let maxSteps: Int
    let tone: String
}

enum LLMModel: String, CaseIterable {
    case gpt4o_mini = "gpt-4o-mini"
    case gpt4o = "gpt-4o"
    case o3_mini = "o3-mini"
}

struct LLMGenerationResponse: Codable, Sendable {
    let title: String
    let summary: String
    let toolsNeeded: [String]
    let steps: [LLMStep]
    let warnings: [String]
    let tags: [String]

    struct LLMStep: Codable, Hashable, Sendable {
        let number: Int
        let instruction: String
        let notes: String?
        let estMinutes: Int?
    }
}

enum LLMError: Error, Equatable {
    case missingAPIKey
    case noAPIKey
    case unauthorized
    case rateLimited
    case unauthorizedOrRateLimited
    case rateLimitedLocal
    case invalidJSON
    case invalidResponse
    case timeout
    case transport
    case server(Int)
    case circuitBreaker
}

extension LLMError {
    var userMessage: String {
        switch self {
        case .noAPIKey:
            return NSLocalizedString("Add an AI key in Settings to generate steps.", comment: "No API key")
        case .missingAPIKey:
            return NSLocalizedString("Add your AI API key in Settings before generating.", comment: "Missing API key")
        case .unauthorized:
            return NSLocalizedString("Your AI credentials were rejected. Please update them.", comment: "Unauthorized")
        case .rateLimited:
            return NSLocalizedString("High demand detected. Please retry in a few seconds.", comment: "Rate limited")
        case .unauthorizedOrRateLimited:
            return NSLocalizedString("Key invalid or rate-limited. Try again or check your plan.", comment: "Unauthorized or rate limited")
        case .rateLimitedLocal:
            return NSLocalizedString("You're going too fast. Please wait a moment.", comment: "Local rate limited")
        case .invalidJSON, .invalidResponse:
            return NSLocalizedString("We could not understand the AI response. Please retry.", comment: "Invalid response")
        case .timeout:
            return NSLocalizedString("The AI call is taking too long. Check your connection and retry.", comment: "Timeout")
        case .transport, .server:
            return NSLocalizedString("Network issue. We'll retry automatically.", comment: "Network error")
        case .circuitBreaker:
            return NSLocalizedString("The AI service is busy. We'll retry shortly.", comment: "Circuit breaker user message")
        }
    }

    var analyticsReason: String {
        switch self {
        case .noAPIKey: return "no_api_key"
        case .missingAPIKey: return "missing_key"
        case .unauthorized: return "unauthorized"
        case .rateLimited: return "rate_limited"
        case .unauthorizedOrRateLimited: return "unauthorized_or_rate_limited"
        case .rateLimitedLocal: return "rate_limited_local"
        case .invalidJSON: return "invalid_json"
        case .invalidResponse: return "invalid_response"
        case .timeout: return "timeout"
        case .transport: return "transport"
        case .server(let code): return "server_\(code)"
        case .circuitBreaker: return "circuit_breaker"
        }
    }

    var isRetriable: Bool {
        switch self {
        case .server, .timeout, .transport, .invalidJSON, .unauthorizedOrRateLimited:
            return true
        default:
            return false
        }
    }
}

final class DefaultLLMService: LLMService, ObservableObject {
    @Published var activeModel: LLMModel = .gpt4o_mini
    private let session: URLSession
    private let apiKeyProvider: () -> String?
    private let baseURL: URL
    private let metrics: MetricsReporter
    private let validator: JSONValidating
    private let rateLimiter = TokenBucket(maxTokens: 5, refillInterval: 60)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let modelName: String
    private let maxLatencySamples = 50
    @MainActor private var latencySamples: [TimeInterval] = []
    @MainActor private var serverErrorTimestamps: [Date] = []
    private let circuitBreakerThreshold = 5
    private let circuitBreakerWindow: TimeInterval = 300 // 5 minutes

    init(
        metrics: MetricsReporter,
        apiKeyProvider: @escaping () -> String?,
        baseURL: URL = URL(string: "https://api.openai.com/v1")!,
        modelName: String = "gpt-4o-mini",
        session: URLSession? = nil,
        validator: JSONValidating = JSONSchemaValidator()
    ) {
        self.metrics = metrics
        self.apiKeyProvider = apiKeyProvider
        self.baseURL = baseURL
        self.modelName = modelName
        self.validator = validator

        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 12
            configuration.timeoutIntervalForResource = 12
            configuration.waitsForConnectivity = true
            self.session = URLSession(configuration: configuration)
        }
    }

    convenience init(metrics: MetricsReporter) {
        self.init(
            metrics: metrics,
            apiKeyProvider: { KeychainStore.string(for: KeychainStore.Key.llmAPIKey) }
        )
    }

    func request(
        rawText: String,
        titleHint: String?,
        includeTools: Bool,
        maxSteps: Int,
        tone: String
    ) async -> Result<SOPDTO, LLMError> {
        guard rateLimiter.consume() else {
            return .failure(.rateLimitedLocal)
        }
        
        guard let apiKey = apiKeyProvider(), apiKey.isEmpty == false else {
            return .failure(.noAPIKey)
        }

        let processedText = PromptBuilder.make(from: rawText, locale: .current, style: .sop)
        let payload = PromptContract.makeUserPayload(
            rawText: processedText,
            titleHint: titleHint,
            includeTools: includeTools,
            maxSteps: maxSteps,
            tone: tone
        )

        guard let userJSON = try? encoder.encode(payload),
              let userJSONString = String(data: userJSON, encoding: .utf8) else {
            return .failure(.invalidJSON)
        }

        let chatRequest = OpenAIChatRequest(
            model: activeModel.rawValue,
            messages: [
                .init(role: "system", content: PromptContract.systemPrompt),
                .init(role: "user", content: userJSONString)
            ],
            temperature: 0.2,
            responseFormat: .init(type: "json_object")
        )

        let callStart = Date()
        let tokensEstimate = TokenEstimator.estimatedTokens(for: rawText)
        var attempt = 0
        var delay: UInt64 = 1_000_000_000 // 1s in nanoseconds
        var lastError: LLMError = .invalidResponse

        let maxRetries = 3
        while attempt < maxRetries {
            attempt += 1
            let attemptStart = Date()
            do {
                let requestData = try encoder.encode(chatRequest)
                var urlRequest = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
                urlRequest.httpMethod = "POST"
                urlRequest.httpBody = requestData
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                urlRequest.timeoutInterval = 12

                let (data, response) = try await session.data(for: urlRequest)
                guard let http = response as? HTTPURLResponse else {
                    lastError = .invalidResponse
                    if attempt < maxRetries && lastError.isRetriable {
                        try? await Task.sleep(nanoseconds: delay)
                        delay = min(delay * 2, 2_000_000_000) // Cap at 2s
                        continue
                    }
                    throw lastError
                }

                switch http.statusCode {
                case 200..<300:
                    do {
                        let dto = try parseResponse(data)
                        let responseDate = Date()
                        let latency = responseDate.timeIntervalSince(attemptStart) * 1000
                        let totalDuration = responseDate.timeIntervalSince(callStart)
                        await MainActor.run {
                            metrics.track(event: .sopGenerated(tokensIn: tokensEstimate, steps: dto.steps.count))
                            metrics.track(event: .generationLatencySample(milliseconds: latency))
                            recordLatencySample(duration: totalDuration)
                        }
                        return .success(dto)
                    } catch {
                        lastError = .invalidJSON
                        if attempt < maxRetries && lastError.isRetriable {
                            try? await Task.sleep(nanoseconds: delay)
                            delay = min(delay * 2, 2_000_000_000) // Cap at 2s
                            continue
                        }
                        throw lastError
                    }
                case 401, 429:
                    return .failure(.unauthorizedOrRateLimited)
                case 500..<600:
                    lastError = .server(http.statusCode)
                    if attempt < maxRetries && lastError.isRetriable {
                        try? await Task.sleep(nanoseconds: delay)
                        delay = min(delay * 2, 2_000_000_000) // Cap at 2s
                        continue
                    }
                    throw lastError
                default:
                    lastError = .invalidResponse
                    return .failure(.invalidResponse)
                }
            } catch {
                let mappedError: LLMError
                if let error = error as? LLMError {
                    mappedError = error
                } else if let urlError = error as? URLError {
                    if urlError.code == .timedOut {
                        mappedError = .timeout
                    } else {
                        mappedError = .transport
                    }
                } else {
                    mappedError = .transport
                }

                lastError = mappedError

                if case .server = mappedError {
                    if await recordServerErrorAndCheckBreaker() {
                        await MainActor.run {
                            metrics.track(event: .error(type: .llm, context: "circuit_breaker"))
                        }
                        return .failure(.circuitBreaker)
                    }
                }

                if mappedError.isRetriable && attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: delay)
                    delay = min(delay * 2, 2_000_000_000) // Cap at 2s
                    continue
                }

                return .failure(mappedError)
            }
        }

        return .failure(lastError)
    }

    func generateSOP(from request: LLMGenerationRequest) async throws -> LLMGenerationResponse {
        let result = await self.request(
            rawText: request.rawText,
            titleHint: request.titleHint,
            includeTools: request.includeTools,
            maxSteps: request.maxSteps,
            tone: request.tone
        )

        switch result {
        case .success(let dto):
            return dto
        case .failure(let error):
            throw error
        }
    }

    @MainActor
    private func recordLatencySample(duration: TimeInterval) {
        latencySamples.append(duration)
        if latencySamples.count > maxLatencySamples {
            latencySamples.removeFirst(latencySamples.count - maxLatencySamples)
        }
        let sortedSamples = latencySamples.sorted()
        let p50 = percentile(from: sortedSamples, percentile: 0.5)
        let p90 = percentile(from: sortedSamples, percentile: 0.9)
        MetricsService.genLatency(p50: p50, p90: p90)
    }

    private func percentile(from sortedSamples: [TimeInterval], percentile: Double) -> TimeInterval {
        guard sortedSamples.isEmpty == false else { return 0 }
        let clampedPercentile = min(max(percentile, 0), 1)
        let position = clampedPercentile * Double(sortedSamples.count - 1)
        let lowerIndex = Int(position.rounded(.down))
        let upperIndex = Int(position.rounded(.up))
        if lowerIndex == upperIndex {
            return sortedSamples[lowerIndex]
        }
        let lower = sortedSamples[lowerIndex]
        let upper = sortedSamples[upperIndex]
        let weight = position - Double(lowerIndex)
        return lower + (upper - lower) * weight
    }

    private func parseResponse(_ data: Data) throws -> LLMGenerationResponse {
        let chatResponse = try decoder.decode(OpenAIChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content,
              let jsonString = extractJSON(from: content),
              let jsonData = jsonString.data(using: .utf8) else {
            throw LLMError.invalidJSON
        }

        try validator.validate(jsonData)
        let promptResponse = try decoder.decode(PromptResponse.self, from: jsonData)
        return LLMGenerationResponse(
            title: promptResponse.title,
            summary: promptResponse.summary,
            toolsNeeded: promptResponse.tools_needed,
            steps: promptResponse.steps.map {
                LLMGenerationResponse.LLMStep(
                    number: $0.number,
                    instruction: $0.instruction,
                    notes: $0.notes,
                    estMinutes: $0.est_minutes
                )
            },
            warnings: promptResponse.warnings,
            tags: promptResponse.tags
        )
    }

    private func extractJSON(from content: String) -> String? {
        if content.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let firstBrace = content.firstIndex(of: "{"),
              let lastBrace = content.lastIndex(of: "}") else {
            return nil
        }
        let range = firstBrace...lastBrace
        return String(content[range])
    }
}

private struct OpenAIChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case responseFormat = "response_format"
    }
}

private struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

private enum TokenEstimator {
    static func estimatedTokens(for text: String) -> Int {
        max(1, text.count / 4)
    }
}

private class TokenBucket {
    private let maxTokens: Int
    private let refillInterval: TimeInterval
    private var tokens: Int
    private var lastRefill: Date
    
    init(maxTokens: Int, refillInterval: TimeInterval) {
        self.maxTokens = maxTokens
        self.refillInterval = refillInterval
        self.tokens = maxTokens
        self.lastRefill = Date()
    }
    
    func consume() -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastRefill) >= refillInterval {
            tokens = maxTokens
            lastRefill = now
        }
        guard tokens > 0 else { return false }
        tokens -= 1
        return true
    }
}
    private func recordServerErrorAndCheckBreaker() async -> Bool {
        return await MainActor.run { () -> Bool in
            let now = Date()
            serverErrorTimestamps.append(now)
            serverErrorTimestamps = serverErrorTimestamps.filter { now.timeIntervalSince($0) <= circuitBreakerWindow }
            return serverErrorTimestamps.count >= circuitBreakerThreshold
        }
    }

    private func resetCircuitBreaker() async {
        await MainActor.run {
            serverErrorTimestamps.removeAll()
        }
    }
