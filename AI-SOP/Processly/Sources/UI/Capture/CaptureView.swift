import SwiftUI
import UIKit
import Combine

struct CaptureView: View {
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @State private var transcript: String = ""
    @State private var isRecording = false
    @State private var transcriptCancellable: AnyCancellable?
    @State private var interruptionCancellable: AnyCancellable?
    @State private var errorMessage: String?

#if DEBUG
    init(previewTranscript: String, isRecording: Bool, errorMessage: String? = nil) {
        _transcript = State(initialValue: previewTranscript)
        _isRecording = State(initialValue: isRecording)
        _errorMessage = State(initialValue: errorMessage)
    }
#endif

    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                Text(transcript.isEmpty ? String(localized: "capture.prompt") : transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            recordButton

            Button(L10n.Capture.generateCTA) {
                enqueueGeneration()
            }
            .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .a11y(
                id: "capture.generate",
                label: String(localized: "capture.generate_cta"),
                hint: String(localized: "a11y.capture.generate.hint"),
                traits: .button
            )
        }
        .padding()
        .navigationTitle(L10n.Capture.title)
        .onAppear {
            subscribeToTranscript()
            subscribeToInterruptions()
        }
        .onDisappear {
            transcriptCancellable?.cancel()
            interruptionCancellable?.cancel()
        }
    }

    private var recordButton: some View {
        Button {
            Task { await toggleRecording() }
        } label: {
            Label(isRecording ? L10n.Capture.stopLabel : L10n.Capture.recordingLabel, systemImage: isRecording ? "stop.fill" : "mic.fill")
                .font(.title2)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(isRecording ? Color.red : AppTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(16)
                .contentShape(Rectangle())
        }
        .a11y(
            id: "capture.record",
            label: String(localized: "a11y.capture.record.label"),
            hint: String(localized: "a11y.capture.record.hint"),
            traits: .button
        )
    }

    private func subscribeToTranscript() {
        transcriptCancellable = dependencies.speechService.transcriptPublisher
            .receive(on: RunLoop.main)
            .sink { value in
                transcript = value
            }
    }

    private func subscribeToInterruptions() {
        interruptionCancellable = dependencies.speechService.interruptionPublisher
            .receive(on: RunLoop.main)
            .sink { error in
                isRecording = false
                errorMessage = error.localizedDescription
            }
    }

    private func toggleRecording() async {
        do {
            if !isRecording {
                try await dependencies.speechService.requestPermissions()
                try await dependencies.speechService.startRecording()
                isRecording = true
                errorMessage = nil
            } else {
                await dependencies.speechService.stopRecording()
                isRecording = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func enqueueGeneration() {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let job = GenerationJob(rawText: trimmed, localeIdentifier: dependencies.speechService.localeIdentifier)
        dependencies.generationQueue.enqueue(job)
        dependencies.router.push(.generate(jobID: job.id))
    }
}

#if DEBUG
extension CaptureView {
    @MainActor static func screenshotMock() -> some View {
        let dependencies = ScreenshotEnvironment.makeDependencies(isPro: true)
        let container = ScreenshotEnvironment.makeContainer(with: nil, isPro: true)
        return ScreenshotScene(dependencies: dependencies, container: container) {
            CaptureView(previewTranscript: ScreenshotSampleData.captureTranscript, isRecording: true)
        }
    }
}
#endif






