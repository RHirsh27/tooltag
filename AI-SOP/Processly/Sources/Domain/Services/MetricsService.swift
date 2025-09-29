import Foundation

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

enum MetricsEvent: String {
    case app_launch
    case onboarding_complete
    case first_finalize
    case gen_latency
    case template_created
    case template_duplicated
    case template_deleted
    case capture_started
    case sop_edited
}

struct MetricsService {
    static var enabled = true
    static var userOptIn = true

    static func configure(defaultEnabled: Bool) {
        userOptIn = defaultEnabled
    }

    static func log(_ event: MetricsEvent, properties: [String: Any]? = nil) {
        guard enabled, userOptIn else { return }
        
        #if canImport(FirebaseAnalytics)
        if userOptIn {
            let safeProperties = properties?.compactMapValues { value in
                if let string = value as? String { return string }
                if let number = value as? NSNumber { return number }
                return nil
            }
            Analytics.logEvent(event.rawValue, parameters: safeProperties)
        } else {
            let propsDescription: String
            if let properties, properties.isEmpty == false {
                let pairs = properties.map { key, value in "\(key): \(value)" }
                propsDescription = "{" + pairs.joined(separator: ", ") + "}"
            } else {
                propsDescription = "{}"
            }
            print("Metrics: \(event.rawValue) \(propsDescription)")
        }
        #else
        let propsDescription: String
        if let properties, properties.isEmpty == false {
            let pairs = properties.map { key, value in "\(key): \(value)" }
            propsDescription = "{" + pairs.joined(separator: ", ") + "}"
        } else {
            propsDescription = "{}"
        }
        print("Metrics: \(event.rawValue) \(propsDescription)")
        #endif
    }

    static func appLaunch() {
        log(.app_launch)
    }

    static func onboardingComplete() {
        log(.onboarding_complete)
    }

    static func firstFinalize(deltaSeconds: Double) {
        log(.first_finalize, properties: ["deltaSeconds": deltaSeconds])
    }

    static func genLatency(p50: Double, p90: Double) {
        log(.gen_latency, properties: ["p50": p50, "p90": p90])
    }
    
    static func templateCreated() {
        log(.template_created)
    }
    
    static func templateDuplicated() {
        log(.template_duplicated)
    }
    
    static func templateDeleted() {
        log(.template_deleted)
    }
    
    static func captureStarted(mode: String) {
        log(.capture_started, properties: ["mode": mode])
    }
    
    static func sopEdited() {
        log(.sop_edited)
    }
}

// MARK: - Console Metrics Service
protocol MetricsReporter {
    func track(event: MetricsEvent, properties: [String: Any]? = nil)
}

@MainActor
final class ConsoleMetricsService: ObservableObject, MetricsReporter {
    func track(event: MetricsEvent, properties: [String: Any]? = nil) {
        MetricsService.log(event, properties: properties)
    }
}

// MARK: - Metrics Event Extensions
extension MetricsEvent {
    var appLaunch: MetricsEvent { .app_launch }
    var templateCreated: MetricsEvent { .template_created }
    var templateDuplicated: MetricsEvent { .template_duplicated }
    var templateDeleted: MetricsEvent { .template_deleted }
    var captureStarted: MetricsEvent { .capture_started }
    var sopEdited: MetricsEvent { .sop_edited }
}

