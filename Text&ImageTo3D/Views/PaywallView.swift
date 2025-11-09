//
//  PaywallView.swift
//  MeshyApp
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject var rc: RevenueCatManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Unlock Meshy Premium")
                    .font(.largeTitle.bold())
                    .padding(.top)

                Text("Generate unlimited 3D models, use advanced AI models, and export in every format.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if rc.isLoading {
                    ProgressView("Loading plans...")
                        .padding()
                } else if let packages = rc.offerings?.current?.availablePackages, !packages.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(packages, id: \.identifier) { pkg in
                            Button {
                                rc.purchase(pkg)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(title(for: pkg))
                                            .font(.headline)
                                        Text(pkg.storeProduct.localizedPriceString)
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text("No available plans right now.")
                        .foregroundColor(.secondary)
                }

                if let error = rc.purchaseError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Button("Restore Purchases") {
                    rc.restorePurchases()
                }
                .padding(.top, 8)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    private func title(for pkg: Package) -> String {
        switch pkg.packageType {
        case .monthly: return "Monthly Plan"
        case .annual: return "Yearly Plan"
        default: return pkg.storeProduct.localizedTitle
        }
    }
}
