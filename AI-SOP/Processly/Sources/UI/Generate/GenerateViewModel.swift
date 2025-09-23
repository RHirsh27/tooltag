import Foundation
import SwiftData

@MainActor
final class GenerateViewModel: ObservableObject {
    enum State {
        case idle
        case generating
        case success(SOP)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    private var llmService: LLMService?
    private var repo: SOPRepository?
    private var metrics: MetricsReporter?
    private var quotaService: QuotaService?
    private var job: GenerationJob?

    func configure(
        job: GenerationJob,
        context: ModelContext,
        llmService: LLMService,
        metrics: MetricsReporter,
        quotaService: QuotaService
    ) {
        self.job = job
        self.repo = SOPRepository(context: context)
        self.llmService = llmService
        self.metrics = metrics
        self.quotaService = quotaService
    }

    func generate() async {
        guard let job, let llmService, let repo else { return }
        state = .generating

        let result = await llmService.request(
            rawText: job.rawText,
            titleHint: job.titleHint,
            includeTools: job.includeTools,
            maxSteps: 15,
            tone: "clear, concise, imperative"
        )

        switch result {
        case .success(let dto):
            do {
                let sanitized = try PostProcessor.sanitize(response: dto, source: job.rawText, localeIdentifier: job.localeIdentifier)
                let sop = try repo.create(from: sanitized.response, source: sanitized.cleanedSource)
                state = .success(sop)
            } catch {
                metrics?.track(event: .sopGenerationFailed(reason: "post_process_failed"))
                state = .failed(String(localized: "generate.failure"))
            }
        case .failure(let error):
            metrics?.track(event: .sopGenerationFailed(reason: error.analyticsReason))
            state = .failed(error.userMessage)
        }
    }
}
#if DEBUG
extension GenerateViewModel {
    func setPreviewState(_ state: State) {
        self.state = state
    }
}
#endif
