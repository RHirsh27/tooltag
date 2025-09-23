import Foundation
import Combine

@MainActor
final class TranscriptMockService: SpeechService {
    private let transcriptSubject: CurrentValueSubject<String, Never>
    private let transcriptionSubject: CurrentValueSubject<SpeechTranscription, Never>
    private let interruptionSubject = PassthroughSubject<SpeechError, Never>()
    private let mockSegments: [SpeechSegment]
    private(set) var isRecording: Bool = false
    let localeIdentifier: String

    init(mockTranscript: String = "This is a deterministic transcript for UI testing.", localeIdentifier: String = "en_US") {
        self.localeIdentifier = localeIdentifier
        let segment = SpeechSegment(text: mockTranscript, duration: 30)
        self.mockSegments = [segment]
        self.transcriptSubject = CurrentValueSubject(mockTranscript)
        self.transcriptionSubject = CurrentValueSubject(SpeechTranscription(fullText: mockTranscript, segments: mockSegments, totalDuration: 30))
    }

    var transcriptPublisher: AnyPublisher<String, Never> {
        transcriptSubject.eraseToAnyPublisher()
    }

    var transcriptionPublisher: AnyPublisher<SpeechTranscription, Never> {
        transcriptionSubject.eraseToAnyPublisher()
    }

    var interruptionPublisher: AnyPublisher<SpeechError, Never> {
        interruptionSubject.eraseToAnyPublisher()
    }

    var currentTranscription: SpeechTranscription {
        transcriptionSubject.value
    }

    func requestPermissions() async throws {}

    func startRecording() async throws {
        isRecording = true
        transcriptSubject.send(mockSegments.first?.text ?? "")
        transcriptionSubject.send(SpeechTranscription(fullText: transcriptSubject.value, segments: mockSegments, totalDuration: 30))
    }

    func stopRecording() async {
        isRecording = false
    }

    func cancelRecording() {
        isRecording = false
    }
}
