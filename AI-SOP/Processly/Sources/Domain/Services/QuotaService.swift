import Foundation
import SwiftData

@MainActor
final class QuotaService: ObservableObject {
    static let installTimestampKey = "com.processly.installTimestamp"
    static let firstFinalizeTimestampKey = "com.processly.firstFinalizeTimestamp"

    private let defaults = UserDefaults.standard
    private let calendar: Calendar
    private let metrics: MetricsReporter
    private let freeQuota = 5
    private let rollingDays = 30

    init(metrics: MetricsReporter, calendar: Calendar = .current) {
        self.metrics = metrics
        self.calendar = calendar
    }

    func canFinalize(using context: ModelContext, now: Date = .now) throws -> Bool {
        let prefs = try fetchPrefs(using: context)
        resetIfCycleElapsed(now: now, prefs: prefs)
        return canFinalize(now: now, prefs: prefs)
    }

    func incrementFinalize(using context: ModelContext, now: Date = .now) throws {
        let prefs = try fetchPrefs(using: context)
        resetIfCycleElapsed(now: now, prefs: prefs)
        markFinalized(now: now, prefs: prefs)
        try context.save()
    }

    func remainingQuota(using context: ModelContext, now: Date = .now) throws -> Int? {
        let prefs = try fetchPrefs(using: context)
        resetIfCycleElapsed(now: now, prefs: prefs)
        guard prefs.proActive == false else { return nil }
        return max(0, freeQuota - prefs.monthlyQuotaUsed)
    }

    func activatePro(using context: ModelContext) throws {
        try setProStatus(isActive: true, using: context)
    }

    func setProStatus(isActive: Bool, using context: ModelContext) throws {
        let prefs = try fetchPrefs(using: context)
        if prefs.proActive != isActive {
            prefs.proActive = isActive
            try context.save()
        }
    }

    // MARK: - Rolling window helpers

    func canFinalize(now: Date, prefs: UserPrefs) -> Bool {
        if prefs.proActive { return true }
        return prefs.monthlyQuotaUsed < freeQuota
    }

    func markFinalized(now: Date, prefs: UserPrefs) {
        if prefs.proActive == false {
            prefs.monthlyQuotaUsed += 1
        }
        metrics.track(event: .sopFinalized)
        maybeTrackFirstSOP(now: now)
    }

    private func maybeTrackFirstSOP(now: Date) {
        if defaults.object(forKey: Self.firstFinalizeTimestampKey) != nil { return }
        defaults.set(now.timeIntervalSince1970, forKey: Self.firstFinalizeTimestampKey)
        let installTimestamp = defaults.double(forKey: Self.installTimestampKey)
        guard installTimestamp > 0 else { return }
        let delta = max(0, now.timeIntervalSince1970 - installTimestamp)
        metrics.track(event: .firstSOP(seconds: delta))
    }

    func resetIfCycleElapsed(now: Date, prefs: UserPrefs) {
        guard let next = calendar.date(byAdding: .day, value: rollingDays, to: prefs.quotaCycleStart) else { return }
        if now >= next {
            prefs.quotaCycleStart = now
            prefs.monthlyQuotaUsed = 0
        }
    }

    // MARK: - Persistence

    private func fetchPrefs(using context: ModelContext) throws -> UserPrefs {
        let descriptor = FetchDescriptor<UserPrefs>(fetchLimit: 1)
        if let prefs = try context.fetch(descriptor).first {
            return prefs
        }
        let prefs = UserPrefs()
        context.insert(prefs)
        try context.save()
        return prefs
    }
}



