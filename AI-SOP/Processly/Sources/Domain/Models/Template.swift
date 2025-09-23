import Foundation
import SwiftData

@Model
final class Template {
    @Attribute(.unique) var id: UUID
    var name: String
    var description: String?
    var sample: Bool
    @Relationship(deleteRule: .cascade) var sopDraft: SOP

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        sample: Bool = false,
        sopDraft: SOP
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.sample = sample
        self.sopDraft = sopDraft
    }
}
