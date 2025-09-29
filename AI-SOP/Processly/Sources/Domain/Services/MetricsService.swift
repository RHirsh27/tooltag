import Foundation

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

enum MetricsEvent: String {
    case app_launch
    case onboarding_complete
    case first_finalize
    case gen_latency
    case template_created
    case template_duplicated
    case template_deleted
    case capture_started
    case sop_edited
    case sop_generated
    case generation_latency_sample
    case error
    case export_clicked
    case export_success
    case onboarding_viewed
    case paywall_viewed
    case quota_blocked
    case sop_finalized
    case first_sop
    case sop_generation_failed
    case iap_purchase_success
    case iap_purchase_failed
    case iap_restore_failed
    case speech_recognition_error
    case speech_recognition_interrupted
    case share_initiated
    case share_completed
    case share_failed
    case tab_switched
    case settings_opened
    case help_viewed
    case sop_deleted
    case sop_duplicated
    case sop_archived
    case sop_unarchived
    case search_performed
    case filter_applied
    case sort_changed
    case attachment_added
    case attachment_removed
    case voice_note_added
    case voice_note_removed
    case checklist_item_added
    case checklist_item_removed
    case step_reordered
    case step_duplicated
    case step_deleted
    case duration_estimated
    case sop_favorited
    case sop_unfavorited
}

struct MetricsService {
    static var enabled = true
    static var userOptIn = true

    static func configure(defaultEnabled: Bool) {
        userOptIn = defaultEnabled
    }

    static func log(_ event: MetricsEvent, properties: [String: Any]? = nil) {
        guard enabled, userOptIn else { return }
        
        #if canImport(FirebaseAnalytics)
        if userOptIn {
            let safeProperties = properties?.compactMapValues { value in
                if let string = value as? String { return string }
                if let number = value as? NSNumber { return number }
                return nil
            }
            Analytics.logEvent(event.rawValue, parameters: safeProperties)
        } else {
            let propsDescription: String
            if let properties, properties.isEmpty == false {
                let pairs = properties.map { key, value in "\(key): \(value)" }
                propsDescription = "{" + pairs.joined(separator: ", ") + "}"
            } else {
                propsDescription = "{}"
            }
            print("Metrics: \(event.rawValue) \(propsDescription)")
        }
        #else
        let propsDescription: String
        if let properties, properties.isEmpty == false {
            let pairs = properties.map { key, value in "\(key): \(value)" }
            propsDescription = "{" + pairs.joined(separator: ", ") + "}"
        } else {
            propsDescription = "{}"
        }
        print("Metrics: \(event.rawValue) \(propsDescription)")
        #endif
    }

    static func appLaunch() {
        log(.app_launch)
    }

    static func onboardingComplete() {
        log(.onboarding_complete)
    }

    static func firstFinalize(deltaSeconds: Double) {
        log(.first_finalize, properties: ["deltaSeconds": deltaSeconds])
    }

    static func genLatency(p50: Double, p90: Double) {
        log(.gen_latency, properties: ["p50": p50, "p90": p90])
    }
    
    static func templateCreated() {
        log(.template_created)
    }
    
    static func templateDuplicated() {
        log(.template_duplicated)
    }
    
    static func templateDeleted() {
        log(.template_deleted)
    }
    
    static func captureStarted(mode: String) {
        log(.capture_started, properties: ["mode": mode])
    }
    
    static func sopEdited() {
        log(.sop_edited)
    }
    
    static func sopGenerated(tokensIn: Int, steps: Int) {
        log(.sop_generated, properties: ["tokens_in": tokensIn, "steps": steps])
    }
    
    static func generationLatencySample(milliseconds: Double) {
        log(.generation_latency_sample, properties: ["latency_ms": milliseconds])
    }
    
    static func error(type: String, context: String) {
        log(.error, properties: ["error_type": type, "context": context])
    }
    
    static func exportClicked(format: String) {
        log(.export_clicked, properties: ["format": format])
    }
    
    static func exportSuccess(format: String) {
        log(.export_success, properties: ["format": format])
    }
    
    // MARK: - User Journey Events
    static func onboardingViewed() {
        log(.onboarding_viewed)
    }
    
    static func paywallViewed(trigger: String) {
        log(.paywall_viewed, properties: ["trigger": trigger])
    }
    
    static func quotaBlocked() {
        log(.quota_blocked)
    }
    
    static func sopFinalized() {
        log(.sop_finalized)
    }
    
    static func firstSOP(seconds: Double) {
        log(.first_sop, properties: ["seconds": seconds])
    }
    
    static func sopGenerationFailed(reason: String) {
        log(.sop_generation_failed, properties: ["reason": reason])
    }
    
    // MARK: - IAP Events
    static func iapPurchaseSuccess(sku: String) {
        log(.iap_purchase_success, properties: ["sku": sku])
    }
    
    static func iapPurchaseFailed(reason: String) {
        log(.iap_purchase_failed, properties: ["reason": reason])
    }
    
    static func iapRestoreFailed(reason: String) {
        log(.iap_restore_failed, properties: ["reason": reason])
    }
    
    // MARK: - Speech Recognition Events
    static func speechRecognitionError(context: String) {
        log(.speech_recognition_error, properties: ["context": context])
    }
    
    static func speechRecognitionInterrupted() {
        log(.speech_recognition_interrupted)
    }
    
    // MARK: - Sharing Events
    static func shareInitiated(type: String) {
        log(.share_initiated, properties: ["type": type])
    }
    
    static func shareCompleted(type: String) {
        log(.share_completed, properties: ["type": type])
    }
    
    static func shareFailed(type: String, reason: String) {
        log(.share_failed, properties: ["type": type, "reason": reason])
    }
    
