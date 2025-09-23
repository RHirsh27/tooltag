import Foundation

enum AppError: LocalizedError {
    case generationFailed
    case quotaExceeded
    case exportUnavailable
    case networkOffline

    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "We couldn\'t generate your SOP. Please try again."
        case .quotaExceeded:
            return "You\'ve used your free quota. Upgrade to continue."
        case .exportUnavailable:
            return "That export format requires \(Brand.proName)."
        case .networkOffline:
            return "You\'re offline. We\'ll retry when you\'re back online."
        }
    }
}
