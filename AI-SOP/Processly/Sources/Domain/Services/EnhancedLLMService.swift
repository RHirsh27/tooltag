import Foundation
import Combine

enum LLMProvider: String, CaseIterable {
    case openai = "openai"
    case anthropic = "anthropic"
    
    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }
}

@MainActor
final class EnhancedLLMService: LLMService, ObservableObject {
    @Published var activeProvider: LLMProvider = .openai
    @Published var activeModel: LLMModel = .gpt4o_mini
    
    private let session: URLSession
    private let openAIKeyProvider: () -> String?
    private let anthropicKeyProvider: () -> String?
    private let metrics: MetricsReporter
    private let validator: JSONValidating
    private let rateLimiter = TokenBucket(maxTokens: 5, refillInterval: 60)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let maxLatencySamples = 50
    private var latencySamples: [TimeInterval] = []
    private var serverErrorTimestamps: [Date] = []
    private let circuitBreakerThreshold = 5
    private let circuitBreakerWindow: TimeInterval = 300 // 5 minutes
    
    init(
        metrics: MetricsReporter,
        openAIKeyProvider: @escaping () -> String? = { KeychainStore.string(for: KeychainStore.Key.llmAPIKey) },
        anthropicKeyProvider: @escaping () -> String? = { KeychainStore.string(for: KeychainStore.Key.anthropicAPIKey) },
        session: URLSession? = nil,
        validator: JSONValidating = JSONSchemaValidator()
    ) {
        self.metrics = metrics
        self.openAIKeyProvider = openAIKeyProvider
        self.anthropicKeyProvider = anthropicKeyProvider
        self.validator = validator
        
        if let session = session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 30
            configuration.waitsForConnectivity = true
            self.session = URLSession(configuration: configuration)
        }
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
        
        let apiKey: String
        let baseURL: URL
        let modelName: String
        