    // MARK: - Navigation Events
    static func tabSwitched(to: String) {
        log(.tab_switched, properties: ["to": to])
    }
    
    static func settingsOpened() {
        log(.settings_opened)
    }
    
    static func helpViewed() {
        log(.help_viewed)
    }
    
    // MARK: - SOP Management Events
    static func sopDeleted() {
        log(.sop_deleted)
    }
    
    static func sopDuplicated() {
        log(.sop_duplicated)
    }
    
    static func sopArchived() {
        log(.sop_archived)
    }
    
    static func sopUnarchived() {
        log(.sop_unarchived)
    }
    
    static func sopFavorited() {
        log(.sop_favorited)
    }
    
    static func sopUnfavorited() {
        log(.sop_unfavorited)
    }
    
    // MARK: - Search and Filter Events
    static func searchPerformed(query: String) {
        log(.search_performed, properties: ["query": query])
    }
    
    static func filterApplied(filter: String) {
        log(.filter_applied, properties: ["filter": filter])
    }
    
    static func sortChanged(sortBy: String) {
        log(.sort_changed, properties: ["sort_by": sortBy])
    }
    
    // MARK: - Content Events
    static func attachmentAdded(type: String) {
        log(.attachment_added, properties: ["type": type])
    }
    
    static func attachmentRemoved(type: String) {
        log(.attachment_removed, properties: ["type": type])
    }
    
    static func voiceNoteAdded() {
        log(.voice_note_added)
    }
    
    static func voiceNoteRemoved() {
        log(.voice_note_removed)
    }
    
    static func checklistItemAdded() {
        log(.checklist_item_added)
    }
    
    static func checklistItemRemoved() {
        log(.checklist_item_removed)
    }
    
    static func stepReordered() {
        log(.step_reordered)
    }
    
    static func stepDuplicated() {
        log(.step_duplicated)
    }
    
    static func stepDeleted() {
        log(.step_deleted)
    }
    
    static func durationEstimated(duration: Int) {
        log(.duration_estimated, properties: ["duration": duration])
    }
}

// MARK: - Console Metrics Service
protocol MetricsReporter {
    func track(event: MetricsEvent, properties: [String: Any]? = nil)
}

@MainActor
final class ConsoleMetricsService: ObservableObject, MetricsReporter {
    func track(event: MetricsEvent, properties: [String: Any]? = nil) {
        MetricsService.log(event, properties: properties)
    }
}

// MARK: - Metrics Event Extensions
extension MetricsEvent {
    var appLaunch: MetricsEvent { .app_launch }
    var templateCreated: MetricsEvent { .template_created }
    var templateDuplicated: MetricsEvent { .template_duplicated }
    var templateDeleted: MetricsEvent { .template_deleted }
    var captureStarted: MetricsEvent { .capture_started }
    var sopEdited: MetricsEvent { .sop_edited }
    var sopGenerated: MetricsEvent { .sop_generated }
    var generationLatencySample: MetricsEvent { .generation_latency_sample }
    var error: MetricsEvent { .error }
    var exportClicked: MetricsEvent { .export_clicked }
    var exportSuccess: MetricsEvent { .export_success }
    var onboardingViewed: MetricsEvent { .onboarding_viewed }
    var paywallViewed: MetricsEvent { .paywall_viewed }
    var quotaBlocked: MetricsEvent { .quota_blocked }
    var sopFinalized: MetricsEvent { .sop_finalized }
    var firstSOP: MetricsEvent { .first_sop }
    var sopGenerationFailed: MetricsEvent { .sop_generation_failed }
    var iapPurchaseSuccess: MetricsEvent { .iap_purchase_success }
    var iapPurchaseFailed: MetricsEvent { .iap_purchase_failed }
    var iapRestoreFailed: MetricsEvent { .iap_restore_failed }
    var speechRecognitionError: MetricsEvent { .speech_recognition_error }
    var speechRecognitionInterrupted: MetricsEvent { .speech_recognition_interrupted }
    var shareInitiated: MetricsEvent { .share_initiated }
    var shareCompleted: MetricsEvent { .share_completed }
    var shareFailed: MetricsEvent { .share_failed }
    var tabSwitched: MetricsEvent { .tab_switched }
    var settingsOpened: MetricsEvent { .settings_opened }
    var helpViewed: MetricsEvent { .help_viewed }
    var sopDeleted: MetricsEvent { .sop_deleted }
    var sopDuplicated: MetricsEvent { .sop_duplicated }
    var sopArchived: MetricsEvent { .sop_archived }
    var sopUnarchived: MetricsEvent { .sop_unarchived }
    var searchPerformed: MetricsEvent { .search_performed }
    var filterApplied: MetricsEvent { .filter_applied }
    var sortChanged: MetricsEvent { .sort_changed }
    var attachmentAdded: MetricsEvent { .attachment_added }
    var attachmentRemoved: MetricsEvent { .attachment_removed }
    var voiceNoteAdded: MetricsEvent { .voice_note_added }
    var voiceNoteRemoved: MetricsEvent { .voice_note_removed }
    var checklistItemAdded: MetricsEvent { .checklist_item_added }
    var checklistItemRemoved: MetricsEvent { .checklist_item_removed }
    var stepReordered: MetricsEvent { .step_reordered }
    var stepDuplicated: MetricsEvent { .step_duplicated }
    var stepDeleted: MetricsEvent { .step_deleted }
    var durationEstimated: MetricsEvent { .duration_estimated }
    var sopFavorited: MetricsEvent { .sop_favorited }
    var sopUnfavorited: MetricsEvent { .sop_unfavorited }
}

