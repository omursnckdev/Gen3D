//
//  RevenueCatManager.swift
//  MeshyApp
//

import Foundation
import RevenueCat
import Combine

@MainActor
class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()

    @Published var isPremium: Bool = false
    @Published var offerings: Offerings?
    @Published var isLoading = false
    @Published var purchaseError: String?

    private let entitlementID = "premium"
    private var customerInfoTask: Task<Void, Never>?

    private init() {
        refreshCustomerInfo()
        fetchOfferings()
        observeCustomerInfoStream()
    }

    // MARK: - Fetch Offerings
    func fetchOfferings() {
        isLoading = true
        Task {
            do {
                let result = try await Purchases.shared.offerings()
                await MainActor.run {
                    self.offerings = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.purchaseError = error.localizedDescription
                    print("❌ Offerings fetch failed: \(error)")
                }
            }
        }
    }

    // MARK: - Observe Entitlements (AsyncStream)
    private func observeCustomerInfoStream() {
        customerInfoTask = Task {
            for await info in Purchases.shared.customerInfoStream {
                updateEntitlementStatus(from: info)
            }
        }
    }

    func refreshCustomerInfo() {
        Task {
            do {
                let info = try await Purchases.shared.customerInfo()
                updateEntitlementStatus(from: info)
            } catch {
                print("❌ Failed to refresh customer info: \(error)")
            }
        }
    }

    private func updateEntitlementStatus(from info: CustomerInfo?) {
        let active = info?.entitlements[entitlementID]?.isActive == true
        if active != isPremium {
            isPremium = active
            print("⭐️ Premium active: \(isPremium)")
        }
    }

    // MARK: - Purchase Logic
    func purchase(_ package: Package) {
        isLoading = true
        purchaseError = nil

        Task {
            do {
                let result = try await Purchases.shared.purchase(package: package)
                await MainActor.run {
                    self.isLoading = false
                    if result.userCancelled {
                        print("🟡 Purchase cancelled")
                    } else {
                        self.updateEntitlementStatus(from: result.customerInfo)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.purchaseError = error.localizedDescription
                    print("❌ Purchase error:", error)
                }
            }
        }
    }

    // MARK: - Restore
    func restorePurchases() {
        isLoading = true
        purchaseError = nil

        Task {
            do {
                let info = try await Purchases.shared.restorePurchases()
                await MainActor.run {
                    self.isLoading = false
                    self.updateEntitlementStatus(from: info)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.purchaseError = error.localizedDescription
                    print("❌ Restore failed:", error)
                }
            }
        }
    }
}
