import Foundation
import SwiftData

protocol SOPRepositoryProtocol {
    func fetchRecent(limit: Int) throws -> [SOP]
    func fetch(by id: PersistentIdentifier) throws -> SOP?
    func create(from response: SOPDTO, source: String) throws -> SOP
    func delete(_ sop: SOP) throws
}

@MainActor
final class SOPRepository: SOPRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchRecent(limit: Int) throws -> [SOP] {
        var descriptor = FetchDescriptor<SOP>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    func fetch(by id: PersistentIdentifier) throws -> SOP? {
        try context.model(for: id) as? SOP
    }

    func create(from response: SOPDTO, source: String) throws -> SOP {
        let steps = response.steps.map { step in
            SOPStep(number: step.number, instruction: step.instruction, notes: step.notes, estMinutes: step.estMinutes)
        }
        let cleanedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = cleanedSource.split(whereSeparator: \.isWhitespace).count

        let sop = SOP(
            title: response.title,
            summary: response.summary,
            tags: response.tags,
            tools: response.toolsNeeded,
            steps: steps,
            sourceRaw: cleanedSource,
            status: .draft,
            wordCount: wordCount
        )
        context.insert(sop)
        try context.save()
        return sop
    }

    func delete(_ sop: SOP) throws {
        context.delete(sop)
        try context.save()
    }
}
