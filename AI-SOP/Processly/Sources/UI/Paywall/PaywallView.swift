import SwiftUI
import StoreKit
import SafariServices
import UIKit

struct PaywallView: View {
    @EnvironmentObject private var dependencies: AppDependencyContainer
    @EnvironmentObject private var iapService: IAPService
    @EnvironmentObject private var router: AppRouter
    let trigger: PaywallTrigger
    @State private var purchaseError: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Upgrade to \(Brand.proName)")
                .font(.title2)
            Text("Unlimited processes. PDF/DOCX/Markdown. No watermark.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            planOptionsView

            Button(String(localized: "paywall.restore")) {
                Task { await restorePurchases() }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .a11y(
                id: "paywall.restore",
                label: String(localized: "paywall.a11y.restore"),
                traits: .button
            )

            if let purchaseError {
                Text(purchaseError)
                    .foregroundColor(.red)
            } else if let statusMessage = iapService.statusMessage {
                Text(statusMessage)
                    .foregroundColor(.secondary)
                dependencies.presentToast(statusMessage)
            }
            
            Text("Auto-renewing subscription. Cancel anytime in Settings > Apple ID > Subscriptions. Payment is charged to your Apple ID. Subscription renews unless cancelled at least 24 hours before the end of the period.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button("Privacy Policy") {
                    openURL(AppConstants.privacyURL)
                }
                .font(.footnote)
                .foregroundColor(.blue)
                
                Button("Terms of Service") {
                    openURL(AppConstants.termsURL)
                }
                .font(.footnote)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.headline)
                }
                .a11y(
                    id: "paywall.close",
                    label: String(localized: "paywall.a11y.close"),
                    traits: .button
                )
            }
        }
        .task {
            dependencies.metrics.track(event: .paywallViewed(trigger: trigger))
            await iapService.refreshSubscriptions()
        }
    }

    private func purchase(_ product: Product) async {
        do {
            try await iapService.purchase(sku: product.id)
            purchaseError = nil
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func close() {
        router.pop()
    }
    
    private func restorePurchases() async {
        await iapService.restorePurchases()
        if let statusMessage = iapService.statusMessage {
            dependencies.presentToast(statusMessage)
        }
    }
    
    private func openURL(_ url: URL) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(SFSafariViewController(url: url), animated: true)
        }
    }

    private func accessibilityIdentifier(for productID: String) -> String {
        switch productID {
        case IAPProduct.proMonthly799.rawValue:
            return "paywall.buy.monthly"
        case IAPProduct.proYearly4999.rawValue:
            return "paywall.buy.yearly"
        default:
            return "paywall.buy.\(productID)"
        }
    }

    private func accessibilityLabel(for productID: String) -> String {
        switch productID {
        case IAPProduct.proMonthly799.rawValue:
            return String(localized: "paywall.a11y.buy.monthly")
        case IAPProduct.proYearly4999.rawValue:
            return String(localized: "paywall.a11y.buy.yearly")
        default:
            return String(localized: "paywall.a11y.buy.generic")
        }
    }
    
    @ViewBuilder
    private var planOptionsView: some View {
        if iapService.subscriptions.isEmpty && iapService.statusMessage == nil {
            ProgressView("Loading plans...")
                .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 16) {
                ForEach(iapService.subscriptions, id: \.id) { product in
                    Button {
                        Task { await purchase(product) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.displayName)
                                    .font(.headline)
                                if product.id == IAPProduct.proMonthly799.rawValue || product.id == IAPProduct.proYearly4999.rawValue {
                                    Text("Unlimited processes. PDF/DOCX/Markdown. No watermark.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(iapService.prices[product.id] ?? "—")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if product.id == IAPProduct.proYearly4999.rawValue {
                                Text("Best Value")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .a11y(
                        id: accessibilityIdentifier(for: product.id),
                        label: accessibilityLabel(for: product.id),
                        traits: .button
                    )
                }
            }
        }
    }
}
