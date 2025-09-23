import SwiftUI
import UIKit
import SwiftData

struct GenerateView: View {
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = GenerateViewModel()
    let jobID: UUID

    init(jobID: UUID) {
        self.jobID = jobID
    }

#if DEBUG
    init(jobID: UUID, previewState: GenerateViewModel.State) {
        self.jobID = jobID
        _viewModel = StateObject(wrappedValue: {
            let model = GenerateViewModel()
            model.setPreviewState(previewState)
            return model
        }())
    }
#endif

    var body: some View {
        VStack(spacing: 24) {
            switch viewModel.state {
            case .idle, .generating:
                ProgressView(L10n.Generate.generating)
                    .accessibilityHidden(false)
                    .a11y(
                        id: "gen.progress",
                        label: String(localized: "a11y.generate.progress.label"),
                        hint: String(localized: "a11y.generate.progress.hint")
                    )
            case .success(let sop):
                Text("\(String(localized: "generate.success_prefix")) \(sop.title)")
                    .font(.headline)
                Button(L10n.Generate.continueEdit) {
                    dependencies.router.push(.edit(sopID: sop.persistentModelID))
                }
                .accessibilityHint(L10n.Generate.continueEdit)
            case .failed(let message):
                Text(message)
                    .foregroundColor(.red)
                Button(L10n.Generate.retry) {
                    Task { await viewModel.generate() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .a11y(
                    id: "gen.retry",
                    label: String(localized: "a11y.generate.retry.label"),
                    traits: .button
                )
            case .noAPIKey:
                noAPIKeyCard
            }
        }
        .padding()
        .navigationTitle(L10n.Generate.title)
        .onChange(of: viewModel.state) { state in
            if case .failed(let message) = state {
                dependencies.presentToast(message)
            }
        }
        .task {
            await setupIfNeeded()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "generate.cancel")) {
                    dependencies.router.pop()
                }
                .a11y(
                    id: "gen.cancel",
                    label: String(localized: "a11y.generate.cancel.label"),
                    traits: .button
                )
            }
        }
    }

    @ViewBuilder
    private var noAPIKeyCard: some View {
        VStack(spacing: 16) {
            Text("Add an AI key")
                .font(.headline)
            Text("Processly needs an AI provider key to generate steps.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Open Settings") {
                    dependencies.router.push(.settings)
                }
                .buttonStyle(.borderedProminent)
                
                if FeatureFlags.showExperimentalTemplates {
                    Button("Try Template") {
                        createTemplateSOP()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func createTemplateSOP() {
        let templateSteps = [
            SOPStep(number: 1, instruction: "Define the objective"),
            SOPStep(number: 2, instruction: "Gather required resources"),
            SOPStep(number: 3, instruction: "Execute the process"),
            SOPStep(number: 4, instruction: "Review and validate results")
        ]
        
        let templateSOP = SOP(
            title: "Process Template",
            summary: "A basic process template to get you started",
            tools: ["Checklist"],
            steps: templateSteps,
            sourceRaw: "Template",
            status: .draft
        )
        
        context.insert(templateSOP)
        try? context.save()
        dependencies.router.push(.edit(sopID: templateSOP.persistentModelID))
    }

    private func setupIfNeeded() async {
        guard let job = dependencies.generationQueue.jobs.first(where: { $0.id == jobID }) else {
            return
        }
        viewModel.configure(
            job: job,
            context: context,
            llmService: dependencies.llmService,
            metrics: dependencies.metrics,
            quotaService: dependencies.quotaService
        )
        await viewModel.generate()
        dependencies.generationQueue.dequeue(job)
    }
}
#if DEBUG
extension GenerateView {
    @MainActor static func screenshotMock() -> some View {
        let dependencies = ScreenshotEnvironment.makeDependencies(isPro: true)
        let result = ScreenshotEnvironment.makeContainerWithSampleSOP(isPro: true, status: .draft)
        let sop = result.sop
        return ScreenshotScene(dependencies: dependencies, container: result.container) {
            GenerateView(jobID: UUID(), previewState: .success(sop))
        }
    }
}
#endif
