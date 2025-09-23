import Foundation
import StoreKit
import Combine

@MainActor
final class IAPService: ObservableObject {
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var prices: [String: String] = [:]
    @Published private(set) var entitlements: Set<Entitlement> = []
    @Published var statusMessage: String?
    @Published var purchaseSheetReady = false

    private var updatesTask: Task<Void, Never>? = nil
    private let metrics: MetricsReporter
    private let defaults = UserDefaults.standard
    private let entitlementCacheKey = "com.processly.entitlements.cache"

    init(metrics: MetricsReporter) {
        self.metrics = metrics
        self.entitlements = loadCachedEntitlements()
        updatesTask = listenForTransactions()
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        purchaseSheetReady = false
        statusMessage = nil
        defer { purchaseSheetReady = true }

        do {
            let products = try await Product.products(for: IAPProduct.allCases.map { $0.rawValue })
            if products.isEmpty {
                prices = [:]
                subscriptions = []
                statusMessage = NSLocalizedString("Products unavailable. Please try again.", comment: "Products unavailable")
                metrics.track(event: .error(type: .iap, context: "product_load_empty"))
            } else {
                subscriptions = products.sorted { $0.price < $1.price }
                statusMessage = nil
                var newPrices: [String: String] = [:]
                for product in products {
                    newPrices[product.id] = product.displayPrice
                }
            
                prices = newPrices
            }
        } catch {
            subscriptions = []
            metrics.track(event: .error(type: .iap, context: "product_load_failed"))
            statusMessage = NSLocalizedString("We couldn\'t load subscriptions. Check your network and try again.", comment: "Product load error")
        }
    }

    func refreshSubscriptions() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func purchase(sku: String) async {
        guard let product = subscriptions.first(where: { $0.id == sku }) else {
            statusMessage = NSLocalizedString("We\'re fetching product details. Please try again in a moment.", comment: "Missing product")
            await loadProducts()
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await transaction.finish()
                await refreshEntitlements()
                metrics.track(event: .iapPurchaseSuccess(sku: product.id))
                statusMessage = NSLocalizedString("Purchase successful!", comment: "Purchase success")
            case .pending:
                statusMessage = NSLocalizedString("Purchase pending. We\'ll unlock Pro once Apple confirms.", comment: "Purchase pending")
            case .userCancelled:
                statusMessage = NSLocalizedString("Purchase cancelled.", comment: "Purchase cancelled")
            @unknown default:
                statusMessage = NSLocalizedString("Purchase state unknown. Please try again.", comment: "Purchase unknown")
            }
        } catch {
            metrics.track(event: .error(type: .iap, context: "purchase_failed"))
            statusMessage = mapPurchaseError(error)
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusMessage = NSLocalizedString("Purchases restored.", comment: "Restore success")
        } catch {
            metrics.track(event: .error(type: .iap, context: "restore_failed"))
            statusMessage = NSLocalizedString("Restore failed. Check your network and try again.", comment: "Restore failure")
        }
    }

    func hasAccess(_ entitlement: Entitlement) -> Bool {
        entitlements.contains(entitlement)
    }

    // MARK: - Transaction handling

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    if let revocationDate = transaction.revocationDate, revocationDate <= Date() {
                        await MainActor.run {
                            self.statusMessage = NSLocalizedString("Your subscription was revoked. Pro features have been disabled.", comment: "Revoked subscription")
                        }
                    }
                    await transaction.finish()
                    await self.refreshEntitlements()
                } catch {
                    await MainActor.run {
                        self.metrics.track(event: .error(type: .iap, context: "transaction_update_failed"))
                        self.statusMessage = NSLocalizedString("We hit an issue updating your subscription. Please retry.", comment: "Transaction update failure")
                    }
                }
            }
        }
    }

    private func refreshEntitlements() async {
        var activeEntitlements: Set<Entitlement> = []
        for await transaction in Transaction.currentEntitlements {
            guard transaction.revocationDate == nil else { continue }
            let productID = transaction.productID
            activeEntitlements.formUnion(Entitlement.entitlements(forProductID: productID))
        }
        await MainActor.run {
            self.entitlements = activeEntitlements
            self.cache(entitlements: activeEntitlements)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.notVerified
        case .verified(let transaction):
            return transaction
        }
    }

    private func cache(entitlements: Set<Entitlement>) {
        let values = entitlements.map { $0.rawValue }
        defaults.set(values, forKey: entitlementCacheKey)
    }

    private func loadCachedEntitlements() -> Set<Entitlement> {
        guard let rawValues = defaults.array(forKey: entitlementCacheKey) as? [String] else {
            return []
        }
        return Set(rawValues.compactMap { Entitlement(rawValue: $0) })
    }
    
    private func mapPurchaseError(_ error: Error) -> String {
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .notVerified:
                return NSLocalizedString("Purchase verification failed. Please try again.", comment: "Verification failed")
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return NSLocalizedString("No internet connection. Please check your network and try again.", comment: "Network error")
            case .timedOut:
                return NSLocalizedString("Request timed out. Please try again.", comment: "Timeout error")
            default:
                return NSLocalizedString("Network error. Please try again.", comment: "Generic network error")
            }
        }
        
        if let nsError = error as? NSError {
            switch nsError.code {
            case 0: // userCancelled
                return NSLocalizedString("Purchase cancelled.", comment: "User cancelled")
            case 1: // clientInvalid
                return NSLocalizedString("Purchase not allowed on this device.", comment: "Client invalid")
            case 2: // paymentCancelled
                return NSLocalizedString("Payment was cancelled.", comment: "Payment cancelled")
            case 3: // paymentInvalid
                return NSLocalizedString("Invalid payment method.", comment: "Payment invalid")
            case 4: // paymentNotAllowed
                return NSLocalizedString("Payment not allowed. Check your device settings.", comment: "Payment not allowed")
            case 5: // storeProductNotAvailable
                return NSLocalizedString("Product not available. Please try again later.", comment: "Product unavailable")
            case 6: // cloudServicePermissionDenied
                return NSLocalizedString("Cloud service access denied. Check your settings.", comment: "Cloud service denied")
            case 7: // cloudServiceNetworkConnectionFailed
                return NSLocalizedString("Cloud service connection failed. Please try again.", comment: "Cloud service failed")
            case 8: // cloudServiceRevoked
                return NSLocalizedString("Cloud service access revoked. Please sign in again.", comment: "Cloud service revoked")
            default:
                return NSLocalizedString("Purchase failed. Please try again.", comment: "Generic purchase error")
            }
        }
        
        return NSLocalizedString("We couldn't complete the purchase. Please try again.", comment: "Generic purchase failure")
    }
}

enum StoreKitError: Error {
    case notVerified
}

enum IAPProduct: String, CaseIterable {
    case proMonthly799 = "pro_monthly_799"
    case proYearly4999 = "pro_yearly_4999"

    var entitlements: Set<Entitlement> {
        switch self {
        case .proMonthly799, .proYearly4999:
            return [.proUnlimited, .exportPremium]
        }
    }
}

enum Entitlement: String, CaseIterable, Hashable {
    case proUnlimited
    case exportPremium

    static func entitlements(forProductID productID: String) -> Set<Entitlement> {
        guard let product = IAPProduct(rawValue: productID) else { return [] }
        return product.entitlements
    }
}
