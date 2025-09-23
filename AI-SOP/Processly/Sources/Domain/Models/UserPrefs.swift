import Foundation
import SwiftData

@Model
final class UserPrefs {
    var proActive: Bool
    var monthlyQuotaUsed: Int
    var quotaCycleStart: Date
    var defaultExport: ExportFormat
    var asrEngine: ASREngine
    var analyticsEnabled: Bool

    init(
        proActive: Bool = false,
        monthlyQuotaUsed: Int = 0,
        quotaCycleStart: Date = .now,
        defaultExport: ExportFormat = .pdf,
        asrEngine: ASREngine = .ios,
        analyticsEnabled: Bool = true
    ) {
        self.proActive = proActive
        self.monthlyQuotaUsed = monthlyQuotaUsed
        self.quotaCycleStart = quotaCycleStart
        self.defaultExport = defaultExport
        self.asrEngine = asrEngine
        self.analyticsEnabled = analyticsEnabled
    }
}

enum ASREngine: String, Codable, CaseIterable {
    case ios
    case whisper
}
