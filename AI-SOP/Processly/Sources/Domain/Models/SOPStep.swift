import Foundation
import SwiftData

@Model
final class SOPStep {
    @Attribute(.unique) var id: UUID
    var order: Int
    var title: String
    var details: String?
    @Relationship(deleteRule: .cascade) var checklistItems: [ChecklistItem] = []
    var attachmentLocalURL: URL?
    var voiceNoteLocalURL: URL?
    var durationMin: Int?

    init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        details: String? = nil,
        checklistItems: [ChecklistItem] = [],
        attachmentLocalURL: URL? = nil,
        voiceNoteLocalURL: URL? = nil,
        durationMin: Int? = nil
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.details = details
        self.checklistItems = checklistItems
        self.attachmentLocalURL = attachmentLocalURL
        self.voiceNoteLocalURL = voiceNoteLocalURL
        self.durationMin = durationMin
    }
}
