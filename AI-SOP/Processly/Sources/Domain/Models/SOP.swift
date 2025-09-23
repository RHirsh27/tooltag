import Foundation
import SwiftData

@Model
final class SOP {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var summary: String?
    @Attribute(.transformable) var tags: [String]
    var estimatedDurationMin: Int?
    var coverImageData: Data?
    var isFavorite: Bool
    @Relationship(deleteRule: .cascade) var steps: [SOPStep] = []
    var sourceRaw: String
    var status: SOPStatus
    var wordCount: Int
    var lastExportFormat: ExportFormat?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        title: String,
        summary: String? = nil,
        tags: [String] = [],
        estimatedDurationMin: Int? = nil,
        coverImageData: Data? = nil,
        isFavorite: Bool = false,
        steps: [SOPStep] = [],
        sourceRaw: String,
        status: SOPStatus = .draft,
        wordCount: Int = 0,
        lastExportFormat: ExportFormat? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.summary = summary
        self.tags = tags
        self.estimatedDurationMin = estimatedDurationMin
        self.coverImageData = coverImageData
        self.isFavorite = isFavorite
        self.steps = steps
        self.sourceRaw = sourceRaw
        self.status = status
        self.wordCount = wordCount
        self.lastExportFormat = lastExportFormat
    }
}
