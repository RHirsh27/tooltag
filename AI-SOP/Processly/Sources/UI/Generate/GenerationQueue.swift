import Foundation
import Combine

struct GenerationJob: Identifiable, Equatable {
    let id: UUID
    let rawText: String
    let titleHint: String?
    let includeTools: Bool
    let createdAt: Date
    let localeIdentifier: String

    init(
        id: UUID = UUID(),
        rawText: String,
        titleHint: String? = nil,
        includeTools: Bool = true,
        createdAt: Date = .now,
        localeIdentifier: String = Locale.current.identifier
    ) {
        self.id = id
        self.rawText = rawText
        self.titleHint = titleHint
        self.includeTools = includeTools
        self.createdAt = createdAt
        self.localeIdentifier = localeIdentifier
    }
}


@MainActor
final class GenerationQueue: ObservableObject {
    @Published private(set) var jobs: [GenerationJob] = []
    private let llmService: LLMService
    private let networkMonitor: NetworkMonitor
    private let metrics: MetricsReporter
    private var processingTask: Task<Void, Never>? = nil

    init(llmService: LLMService, networkMonitor: NetworkMonitor, metrics: MetricsReporter) {
        self.llmService = llmService
        self.networkMonitor = networkMonitor
        self.metrics = metrics
        processingTask = monitorNetwork()
    }

    deinit {
        processingTask?.cancel()
    }

    func enqueue(_ job: GenerationJob) {
        jobs.append(job)
    }

    func dequeue(_ job: GenerationJob) {
        jobs.removeAll { $0.id == job.id }
    }

    private func monitorNetwork() -> Task<Void, Never> {
        Task.detached { [weak self] in
            guard let self else { return }
            for await isOnline in self.networkMonitor.$isOnline.values {
                if isOnline {
                    await self.processNext()
                }
            }
        }
    }

    private func processNext() async {
        guard let job = jobs.first, networkMonitor.isOnline else { return }
        do {
            _ = try await llmService.generateSOP(
                from: LLMGenerationRequest(
                    rawText: job.rawText,
                    titleHint: job.titleHint,
                    includeTools: job.includeTools,
                    maxSteps: 15,
                    tone: "clear, concise, imperative"
                )
            )
            dequeue(job)
        } catch {
            metrics.track(event: .sopGenerationFailed(reason: "queue_error"))
        }
    }
}
