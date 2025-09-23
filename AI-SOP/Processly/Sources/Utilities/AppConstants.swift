import Foundation

enum AppConstants {
    static let maxSteps = 15
    static let freeQuota = 5
    static let quotaRollingDays = 30
    static let tone = "clear, concise, imperative"

    enum LegalLinks {
        static let privacyPolicy = URL(string: "https://processly.app/privacy")!
        static let termsOfService = URL(string: "https://processly.app/terms")!
    }
    
    static let privacyURL = URL(string:"https://processly.app/privacy")!
    static let termsURL   = URL(string:"https://processly.app/terms")!
}
