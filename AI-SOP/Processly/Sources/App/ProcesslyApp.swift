import Foundation
import Combine
import SwiftUI
import SwiftData

#if canImport(Firebase)
import Firebase
#endif

enum Observability {
    static var enableCrashReporting = false
    static var crashEnabled = false

    static func bootstrap() {
        #if canImport(Firebase)
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            enableCrashReporting = false
            crashEnabled = false
            recordBreadcrumb("GoogleService-Info.plist missing; skipping Firebase configuration.")
            return
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        enableCrashReporting = FirebaseApp.app() != nil
        crashEnabled = FirebaseApp.app() != nil
        #else
        enableCrashReporting = false
        crashEnabled = false
        recordBreadcrumb("Firebase SDK unavailable; crash reporting disabled.")
        #endif
    }

    @discardableResult
    static func recordBreadcrumb(_ message: String, function: String = #function, line: Int = #line) -> String {
        #if DEBUG
        let entry = "Breadcrumb [\(function):\(line)]: \(message)"
        print(entry)
        return entry
        #else
        return message
        #endif
    }
}

@main
struct ProcesslyApp: App {
    init() {
        Observability.bootstrap()
    }
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var container: ModelContainer = {
        do {
            let schema = Schema([
                SOP.self,
                UserPrefs.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    @StateObject private var dependencies = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
                .environmentObject(dependencies.router)
                .environmentObject(dependencies.metrics)
                .environmentObject(dependencies.iapService)
                .environmentObject(dependencies.quotaService)
                .environmentObject(dependencies.networkMonitor)
                .environmentObject(dependencies.generationQueue)
                .modelContainer(container)
                .task {
                    await dependencies.bootstrap()
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        AppTheme.configureAppearance()
        // Observability bootstrap handles crash reporting wiring when Firebase is available.
        return true
    }
}

private struct RootView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var metrics: ConsoleMetricsService
    @EnvironmentObject private var iapService: IAPService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let toastBinding = Binding<String?>(
            get: { dependencies.toastMessage },
            set: { dependencies.toastMessage = $0 }
        )

        return NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    router.destination(for: route)
                }
        }
        .toast(message: toastBinding)
        .transaction { transaction in
            if reduceMotion {
                transaction.disablesAnimations = true
            }
        }
        .onReceive(iapService.$statusMessage.compactMap { $0 }) { message in
            dependencies.presentToast(message)
            iapService.statusMessage = nil
        }
        .task {
            SeedData.ensureDefaults(context: context)
            metrics.track(event: .appLaunch)
            await iapService.refreshSubscriptions()
            handleUITestNavigation()
        }
        .onReceive(iapService.$entitlements) { entitlements in
            let isPro = entitlements.contains(.proUnlimited)
            try? dependencies.quotaService.setProStatus(isActive: isPro, using: context)
        }
    }
}

@MainActor
final class AppDependencyContainer: ObservableObject {
    @Published var toastMessage: String? = nil
    let router = AppRouter()
    let metrics = ConsoleMetricsService()
    let speechService: any SpeechService
    let llmService: DefaultLLMService
    let quotaService: QuotaService
    let exportService: ExportService
    let iapService: IAPService
    let networkMonitor = NetworkMonitor()
    let generationQueue: GenerationQueue

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let environment = ProcessInfo.processInfo.environment
        let isUITest = arguments.contains("--ui-testing") || environment["UITEST_MODE"] == "1"
        if isUITest {
            speechService = TranscriptMockService()
        } else {
            speechService = DefaultSpeechService(metrics: metrics)
        }
        llmService = DefaultLLMService(metrics: metrics)
        quotaService = QuotaService(metrics: metrics)
        exportService = ExportService(metrics: metrics)
        iapService = IAPService(metrics: metrics)
        generationQueue = GenerationQueue(llmService: llmService, networkMonitor: networkMonitor, metrics: metrics)
    }

    func bootstrap() async {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: QuotaService.installTimestampKey) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: QuotaService.installTimestampKey)
        }
        await networkMonitor.startMonitoring()
        // TODO: Load persisted entitlements, refresh templates/seed data if needed.
    }

    func presentToast(_ message: String) {
        toastMessage = message
    }
}

private extension RootView {
    func handleUITestNavigation() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--ui-testing") else { return }

        if arguments.contains("--ui-show-paywall") {
            dependencies.router.push(.paywall(trigger: .quota))
        }

        if arguments.contains("--ui-show-export") {
            let sop = ensureSampleSOP()
            dependencies.router.push(.export(sopID: sop.persistentModelID))
        }
    }

    func ensureSampleSOP() -> SOP {
        if let existing = try? context.fetch(FetchDescriptor<SOP>(predicate: #Predicate { $0.title == "UI Test Sample" }, fetchLimit: 1)).first {
            return existing
        }

        let steps = [
            SOPStep(number: 1, instruction: "Gather inputs"),
            SOPStep(number: 2, instruction: "Review with team"),
            SOPStep(number: 3, instruction: "Publish and share")
        ]

        let sop = SOP(
            title: "UI Test Sample",
            summary: "Sample SOP used in UI automation.",
            tools: ["Checklist"],
            steps: steps,
            sourceRaw: "UI Test Sample",
            status: .draft
        )
        context.insert(sop)
        try? context.save()
        return sop
    }
}





