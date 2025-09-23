import SwiftUI

enum L10n {
    enum Home {
        static let title: LocalizedStringKey = "home.title"
        static let welcome: LocalizedStringKey = "home.welcome"
        static let subtitle: LocalizedStringKey = "home.subtitle"
        static let recordCTA: LocalizedStringKey = "home.record.cta"
        static let recordHint = String(localized: "home.record.hint")
        static let pasteCTA: LocalizedStringKey = "home.paste.cta"
        static let pasteHint = String(localized: "home.paste.hint")
        static let emptyMessage: LocalizedStringKey = "home.empty.message"
    }

    enum Onboarding {
        static let pageOneTitle: LocalizedStringKey = "onboarding.page1.title"
        static let pageOneSubtitle: LocalizedStringKey = "onboarding.page1.subtitle"
        static let pageTwoTitle: LocalizedStringKey = "onboarding.page2.title"
        static let pageTwoSubtitle: LocalizedStringKey = "onboarding.page2.subtitle"
        static let pageThreeTitle: LocalizedStringKey = "onboarding.page3.title"
        static let pageThreeSubtitle: LocalizedStringKey = "onboarding.page3.subtitle"
        static let next: LocalizedStringKey = "onboarding.next"
        static let getStarted: LocalizedStringKey = "onboarding.get_started"
        static let learnAboutPro: LocalizedStringKey = "onboarding.learn_about_pro"
    }

    enum Capture {
        static let title: LocalizedStringKey = "capture.title"
        static let prompt: LocalizedStringKey = "capture.prompt"
        static let recordingLabel: LocalizedStringKey = "capture.recording.label"
        static let stopLabel: LocalizedStringKey = "capture.stop.label"
        static let generateCTA: LocalizedStringKey = "capture.generate_cta"
        static let accessibilityHintRecord = String(localized: "capture.record.hint")
    }

    enum Paste {
        static let title: LocalizedStringKey = "paste.title"
        static let titleHintPlaceholder: LocalizedStringKey = "paste.title_hint_placeholder"
        static let textPlaceholder: LocalizedStringKey = "paste.text_placeholder"
        static let generateCTA: LocalizedStringKey = "paste.generate_cta"
    }

    enum Generate {
        static let title: LocalizedStringKey = "generate.title"
        static let generating: LocalizedStringKey = "generate.generating"
        static let successPrefix: LocalizedStringKey = "generate.success_prefix"
        static let continueEdit: LocalizedStringKey = "generate.continue_edit"
        static let retry: LocalizedStringKey = "generate.retry"
        static let failure: LocalizedStringKey = "generate.failure"
    }

    enum Edit {
        static let title: LocalizedStringKey = "edit.title"
        static let sectionTitle: LocalizedStringKey = "edit.section.title"
        static let titlePlaceholder: LocalizedStringKey = "edit.title_placeholder"
        static let sectionSummary: LocalizedStringKey = "edit.section.summary"
        static let summaryPlaceholder: LocalizedStringKey = "edit.summary_placeholder"
        static let sectionTools: LocalizedStringKey = "edit.section.tools"
        static let sectionSteps: LocalizedStringKey = "edit.section.steps"
        static let addStep: LocalizedStringKey = "edit.add_step"
        static let addTag: LocalizedStringKey = "edit.add_tag"
        static let errorMessage: LocalizedStringKey = "edit.error_message"
        static let toolPlaceholder: LocalizedStringKey = "edit.tool_placeholder"
        static let stepInstructionPlaceholder: LocalizedStringKey = "edit.step.instruction"
        static let stepNotesPlaceholder: LocalizedStringKey = "edit.step.notes"
        static let stepMinutesPlaceholder: LocalizedStringKey = "edit.step.minutes"
        static let notesPlaceholder: LocalizedStringKey = "edit.notes_placeholder"
        static let minutesPlaceholder: LocalizedStringKey = "edit.minutes_placeholder"
    }

    enum Finalize {
        static let title: LocalizedStringKey = "finalize.title"
        static let prompt: LocalizedStringKey = "finalize.prompt"
        static let quotaRemaining: LocalizedStringKey = "finalize.quota_remaining"
        static let unlimited: LocalizedStringKey = "finalize.unlimited"
        static let finalizeCTA: LocalizedStringKey = "finalize.button"
        static let finalizedToast = String(localized: "finalize.toast")
        static let quotaToast = String(localized: "finalize.quota_toast")
    }

    enum Export {
        static let title: LocalizedStringKey = "export.title"
        static let formatSegment: LocalizedStringKey = "export.format"
        static let exportCTA: LocalizedStringKey = "export.button"
        static let markdownMessage: LocalizedStringKey = "export.markdown.message"
        static let docxMessage: LocalizedStringKey = "export.docx.message"
        static let shareCTA: LocalizedStringKey = "export.share"
        static let premiumToast = String(localized: "export.premium_toast")
    }

    enum Paywall {
        static let title = String(localized: "paywall.title")
        static let subtitle: LocalizedStringKey = "paywall.subtitle"
        static let restore: LocalizedStringKey = "paywall.restore"
        static let close: LocalizedStringKey = "paywall.close"
    }

    enum Settings {
        static let title: LocalizedStringKey = "settings.title"
        static let accountSection: LocalizedStringKey = "settings.account"
        static let analyticsOptIn: LocalizedStringKey = "settings.analytics_optin"
        static let planPro: LocalizedStringKey = "settings.plan.pro"
        static let planFree: LocalizedStringKey = "settings.plan.free"
        static let aiDisclosure: LocalizedStringKey = "settings.ai_disclosure"
        static let defaultsSection: LocalizedStringKey = "settings.defaults"
        static let quotaSection: LocalizedStringKey = "settings.quota"
        static let supportSection: LocalizedStringKey = "settings.support"
        static let legalSection: LocalizedStringKey = "settings.legal"
        static let manageSubscription: LocalizedStringKey = "settings.manage_subscription"
        static let openSettings: LocalizedStringKey = "settings.open_ios"
        static let privacyPolicy: LocalizedStringKey = "settings.privacy_policy"
        static let termsOfService: LocalizedStringKey = "settings.terms"
        static let keychainInfo: LocalizedStringKey = "settings.keychain"
        static let apiKeyField: LocalizedStringKey = "settings.api_key_field"
        static let showKey: LocalizedStringKey = "settings.show_key"
        static let saveKey: LocalizedStringKey = "settings.save_key"
        static let removeKey: LocalizedStringKey = "settings.remove_key"
        static let apiKeySavedToast = String(localized: "settings.api_key_saved")
        static let apiKeyRemovedToast = String(localized: "settings.api_key_removed")
    }

    enum Toast {
        static let quotaExceeded = String(localized: "toast.quota_exceeded")
        static let generationFailure = String(localized: "toast.generation_failure")
    }

    enum Accessibility {
        static let recordHint = String(localized: "a11y.capture.record_hint")
        static let generateHint = String(localized: "a11y.capture.generate_hint")
        static let pasteGenerateHint = String(localized: "a11y.paste.generate_hint")
        static let editAddStep = String(localized: "a11y.edit.add_step")
        static let finalizeButtonHint = String(localized: "a11y.finalize.button_hint")
        static let exportButtonHint = String(localized: "a11y.export.button_hint")
        static let paywallCloseHint = String(localized: "a11y.paywall.close_hint")
        static let shareButtonHint = String(localized: "a11y.share.button_hint")
    }
}
