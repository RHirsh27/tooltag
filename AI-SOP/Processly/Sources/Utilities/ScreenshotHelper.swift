import SwiftUI
import SwiftData

struct ScreenshotHelper {
    static func captureCaptureView() -> some View {
        let dependencies = ScreenshotEnvironment.makeDependencies(isPro: false)
        let container = ScreenshotEnvironment.makeContainer(with: nil, isPro: false)
        
        return ScreenshotScene(dependencies: dependencies, container: container) {
            CaptureView(previewTranscript: "Here's how to set up a new project: First, gather all the requirements from stakeholders. Then create a project plan with milestones. Finally, assign tasks to team members and set up regular check-ins.", isRecording: false)
        }
    }
    
    static func captureGenerateView() -> some View {
        let dependencies = ScreenshotEnvironment.makeDependencies(isPro: false)
        let result = ScreenshotEnvironment.makeContainerWithSampleSOP(isPro: false, status: .draft)
        
        return ScreenshotScene(dependencies: dependencies, container: result.container) {
            GenerateView(jobID: UUID(), previewState: .success(result.sop))
        }
    }
    
    static func captureEditView() -> some View {
        let dependencies = ScreenshotEnvironment.makeDependencies(isPro: true)
        let result = ScreenshotEnvironment.makeContainerWithSampleSOP(isPro: true, status: .draft)
        
        return ScreenshotScene(dependencies: dependencies, container: result.container) {
            SOPEditView(sopID: result.sop.persistentModelID)
        }
    }
    
    static func captureFinalizeView(isPro: Bool) -> some View {
        let dependencies = ScreenshotEnvironment.makeDependencies(isPro: isPro)
        let result = ScreenshotEnvironment.makeContainerWithSampleSOP(isPro: isPro, status: .draft)
        
        return ScreenshotScene(dependencies: dependencies, container: result.container) {
            FinalizeView(sopID: result.sop.persistentModelID)
        }
    }
    
    static func captureExportView(isPro: Bool) -> some View {
        let dependencies = ScreenshotEnvironment.makeDependencies(isPro: isPro)
        let result = ScreenshotEnvironment.makeContainerWithSampleSOP(isPro: isPro, status: .final)
        
        return ScreenshotScene(dependencies: dependencies, container: result.container) {
            ExportView(sopID: result.sop.persistentModelID)
        }
    }
}

private struct ScreenshotEnvironment {
    static func makeDependencies(isPro: Bool) -> AppDependencyContainer {
        let container = AppDependencyContainer()
        // Mock IAP service with pro status
        if isPro {
            container.iapService.entitlements = [.proUnlimited, .exportPremium]
        }
        return container
    }
    
    static func makeContainer(with context: ModelContext?, isPro: Bool) -> ModelContainer {
        let schema = Schema([SOP.self, UserPrefs.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            if let context = context {
                // Copy data from existing context if provided
            }
            return container
        } catch {
            fatalError("Failed to create screenshot container: \(error)")
        }
    }
    
    static func makeContainerWithSampleSOP(isPro: Bool, status: SOPStatus) -> (container: ModelContainer, sop: SOP) {
        let container = makeContainer(with: nil, isPro: isPro)
        let context = container.mainContext
        
        let sampleSteps = [
            SOPStep(number: 1, instruction: "Define project requirements"),
            SOPStep(number: 2, instruction: "Create project timeline"),
            SOPStep(number: 3, instruction: "Assign team members"),
            SOPStep(number: 4, instruction: "Set up communication channels"),
            SOPStep(number: 5, instruction: "Schedule regular check-ins")
        ]
        
        let sop = SOP(
            title: "Project Setup Process",
            summary: "A comprehensive guide for setting up new projects from start to finish",
            tags: ["Project Management", "Team Coordination"],
            tools: ["Project Management Software", "Calendar", "Communication Tools"],
            steps: sampleSteps,
            sourceRaw: "Here's how to set up a new project...",
            status: status,
            wordCount: 150
        )
        
        context.insert(sop)
        
        let prefs = UserPrefs(proActive: isPro)
        context.insert(prefs)
        
        try? context.save()
        
        return (container: container, sop: sop)
    }
}

private struct ScreenshotScene<Content: View>: View {
    let dependencies: AppDependencyContainer
    let container: ModelContainer
    let content: Content
    
    init(dependencies: AppDependencyContainer, container: ModelContainer, @ViewBuilder content: () -> Content) {
        self.dependencies = dependencies
        self.container = container
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            content
        }
        .environmentObject(dependencies)
        .environmentObject(dependencies.router)
        .environmentObject(dependencies.metrics)
        .environmentObject(dependencies.iapService)
        .environmentObject(dependencies.quotaService)
        .environmentObject(dependencies.networkMonitor)
        .environmentObject(dependencies.generationQueue)
        .modelContainer(container)
    }
}