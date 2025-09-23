import Foundation
import SwiftData

@Model
final class Recording {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var audioURL: URL
    var transcript: String?
    var linkedSOPId: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        audioURL: URL,
        transcript: String? = nil,
        linkedSOPId: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.audioURL = audioURL
        self.transcript = transcript
        self.linkedSOPId = linkedSOPId
    }
}
