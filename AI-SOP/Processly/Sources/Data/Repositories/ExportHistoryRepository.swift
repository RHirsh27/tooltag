import Foundation

struct ExportRecord: Codable, Hashable {
    let sopID: UUID
    let format: ExportFormat
    let date: Date
}

final class ExportHistoryRepository {
    private let defaults = UserDefaults.standard
    private let key = "com.processly.exportHistory"

    func logExport(record: ExportRecord) {
        var records = loadHistory()
        records.append(record)
        save(records: records)
    }

    func recentExports(limit: Int) -> [ExportRecord] {
        let records = loadHistory().sorted { $0.date > $1.date }
        return Array(records.prefix(limit))
    }

    private func loadHistory() -> [ExportRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ExportRecord].self, from: data)) ?? []
    }

    private func save(records: [ExportRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }
}
