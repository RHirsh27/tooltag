import Foundation
import SwiftData

@Model
final class ChecklistItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var isRequired: Bool

    init(
        id: UUID = UUID(),
        text: String,
        isRequired: Bool = false
    ) {
        self.id = id
        self.text = text
        self.isRequired = isRequired
    }
}
