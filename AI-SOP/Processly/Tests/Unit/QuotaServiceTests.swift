import XCTest
import SwiftData
@testable import Processly

final class QuotaServiceTests: XCTestCase {
    @MainActor
    func testQuotaBlocksAfterFiveFinalizations() throws {
        let container = try ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let prefs = UserPrefs(proActive: false, monthlyQuotaUsed: 0, quotaCycleStart: .now)
        context.insert(prefs)
        try context.save()

        let service = QuotaService(metrics: ConsoleMetricsService())
        for _ in 0..<5 {
            XCTAssertTrue(try service.canFinalize(using: context))
            try service.incrementFinalize(using: context)
        }

        XCTAssertFalse(try service.canFinalize(using: context))
    }

    @MainActor
    func testProBypassesQuota() throws {
        let container = try ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let prefs = UserPrefs(proActive: true, monthlyQuotaUsed: 10, quotaCycleStart: .now)
        context.insert(prefs)
        try context.save()

        let service = QuotaService(metrics: ConsoleMetricsService())
        XCTAssertTrue(try service.canFinalize(using: context))
    }

    @MainActor
    func testRollingWindowResetsAfterThirtyDays() throws {
        let container = try ModelContainer(for: UserPrefs.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        var dateComponents = DateComponents()
        dateComponents.day = -31
        let past = Calendar.current.date(byAdding: dateComponents, to: .now) ?? .now
        let prefs = UserPrefs(proActive: false, monthlyQuotaUsed: 5, quotaCycleStart: past)
        context.insert(prefs)
        try context.save()

        let service = QuotaService(metrics: ConsoleMetricsService())
        XCTAssertTrue(try service.canFinalize(using: context, now: .now))
    }
}
