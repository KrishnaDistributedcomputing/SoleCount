import Foundation
import StoreKit
import Observation

// Handles the one-time "SoleCount Pro" purchase with StoreKit 2.
// No servers needed: Apple's StoreKit checks the purchase on the phone.
@MainActor
@Observable
final class StoreManager {
    static let proProductID = "com.krishnav.SoleCount.pro"
    static let freePairLimit = 3
    private static let isProKey = "isPro"

    private(set) var proProduct: Product?
    private(set) var isPro: Bool = UserDefaults.standard.bool(forKey: StoreManager.isProKey)
    private(set) var isLoading = false

    // Used to show an error alert.
    var showError = false
    private(set) var errorMessage = ""

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        // Listen for purchases that happen outside the app
        // (e.g. Ask to Buy approved later, refunds, purchases on another device).
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await refresh() }
    }

    func refresh() async {
        await loadProducts()
        await updateEntitlements()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            proProduct = products.first
        } catch {
            fail("Couldn't load the App Store. Check your internet connection and try again.")
        }
    }

    /// Asks StoreKit what this Apple Account owns.
    func updateEntitlements() async {
        var ownsPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                ownsPro = true
            }
        }
        setPro(ownsPro)
    }

    func purchase() async {
        guard let product = proProduct else {
            await loadProducts()
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    setPro(true)
                    await transaction.finish()
                case .unverified:
                    fail("We couldn't verify this purchase. Please try again.")
                }
            case .pending:
                fail("Your purchase is waiting for approval (for example Ask to Buy). Pro will unlock automatically once it's approved.")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            fail("The purchase didn't go through: \(error.localizedDescription)")
        }
    }

    /// Required by App Review: lets people get Pro back on a new phone.
    func restore() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
        } catch {
            // The user may have cancelled the sign-in prompt; still check below.
        }
        await updateEntitlements()
        if !isPro {
            fail("No previous SoleCount Pro purchase was found for this Apple Account.")
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result {
            await transaction.finish()
        }
        await updateEntitlements()
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: Self.isProKey)
    }

    private func fail(_ message: String) {
        errorMessage = message
        showError = true
    }
}
