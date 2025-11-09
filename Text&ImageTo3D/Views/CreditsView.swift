//
//  CreditsView.swift
//  MeshyApp
//
//  Credits and subscription management view
//

import SwiftUI
import StoreKit

struct CreditsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var purchaseManager: PurchaseManager

    @State private var selectedTab = 0
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                NeonTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Current balance
                    VStack(spacing: 15) {
                        Text("Your Balance")
                            .font(.headline)
                            .foregroundColor(NeonTheme.secondaryText)

                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.title)
                                .foregroundColor(NeonTheme.neonCyan)

                            Text("\(authService.user?.credits ?? 0)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(NeonTheme.glowGradient)
                        }
                        .neonGlow(color: NeonTheme.neonCyan, radius: 15)

                        Text("credits")
                            .font(.subheadline)
                            .foregroundColor(NeonTheme.secondaryText)

                        // Subscription status
                        if authService.user?.subscriptionType != .free {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(NeonTheme.neonPurple)

                                Text(authService.user?.subscriptionType.displayName ?? "")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                if let endDate = authService.user?.subscriptionEndDate {
                                    Text("• Renews \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(NeonTheme.secondaryText)
                                }
                            }
                            .padding()
                            .background(NeonTheme.cardBackground)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.vertical, 30)

                    // Tab selector
                    Picker("Options", selection: $selectedTab) {
                        Text("Subscriptions").tag(0)
                        Text("Buy Credits").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom)

                    // Content
                    ScrollView {
                        if selectedTab == 0 {
                            SubscriptionPlansView(purchaseManager: purchaseManager, isPurchasing: $isPurchasing)
                        } else {
                            CreditPackagesView(purchaseManager: purchaseManager, isPurchasing: $isPurchasing)
                        }
                    }
                }
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: restorePurchases) {
                        Text("Restore")
                            .foregroundColor(NeonTheme.neonPurple)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await purchaseManager.restorePurchases()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct SubscriptionPlansView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @Binding var isPurchasing: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(purchaseManager.subscriptionPlans) { plan in
                SubscriptionPlanCard(
                    plan: plan,
                    isPurchasing: isPurchasing
                ) {
                    purchase(plan: plan)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }

    private func purchase(plan: SubscriptionPlan) {
        guard let product = purchaseManager.availableProducts.first(where: { $0.id == plan.productIdentifier }) else {
            return
        }

        isPurchasing = true

        Task {
            do {
                try await purchaseManager.purchase(product)
                isPurchasing = false
            } catch {
                isPurchasing = false
                print("Purchase failed: \(error)")
            }
        }
    }
}

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(plan.type.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("\(plan.monthlyCredits) credits/month")
                        .font(.subheadline)
                        .foregroundColor(NeonTheme.neonCyan)
                }

                Spacer()

                if plan.isPopular {
                    Text("POPULAR")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NeonTheme.neonPink)
                        .cornerRadius(12)
                }
            }

            // Price
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("$\(String(format: "%.2f", plan.price))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(NeonTheme.primaryGradient)

                Text(plan.type == .monthly ? "/ month" : "/ year")
                    .foregroundColor(NeonTheme.secondaryText)
            }

            if plan.type == .yearly {
                Text("Only $\(String(format: "%.2f", plan.pricePerMonth))/month")
                    .font(.subheadline)
                    .foregroundColor(NeonTheme.neonCyan)
            }

            Divider()
                .background(NeonTheme.neonPurple.opacity(0.3))

            // Features
            VStack(alignment: .leading, spacing: 10) {
                ForEach(plan.features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(NeonTheme.neonCyan)

                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }

            // Subscribe button
            Button(action: action) {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Subscribe")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(NeonButtonStyle(
                gradient: plan.isPopular ? NeonTheme.accentGradient : NeonTheme.primaryGradient,
                glowColor: plan.isPopular ? NeonTheme.neonPink : NeonTheme.neonPurple
            ))
            .disabled(isPurchasing)
        }
        .padding(20)
        .neonCard()
        .overlay(
            plan.isPopular ?
            RoundedRectangle(cornerRadius: 20)
                .stroke(NeonTheme.neonPink, lineWidth: 2)
            : nil
        )
    }
}

struct CreditPackagesView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @Binding var isPurchasing: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Buy Credits")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ForEach(purchaseManager.creditPackages) { package in
                CreditPackageCard(
                    package: package,
                    isPurchasing: isPurchasing
                ) {
                    purchase(package: package)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }

    private func purchase(package: CreditPackage) {
        guard let product = purchaseManager.availableProducts.first(where: { $0.id == package.productIdentifier }) else {
            return
        }

        isPurchasing = true

        Task {
            do {
                try await purchaseManager.purchase(product)
                isPurchasing = false
            } catch {
                isPurchasing = false
                print("Purchase failed: \(error)")
            }
        }
    }
}

struct CreditPackageCard: View {
    let package: CreditPackage
    let isPurchasing: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Credits info
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(package.totalCredits)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(NeonTheme.glowGradient)

                    Text("credits")
                        .font(.subheadline)
                        .foregroundColor(NeonTheme.secondaryText)
                }

                if package.bonus > 0 {
                    Text("+\(package.bonus) bonus credits")
                        .font(.caption)
                        .foregroundColor(NeonTheme.neonCyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(NeonTheme.neonCyan.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            Spacer()

            // Price and button
            VStack(alignment: .trailing, spacing: 10) {
                Text("$\(String(format: "%.2f", package.price))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("$\(String(format: "%.3f", package.pricePerCredit))/credit")
                    .font(.caption)
                    .foregroundColor(NeonTheme.secondaryText)

                Button(action: action) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Buy")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(NeonButtonStyle())
                .disabled(isPurchasing)
            }
        }
        .padding(20)
        .neonCard()
        .overlay(
            package.isPopular ?
            RoundedRectangle(cornerRadius: 20)
                .stroke(NeonTheme.neonPurple, lineWidth: 2)
            : nil
        )
    }
}
