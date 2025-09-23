import Foundation

struct FeatureFlags {
    static var isProd: Bool {
        ProcessInfo.processInfo.environment["PROCESSLY_ENV"] == "PROD"
    }
    
    static var showExperimentalTemplates: Bool {
        !isProd
    }
    
    static var enableDebugToasts: Bool {
        !isProd
    }
}