        switch activeProvider {
        case .openai:
            guard let key = openAIKeyProvider(), !key.isEmpty else {
                return .failure(.noAPIKey)
            }
            apiKey = key
            baseURL = URL(string: "https://api.openai.com/v1")!
            modelName = activeModel.rawValue
            
        case .anthropic:
            guard let key = anthropicKeyProvider(), !key.isEmpty else {
                return .failure(.noAPIKey)
            }
            apiKey = key
            baseURL = URL(string: "https://api.anthropic.com/v1")!
            modelName = activeModel.rawValue
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
                let result = try await makeAPICall(
                    baseURL: baseURL,
                    apiKey: apiKey,
                    modelName: modelName,
                    userContent: userJSONString
                )
                
                let responseDate = Date()
                let latency = responseDate.timeIntervalSince(attemptStart) * 1000
                let totalDuration = responseDate.timeIntervalSince(callStart)
                
                metrics.track(event: .sopGenerated, properties: ["tokens_in": tokensEstimate, "steps": result.steps.count])
                metrics.track(event: .generationLatencySample, properties: ["latency_ms": latency])
                recordLatencySample(duration: totalDuration)
                
                return .success(result)
                
            } catch let error as LLMError {
                lastError = error
                
                if case .server = error {
                    if recordServerErrorAndCheckBreaker() {
                        metrics.track(event: .error, properties: ["error_type": "llm", "context": "circuit_breaker"])
                        return .failure(.circuitBreaker)
                    }
                }
                
                if error.isRetriable && attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: delay)
                    delay = min(delay * 2, 2_000_000_000) // Cap at 2s
                    continue
                }
                
                return .failure(error)
                
            } catch {
                let mappedError: LLMError
                if let urlError = error as? URLError {
                    if urlError.code == .timedOut {
                        mappedError = .timeout
                    } else {
                        mappedError = .transport
                    }
                } else {
                    mappedError = .transport
                }
                
                lastError = mappedError
                
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
    
    // MARK: - Private Methods
    
    private func makeAPICall(
        baseURL: URL,
        apiKey: String,
        modelName: String,
        userContent: String
    ) async throws -> LLMGenerationResponse {
        switch activeProvider {
        case .openai:
            return try await makeOpenAICall(baseURL: baseURL, apiKey: apiKey, modelName: modelName, userContent: userContent)
        case .anthropic:
            return try await makeAnthropicCall(baseURL: baseURL, apiKey: apiKey, modelName: modelName, userContent: userContent)
        }
    }
    
    private func makeOpenAICall(
        baseURL: URL,
        apiKey: String,
        modelName: String,
        userContent: String
    ) async throws -> LLMGenerationResponse {
        let chatRequest = OpenAIChatRequest(
            model: modelName,
            messages: [
                .init(role: "system", content: PromptContract.systemPrompt),
                .init(role: "user", content: userContent)
            ],
            temperature: 0.2,
            responseFormat: .init(type: "json_object")
        )
        
        let requestData = try encoder.encode(chatRequest)
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = 30
        
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        switch http.statusCode {
        case 200..<300:
            return try parseOpenAIResponse(data)
        case 401, 429:
            throw LLMError.unauthorizedOrRateLimited
        case 500..<600:
            throw LLMError.server(http.statusCode)
        default:
            throw LLMError.invalidResponse
        }
    }
    
    private func makeAnthropicCall(
        baseURL: URL,
        apiKey: String,
        modelName: String,
        userContent: String
    ) async throws -> LLMGenerationResponse {
        let anthropicRequest = AnthropicRequest(
            model: modelName,
            max_tokens: 4000,
            messages: [
                .init(role: "user", content: "\(PromptContract.systemPrompt)\n\n\(userContent)")
            ],
            temperature: 0.2
        )
        
        let requestData = try encoder.encode(anthropicRequest)
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("messages"))
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.timeoutInterval = 30
        
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        switch http.statusCode {
        case 200..<300:
            return try parseAnthropicResponse(data)
        case 401, 429:
            throw LLMError.unauthorizedOrRateLimited
        case 500..<600:
            throw LLMError.server(http.statusCode)
        default:
            throw LLMError.invalidResponse
        }
    }
    
    private func parseOpenAIResponse(_ data: Data) throws -> LLMGenerationResponse {
        let chatResponse = try decoder.decode(OpenAIChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content,
              let jsonString = extractJSON(from: content),
              let jsonData = jsonString.data(using: .utf8) else {
            throw LLMError.invalidJSON
        }
        
        try validator.validate(jsonData)
        let promptResponse = try decoder.decode(PromptResponse.self, from: jsonData)
        return convertToLLMResponse(promptResponse)
    }
    
    private func parseAnthropicResponse(_ data: Data) throws -> LLMGenerationResponse {
        let anthropicResponse = try decoder.decode(AnthropicResponse.self, from: data)
        guard let content = anthropicResponse.content.first?.text,
              let jsonString = extractJSON(from: content),
              let jsonData = jsonString.data(using: .utf8) else {
            throw LLMError.invalidJSON
        }
        
        try validator.validate(jsonData)
        let promptResponse = try decoder.decode(PromptResponse.self, from: jsonData)
        return convertToLLMResponse(promptResponse)
    }
    
    private func convertToLLMResponse(_ promptResponse: PromptResponse) -> LLMGenerationResponse {
        return LLMGenerationResponse(
            title: promptResponse.title,
            summary: promptResponse.summary,
            toolsNeeded: promptResponse.tools_needed,
            steps: promptResponse.steps.map { step in
                LLMGenerationResponse.LLMStep(
                    number: step.number,
                    instruction: step.instruction,
                    notes: step.notes,
                    estMinutes: step.est_minutes
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
    
    private func recordServerErrorAndCheckBreaker() -> Bool {
        let now = Date()
        serverErrorTimestamps.append(now)
        serverErrorTimestamps = serverErrorTimestamps.filter { now.timeIntervalSince($0) <= circuitBreakerWindow }
        return serverErrorTimestamps.count >= circuitBreakerThreshold
    }
}

// MARK: - API Request/Response Models

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

private struct AnthropicRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }
    
    let model: String
    let max_tokens: Int
    let messages: [Message]
    let temperature: Double
}

private struct AnthropicResponse: Decodable {
    struct Content: Decodable {
        let text: String
    }
    
    let content: [Content]
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
