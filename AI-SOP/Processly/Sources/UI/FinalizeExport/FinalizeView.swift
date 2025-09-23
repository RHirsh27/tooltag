import SwiftUI
import SwiftData
import UIKit

struct FinalizeView: View {
    private let firstFinalizeLoggedKey = "com.processly.metrics.firstFinalizeLogged"
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var dependencies: AppDependencyContainer
    let sopID: PersistentIdentifier
    @State private var sop: SOP?
    @State private var errorMessage: String?
    @State private var remainingQuota: Int?

    private var isQuotaBlocked: Bool {
        if let remainingQuota {
            return remainingQuota <= 0
        }
        return false
    }

    var body: some View {
        VStack(spacing: 24) {
            if let sop {
                Text(String.localizedStringWithFormat(String(localized: "finalize.title.prompt"), sop.title))
                    .font(.title2)
                Text(String(localized: "finalize.subtitle"))
                    .foregroundColor(.secondary)
                quotaLabel
                if isQuotaBlocked {
                    Text(String(localized: "finalize.quota.blocked"))
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .a11y(
                            id: "finalize.quota",
                            label: String(localized: "a11y.finalize.quota.label")
                        )
                    Button(String(localized: "finalize.upgrade.cta")) {
                        dependencies.router.push(.paywall(trigger: .quota))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .a11y(
                        id: "finalize.paywall",
                        label: String(localized: "a11y.finalize.paywall.label"),
                        traits: .button
                    )
                }
                Button(String(localized: "finalize.cta.title")) {
                    Task { await finalize() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .a11y(
                    id: "finalize.cta",
                    label: String(localized: "a11y.finalize.cta.label"),
                    hint: String(localized: "a11y.finalize.cta.hint"),
                    traits: .button
                )
                .disabled(isQuotaBlocked)
            } else {
                ProgressView()
                    .task(load)
            }
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .navigationTitle(String(localized: "finalize.nav.title"))
        .task {
            await load()
        }
    }

    @ViewBuilder
    private var quotaLabel: some View {
        if let remainingQuota {
            Text(String.localizedStringWithFormat(String(localized: "finalize.quota.remaining"), remainingQuota))
                .font(.subheadline)
        } else {
            Text(String(localized: "finalize.quota.unlimited"))
                .font(.subheadline)
        }
    }

    private func load() async {
        do {
            sop = try context.model(for: sopID) as? SOP
            remainingQuota = try dependencies.quotaService.remainingQuota(using: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finalize() async {
        guard let sop else { return }
        do {
            let canFinalize = try dependencies.quotaService.canFinalize(using: context)
            if canFinalize == false {
                dependencies.metrics.track(event: .quotaBlocked)
                dependencies.presentToast(String(localized: "finalize.toast.quota"))
                return
            }

            sop.status = .final
            sop.updatedAt = .now
            try context.save()
            try dependencies.quotaService.incrementFinalize(using: context)
            logFirstFinalizeIfNeeded()
            dependencies.presentToast(String(localized: "finalize.toast.success"))
            dependencies.router.push(.export(sopID: sopID))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func logFirstFinalizeIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: firstFinalizeLoggedKey) == false else { return }
        let installTimestamp = defaults.double(forKey: QuotaService.installTimestampKey)
        guard installTimestamp > 0 else { return }
        let deltaSeconds = max(0, Date().timeIntervalSince1970 - installTimestamp)
        MetricsService.firstFinalize(deltaSeconds: deltaSeconds)
        defaults.set(true, forKey: firstFinalizeLoggedKey)
    }
}
#if DEBUG
extension FinalizeView {
    @MainActor static func screenshotMock(isPro: Bool) -> some View {
        let dependencies = ScreenshotEnvironment.makeDependencies(isPro: isPro)
        let result = ScreenshotEnvironment.makeContainerWithSampleSOP(isPro: isPro, status: .draft)
        return ScreenshotScene(dependencies: dependencies, container: result.container) {
            FinalizeView(sopID: result.sop.persistentModelID)
        }
    }
}
#endif

