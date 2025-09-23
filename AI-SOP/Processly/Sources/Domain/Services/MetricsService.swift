import Foundation

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

enum MetricsEvent: String {
    case app_launch
    case onboarding_complete
    case first_finalize
    case gen_latency
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
}

