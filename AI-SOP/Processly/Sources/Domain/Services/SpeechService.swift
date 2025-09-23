import Foundation
import AVFoundation
import Speech
import Combine
import SwiftUI

struct SpeechSegment: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let duration: TimeInterval
}

struct SpeechTranscription: Equatable {
    let fullText: String
    let segments: [SpeechSegment]
    let totalDuration: TimeInterval

    static let empty = SpeechTranscription(fullText: "", segments: [], totalDuration: 0)
}

@MainActor
protocol SpeechService: ObservableObject {
    var transcriptPublisher: AnyPublisher<String, Never> { get }
    var transcriptionPublisher: AnyPublisher<SpeechTranscription, Never> { get }
    var interruptionPublisher: AnyPublisher<SpeechError, Never> { get }
    var isRecording: Bool { get }
    var currentTranscription: SpeechTranscription { get }
    var localeIdentifier: String { get }

    func requestPermissions() async throws
    func startRecording() async throws
    func stopRecording() async
    func cancelRecording()
}

@MainActor
final class DefaultSpeechService: NSObject, SpeechService {
    private let audioSession = AVAudioSession.sharedInstance()
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let transcriptionSubject = CurrentValueSubject<SpeechTranscription, Never>(.empty)
    private let interruptionSubject = PassthroughSubject<SpeechError, Never>()
    private(set) var isRecording: Bool = false
    let localeIdentifier: String

    private var currentSegments: [SpeechSegment] = []
    private var currentSegmentText: String = ""
    private var currentSegmentStartOffset: TimeInterval = 0
    private let chunkThreshold: TimeInterval = 240 // ~4 minutes
    private let metrics: MetricsReporter
    private var scenePhaseObserver: AnyCancellable?

    init(metrics: MetricsReporter, locale: Locale = Locale(identifier: Locale.preferredLanguages.first ?? "en_US")) {
        self.metrics = metrics
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        self.localeIdentifier = locale.identifier
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )
        setupScenePhaseObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        scenePhaseObserver?.cancel()
    }

    var transcriptPublisher: AnyPublisher<String, Never> {
        transcriptionSubject
            .map { $0.fullText }
            .eraseToAnyPublisher()
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

    func requestPermissions() async throws {
        let audioGranted = await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard audioGranted else {
            throw SpeechError.microphoneDenied
        }

        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            throw SpeechError.speechDenied
        }
    }

    func startRecording() async throws {
        guard !isRecording else { return }
        try await requestPermissions()
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechError.noRecognizerLocale
        }

        metrics.track(event: .captureStarted(mode: .voice))
        resetSessionState()
        isRecording = true
        transcriptionSubject.send(.empty)

        try configureSession()
        try beginRecognition(with: recognizer)
    }

    func stopRecording() async {
        guard isRecording else { return }
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        finalizeCurrentSegment(finalTimestamp: transcriptionSubject.value.totalDuration)
        isRecording = false
    }

    func cancelRecording() {
        audioEngine.stop()
        audioEngine.reset()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    private func resetSessionState() {
        currentSegments = []
        currentSegmentText = ""
        currentSegmentStartOffset = 0
    }

    private func configureSession() throws {
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func beginRecognition(with recognizer: SFSpeechRecognizer) throws {
        let node = audioEngine.inputNode
        let format = node.outputFormat(forBus: 0)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    self.process(result: result)
                }
            }
            if let error {
                Task { @MainActor in
                    self.metrics.track(event: .error(type: .speechRecognition, context: "recognition_error"))
                    self.pauseForInterruption()
                    self.handleRecognitionFailure(error)
                }
            }
        }

        node.removeTap(onBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func process(result: SFSpeechRecognitionResult) {
        let newText = result.bestTranscription.formattedString
        let previousText = transcriptionSubject.value.fullText
        let appended = diff(from: previousText, to: newText)

        if appended.isEmpty == false {
            currentSegmentText.append(appended)
        }

        let totalDuration = result.bestTranscription.segments.last.map { segment in
            segment.timestamp + segment.duration
        } ?? transcriptionSubject.value.totalDuration

        if totalDuration - currentSegmentStartOffset >= chunkThreshold {
            finalizeCurrentSegment(finalTimestamp: totalDuration)
        }

        if result.isFinal {
            finalizeCurrentSegment(finalTimestamp: totalDuration)
        }

        let transcription = SpeechTranscription(
            fullText: newText,
            segments: currentSegments,
            totalDuration: totalDuration
        )
        transcriptionSubject.send(transcription)
    }

    private func finalizeCurrentSegment(finalTimestamp: TimeInterval) {
        let trimmed = currentSegmentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            currentSegmentStartOffset = finalTimestamp
            currentSegmentText = ""
            return
        }

        let duration = max(0, finalTimestamp - currentSegmentStartOffset)
        currentSegments.append(SpeechSegment(text: trimmed, duration: duration))
        currentSegmentText = ""
        currentSegmentStartOffset = finalTimestamp

        let transcription = SpeechTranscription(
            fullText: transcriptionSubject.value.fullText,
            segments: currentSegments,
            totalDuration: finalTimestamp
        )
        transcriptionSubject.send(transcription)
    }

    private func diff(from old: String, to new: String) -> String {
        guard new.hasPrefix(old) else { return new }
        let startIndex = new.index(new.startIndex, offsetBy: old.count)
        return String(new[startIndex...])
    }

    private func handleRecognitionFailure(_ error: Swift.Error) {
        interruptionSubject.send(.audioInterrupted)
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let rawValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawValue) else {
            return
        }

        switch type {
        case .began:
            metrics.track(event: .error(type: .speechRecognition, context: "interrupted"))
            pauseForInterruption()
        case .ended:
            break
        default:
            break
        }
    }

    private func pauseForInterruption() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        interruptionSubject.send(.audioInterrupted)
    }
    
    private func setupScenePhaseObserver() {
        scenePhaseObserver = NotificationCenter.default
            .publisher(for: UIScene.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleScenePhaseChange(.background)
                }
            }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            if isRecording {
                Task {
                    await stopRecording()
                }
            }
        case .active, .inactive:
            break
        @unknown default:
            break
        }
    }
}

enum SpeechError: LocalizedError {
    case microphoneDenied
    case speechDenied
    case noRecognizerLocale
    case audioInterrupted

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return NSLocalizedString("Microphone permission is required to record.", comment: "Mic denied")
        case .speechDenied:
            return NSLocalizedString("Speech recognition permission is required.", comment: "Speech denied")
        case .noRecognizerLocale:
            return NSLocalizedString("Speech recognition is not available in your locale.", comment: "No recognizer")
        case .audioInterrupted:
            return NSLocalizedString("Audio was interrupted. Please try recording again.", comment: "Audio interrupted")
        }
    }
}
