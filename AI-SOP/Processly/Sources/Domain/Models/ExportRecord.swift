import Foundation
import SwiftData

@Model
final class ExportRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var sopId: UUID
    var fileURL: URL
    var format: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        sopId: UUID,
        fileURL: URL,
        format: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.sopId = sopId
        self.fileURL = fileURL
        self.format = format
    }
}
