import SwiftUI
import SwiftData
import UIKit
import AVFoundation
import Speech

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @EnvironmentObject private var iapService: IAPService
    @Query(sort: \UserPrefs.quotaCycleStart, order: .reverse, fetchLimit: 1) private var prefs: [UserPrefs]
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var apiKey: String = ""
    @State private var keyDraft: String = ""
    @State private var isAPIKeyVisible = false
    @State private var toastMessage: String?
    @State private var micPermission: AVAudioSession.RecordPermission = .undetermined
    @State private var speechPermission: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @State private var showingHelpSheet = false

    var body: some View {
        Form {
            permissionsSection
            accountSection
            aiProviderSection
            defaultsSection
            quotaSection
            supportSection
            legalSection
        }
        .navigationTitle(Text("Settings", comment: "Settings title"))
        .onAppear {
            ensurePrefs()
            MetricsService.configure(defaultEnabled: prefs.first?.analyticsEnabled ?? true)
            keyDraft = KeychainStore.string(for: KeychainStore.Key.llmAPIKey) ?? ""
            apiKey = KeychainStore.string(for: KeychainStore.Key.llmAPIKey) ?? ""
            refreshPermissions()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                refreshPermissions()
            }
        }
        .toast(message: $toastMessage)
        .sheet(isPresented: $showingHelpSheet) {
            HelpSheet()
        }
    }

    private var permissionsSection: some View {
        Section(Text("Capture Permissions", comment: "Permissions section title")) {
            LabeledContent {
                Text(microphoneStatusText)
                    .foregroundStyle(microphoneStatusColor)
                    .fixedSize(horizontal: false, vertical: true)
            } label: {
                Label(NSLocalizedString("Microphone", comment: "Microphone permission label"), systemImage: "mic.fill")
            }

            LabeledContent {
                Text(speechStatusText)
                    .foregroundStyle(speechStatusColor)
                    .fixedSize(horizontal: false, vertical: true)
            } label: {
                Label(NSLocalizedString("Speech Recognition", comment: "Speech permission label"), systemImage: "waveform")
            }

            if shouldShowSettingsLink {
                Button(action: openSystemSettings) {
                    Label(NSLocalizedString("Open iOS Settings", comment: "Open settings button"), systemImage: "gearshape.fill")
                }
                .buttonStyle(.borderedProminent)
                .a11y(
                    id: "settings.openSystem",
                    label: String(localized: "settings.open_ios"),
                    traits: .button
                )
                .accessibilityHint(Text("Opens Settings so you can enable microphone and speech access for Processly.", comment: "Settings deep link hint"))
            } else {
                Text(NSLocalizedString("You're ready to capture voice notes with Processly.", comment: "Permissions satisfied copy"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var accountSection: some View {
        Section(Text("Account", comment: "Account settings section")) {
            Toggle(isOn: analyticsEnabledBinding()) {
                Text("Analytics", comment: "Analytics toggle label")
            }
            .a11y(
                id: "settings.analytics",
                label: String(localized: "settings.analytics_optin"),
                hint: String(localized: "settings.a11y.analytics.hint")
            )
            Text(iapService.hasAccess(.proUnlimited) ? NSLocalizedString("Pro Active", comment: "Pro tier label") : NSLocalizedString("Free Tier", comment: "Free tier label"))
                .accessibilityLabel(Text("Subscription status", comment: "VoiceOver label for subscription status"))
        }
    }

    private var aiProviderSection: some View {
        Section(Text("AI Provider", comment: "AI provider section title")) {
            VStack(alignment: .leading, spacing: 8) {
                SecureField("API Key", text: $keyDraft)
                    .textContentType(.password)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                
                if isAPIKeyVisible {
                    TextField(NSLocalizedString("Enter API Key", comment: "API key text field"), text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField(NSLocalizedString("Enter API Key", comment: "API key secure field"), text: $apiKey)
                        .textContentType(.password)
                }
                Toggle(isOn: $isAPIKeyVisible) {
                    Text("Show Key", comment: "Show API key toggle")
                }
                .accessibilityHint(Text("Toggles between showing and hiding your API key.", comment: "Show key accessibility hint"))
            }
            .accessibilityElement(children: .combine)

            HStack {
                Button(NSLocalizedString("Save API Key", comment: "Save API key button")) {
                    saveAPIKey()
                    keyDraft = apiKey
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityHint(Text("Stores your key securely in the Keychain.", comment: "Save key hint"))

                Button(NSLocalizedString("Remove", comment: "Remove API key button"), role: .destructive) {
                    removeAPIKey()
                    keyDraft = ""
                }
                .disabled(keyDraft.isEmpty)
            }

            Text("Processly stores keys securely on-device in the iOS Keychain.", comment: "Keychain storage description")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("You can create a key at your provider's dashboard.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityHint(Text("Your API key never leaves the device without your consent.", comment: "Keychain info hint"))
        }
    }

    private var defaultsSection: some View {
        Section(Text("Defaults", comment: "Defaults section title")) {
            Picker(NSLocalizedString("Default Export", comment: "Default export picker"), selection: binding(for: \UserPrefs.defaultExport)) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Text(formatTitle(format)).tag(format)
                }
            }
            Picker(NSLocalizedString("ASR Engine", comment: "ASR engine picker"), selection: binding(for: \UserPrefs.asrEngine)) {
                ForEach(ASREngine.allCases, id: \.self) { engine in
                    Text(engineTitle(engine)).tag(engine)
                }
            }
        }
    }

    private var quotaSection: some View {
        Section(Text("Quota", comment: "Quota section title")) {
            if let pref = prefs.first {
                Text(String.localizedStringWithFormat(NSLocalizedString("Used: %d / 5 (resets %@)", comment: "Quota usage label"), pref.monthlyQuotaUsed, pref.quotaCycleStart.addingTimeInterval(30 * 24 * 60 * 60).formatted(.dateTime.month().day())))
                    .font(.subheadline)
                    .accessibilityLabel(Text("Free quota remaining", comment: "Quota VoiceOver label"))
            }
        }
    }

    private var supportSection: some View {
        Section(Text("Support", comment: "Support section title")) {
            Button(NSLocalizedString("Help & How-To", comment: "Help button")) {
                showingHelpSheet = true
            }
            
            Button(NSLocalizedString("Manage Subscription", comment: "Manage subscription button")) {
                // TODO: Link to deep link in-app subscription management when available.
            }
        }
    }

    private var legalSection: some View {
        Section(Text(NSLocalizedString("settings.legal", comment: "Legal section title"))) {
            Text(NSLocalizedString("settings.ai_disclosure", comment: "AI disclosure copy"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { openExternalURL(AppConstants.LegalLinks.privacyPolicy) }) {
                Label(NSLocalizedString("settings.privacy_policy", comment: "Privacy policy label"), systemImage: "link")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .a11y(
                id: "settings.privacy",
                label: String(localized: "settings.privacy_policy"),
                traits: .link
            )

            Button(action: { openExternalURL(AppConstants.LegalLinks.termsOfService) }) {
                Label(NSLocalizedString("settings.terms", comment: "Terms of service label"), systemImage: "doc.text")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .a11y(
                id: "settings.terms",
                label: String(localized: "settings.terms"),
                traits: .link
            )
        }
    }

    private func saveAPIKey() {
        let trimmed = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        KeychainStore.setString(trimmed, for: KeychainStore.Key.llmAPIKey)
        apiKey = trimmed
        toastMessage = NSLocalizedString("API key saved.", comment: "API key saved toast")
    }

    private func removeAPIKey() {
        KeychainStore.removeString(for: KeychainStore.Key.llmAPIKey)
        apiKey = ""
        keyDraft = ""
        toastMessage = NSLocalizedString("API key removed.", comment: "API key removed toast")
    }

    private func analyticsEnabledBinding() -> Binding<Bool> {
        let base = binding(for: \UserPrefs.analyticsEnabled)
        return Binding(
            get: { base.wrappedValue },
            set: { newValue in
                base.wrappedValue = newValue
                MetricsService.configure(defaultEnabled: newValue)
            }
        )
    }

    private func binding<Value>(for keyPath: ReferenceWritableKeyPath<UserPrefs, Value>) -> Binding<Value> {
        ensurePrefs()
        guard let pref = prefs.first else {
            fatalError("UserPrefs missing")
        }
        return Binding(
            get: { pref[keyPath: keyPath] },
            set: { newValue in
                pref[keyPath: keyPath] = newValue
                try? context.save()
            }
        )
    }

    private func ensurePrefs() {
        if prefs.isEmpty {
            let pref = UserPrefs()
            context.insert(pref)
            try? context.save()
        }
    }

    private func formatTitle(_ format: ExportFormat) -> String {
        switch format {
        case .pdf: return "PDF"
        case .docx: return "DOCX"
        case .markdown: return "Markdown"
        }
    }

    private func engineTitle(_ engine: ASREngine) -> String {
        switch engine {
        case .ios: return "iOS Speech"
        case .whisper: return "Whisper (Coming Soon)"
        }
    }

    private var microphoneStatusText: String {
        switch micPermission {
        case .granted:
            return NSLocalizedString("Microphone access is on so Processly can listen when you tap Record.", comment: "Mic permission granted message")
        case .denied:
            return NSLocalizedString("Microphone access is off. Enable it in Settings to capture voice notes.", comment: "Mic permission denied message")
        case .undetermined:
            return NSLocalizedString("We'll request microphone access the next time you record.", comment: "Mic permission undetermined message")
        @unknown default:
            return NSLocalizedString("Microphone permission status is unknown.", comment: "Mic permission unknown message")
        }
    }

    private var microphoneStatusColor: Color {
        micPermission == .denied ? .red : .secondary
    }

    private var speechStatusText: String {
        switch speechPermission {
        case .authorized:
            return NSLocalizedString("Speech recognition is on so Processly can turn your words into steps.", comment: "Speech permission granted message")
        case .denied:
            return NSLocalizedString("Speech recognition is off. Enable it in Settings to transcribe automatically.", comment: "Speech permission denied message")
        case .notDetermined:
            return NSLocalizedString("We'll request speech recognition access the next time you generate a process.", comment: "Speech permission undetermined message")
        case .restricted:
            return NSLocalizedString("Speech recognition isn't available for this device or profile.", comment: "Speech permission restricted message")
        @unknown default:
            return NSLocalizedString("Speech recognition permission status is unknown.", comment: "Speech permission unknown message")
        }
    }

    private var speechStatusColor: Color {
        switch speechPermission {
        case .denied, .restricted:
            return .red
        default:
            return .secondary
        }
    }

    private var shouldShowSettingsLink: Bool {
        Self.shouldShowSettingsLink(microphonePermission: micPermission, speechPermission: speechPermission)
    }

    static func shouldShowSettingsLink(microphonePermission: AVAudioSession.RecordPermission, speechPermission: SFSpeechRecognizerAuthorizationStatus) -> Bool {
        microphonePermission == .denied || speechPermission == .denied
    }

    private func refreshPermissions() {
        micPermission = AVAudioSession.sharedInstance().recordPermission
        speechPermission = SFSpeechRecognizer.authorizationStatus()
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    private func openExternalURL(_ url: URL) {
        openURL(url)
    }
}

private struct TagEditor: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(L10n.Edit.toolPlaceholder, text: $newTag)
                    .textFieldStyle(.roundedBorder)
                Button(L10n.Edit.addStep) {
                    let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if !tags.contains(trimmed) {
                        tags.append(trimmed)
                    }
                    newTag = ""
                }
            }
            FlowLayout(tags: tags)
        }
    }
}

private struct FlowLayout: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
        }
    }
}

private struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Voice Capture") {
                    Text("Tap the microphone button to start recording. Speak clearly and Processly will transcribe your words into structured steps.")
                }
                
                Section("API Key Setup") {
                    Text("Go to Settings > AI Provider and enter your OpenAI or Anthropic API key. Keys are stored securely in your device's Keychain.")
                }
                
                Section("Free Quota") {
                    Text("Free users get 5 generations per month. Upgrade to Pro for unlimited generations and premium export formats.")
                }
                
                Section("Export Formats") {
                    Text("PDF exports are free. DOCX and Markdown exports require Pro subscription. All exports can include watermarks.")
                }
                
                Section("Purchases") {
                    Text("Manage subscriptions through your Apple ID settings or the App Store. Pro features unlock unlimited generations and premium exports.")
                }
            }
            .navigationTitle("Help & How-To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#if DEBUG
extension SettingsView {
    @MainActor static func screenshotMock() -> some View {
        let dependencies = AppDependencyContainer()
        return NavigationStack {
            SettingsView()
        }
        .environmentObject(dependencies)
        .environmentObject(dependencies.router)
        .environmentObject(dependencies.metrics)
        .environmentObject(dependencies.iapService)
        .environmentObject(dependencies.quotaService)
        .environmentObject(dependencies.networkMonitor)
        .environmentObject(dependencies.generationQueue)
    }
}
#endif
