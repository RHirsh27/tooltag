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
                SOPStep.self,
                ChecklistItem.self,
                Template.self,
                Recording.self,
                ExportRecord.self,
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
            MainTabView()
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






