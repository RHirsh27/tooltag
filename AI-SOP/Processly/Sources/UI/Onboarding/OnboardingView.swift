import SwiftUI
import AVFoundation
import Speech

struct OnboardingView: View {
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @Environment(\.openURL) private var openURL
    @State private var currentStep = 0
    @State private var micPermission: AVAudioSession.RecordPermission = .undetermined
    @State private var speechPermission: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 32) {
            TabView(selection: $currentStep) {
                welcomeStep
                    .tag(0)
                permissionsStep
                    .tag(1)
                readyStep
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            if currentStep < 2 {
                continueButton
            } else {
                finishButton
            }
        }
        .padding()
        .onAppear {
            dependencies.metrics.track(event: .onboardingViewed)
            refreshPermissions()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to Processly")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Turn your voice notes into clear, actionable processes in seconds.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }

    private var permissionsStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Enable Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Processly needs microphone and speech recognition access to record and transcribe your voice notes.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if shouldShowSettingsButton {
                Button("Open iOS Settings") {
                    openSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var readyStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Start recording your first process or paste some text to get started.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }

    private var continueButton: some View {
        Button("Continue") {
            withAnimation {
                currentStep += 1
                refreshPermissions()
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var finishButton: some View {
        Button("Get Started") {
            MetricsService.onboardingComplete()
            dependencies.router.popToRoot()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var shouldShowSettingsButton: Bool {
        micPermission == .denied || speechPermission == .denied
    }

    private func refreshPermissions() {
        micPermission = AVAudioSession.sharedInstance().recordPermission
        speechPermission = SFSpeechRecognizer.authorizationStatus()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}