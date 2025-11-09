//
//  PurchaseManager.swift
//  MeshyApp
//
//  StoreKit In-App Purchase Manager
//

import Foundation
import StoreKit
import Combine

class PurchaseManager: NSObject, ObservableObject {
    static let shared = PurchaseManager()

    @Published var availableProducts: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var updates: Task<Void, Never>?
    private let authService = AuthenticationService.shared

    // Product IDs
    private let creditPackageIDs = [
        "com.meshyapp.credits.50",
        "com.meshyapp.credits.100",
        "com.meshyapp.credits.250",
        "com.meshyapp.credits.500",
        "com.meshyapp.credits.1000"
    ]

    private let subscriptionIDs = [
        "com.meshyapp.subscription.monthly",
        "com.meshyapp.subscription.yearly"
    ]

    // Credit packages configuration
    let creditPackages: [CreditPackage] = [
        CreditPackage(
            id: "com.meshyapp.credits.50",
            credits: 50,
            price: 4.99,
            productIdentifier: "com.meshyapp.credits.50",
            bonus: 0,
            isPopular: false
        ),
        CreditPackage(
            id: "com.meshyapp.credits.100",
            credits: 100,
            price: 8.99,
            productIdentifier: "com.meshyapp.credits.100",
            bonus: 10,
            isPopular: true
        ),
        CreditPackage(
            id: "com.meshyapp.credits.250",
            credits: 250,
            price: 19.99,
            productIdentifier: "com.meshyapp.credits.250",
            bonus: 50,
            isPopular: false
        ),
        CreditPackage(
            id: "com.meshyapp.credits.500",
            credits: 500,
            price: 34.99,
            productIdentifier: "com.meshyapp.credits.500",
            bonus: 150,
            isPopular: false
        ),
        CreditPackage(
            id: "com.meshyapp.credits.1000",
            credits: 1000,
            price: 59.99,
            productIdentifier: "com.meshyapp.credits.1000",
            bonus: 400,
            isPopular: false
        )
    ]

    // Subscription plans configuration
    let subscriptionPlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: "com.meshyapp.subscription.monthly",
            type: .monthly,
            monthlyCredits: 200,
            price: 19.99,
            productIdentifier: "com.meshyapp.subscription.monthly",
            features: [
                "200 credits per month",
                "Priority generation queue",
                "Advanced AI models",
                "Unlimited AR viewing",
                "Export in all formats"
            ],
            isPopular: false
        ),
        SubscriptionPlan(
            id: "com.meshyapp.subscription.yearly",
            type: .yearly,
            monthlyCredits: 250,
            price: 179.99,
            productIdentifier: "com.meshyapp.subscription.yearly",
            features: [
                "250 credits per month",
                "Batch Generation (Exclusive)",
                "Priority generation queue",
                "Advanced AI models",
                "Unlimited AR viewing",
                "Export in all formats",
                "Early access to new features",
                "Best value - Save 25%"
            ],
            isPopular: true
        )
    ]

    private override init() {
        super.init()
        updates = observeTransactionUpdates()
    }

    deinit {
        updates?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true

        do {
            let allProductIDs = creditPackageIDs + subscriptionIDs
            let products = try await Product.products(for: allProductIDs)

            await MainActor.run {
                self.availableProducts = products
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Grant credits or subscription
            await handleSuccessfulPurchase(transaction: transaction)

            // Finish the transaction
            await transaction.finish()

        case .userCancelled:
            throw PurchaseError.cancelled

        case .pending:
            throw PurchaseError.pending

        @unknown default:
            throw PurchaseError.unknown
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)

            // Re-grant subscriptions if active
            if transaction.productType == .autoRenewable {
                await handleSuccessfulPurchase(transaction: transaction)
            }

            await transaction.finish()
        }
    }

    // MARK: - Handle Purchase

    private func handleSuccessfulPurchase(transaction: Transaction) async {
        guard let userId = authService.user?.id else { return }

        // Handle credit packages
        if creditPackageIDs.contains(transaction.productID) {
            if let package = creditPackages.first(where: { $0.productIdentifier == transaction.productID }) {
                do {
                    try await authService.updateCredits(amount: package.totalCredits)
                } catch {
                    print("Failed to grant credits: \(error)")
                }
            }
        }

        // Handle subscriptions
        if subscriptionIDs.contains(transaction.productID) {
            if let plan = subscriptionPlans.first(where: { $0.productIdentifier == transaction.productID }) {
                do {
                    // Calculate subscription end date
                    let endDate: Date
                    if plan.type == .monthly {
                        endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
                    } else {
                        endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
                    }

                    // Update subscription
                    try await authService.updateSubscription(type: plan.type, endDate: endDate)

                    // Grant monthly credits
                    try await authService.updateCredits(amount: plan.monthlyCredits)
                } catch {
                    print("Failed to activate subscription: \(error)")
                }
            }
        }
    }

    // MARK: - Verify Transaction

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Observe Transactions

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                do {
                    let transaction = try self.checkVerified(result)
                    await self.handleSuccessfulPurchase(transaction: transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Check Subscription Status

    func checkSubscriptionStatus() async {
        guard let userId = authService.user?.id else { return }

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if subscriptionIDs.contains(transaction.productID) {
                // Subscription is active
                if let plan = subscriptionPlans.first(where: { $0.productIdentifier == transaction.productID }) {
                    // Check if we need to renew monthly credits
                    await renewMonthlyCreditsIfNeeded(plan: plan)
                }
                return
            }
        }

        // No active subscription
        do {
            try await authService.updateSubscription(type: .free, endDate: nil)
        } catch {
            print("Failed to update subscription status: \(error)")
        }
    }

    private func renewMonthlyCreditsIfNeeded(plan: SubscriptionPlan) async {
        guard let user = authService.user,
              let endDate = user.subscriptionEndDate else { return }

        // If subscription has passed the end date, renew credits
        if Date() > endDate {
            do {
                let newEndDate: Date
                if plan.type == .monthly {
                    newEndDate = Calendar.current.date(byAdding: .month, value: 1, to: endDate)!
                } else {
                    newEndDate = Calendar.current.date(byAdding: .month, value: 1, to: endDate)!
                }

                try await authService.updateSubscription(type: plan.type, endDate: newEndDate)
                try await authService.updateCredits(amount: plan.monthlyCredits)
            } catch {
                print("Failed to renew monthly credits: \(error)")
            }
        }
    }
}

// MARK: - Purchase Errors

enum PurchaseError: LocalizedError {
    case cancelled
    case pending
    case failedVerification
    case unknown

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending"
        case .failedVerification:
            return "Purchase verification failed"
        case .unknown:
            return "Unknown purchase error"
        }
    }
}
