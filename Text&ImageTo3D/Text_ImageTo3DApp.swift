//
//  MeshyAppApp.swift
//  MeshyApp
//
//  Created by Claude on 2025-11-08.
//

import SwiftUI
import Firebase
import RevenueCat
import FirebaseAuth

@main
struct MeshyAppApp: App {
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var purchaseManager = PurchaseManager.shared

    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Configure app appearance
        configureAppearance()
        
        Purchases.configure(withAPIKey: "test_vRSsHrVnVVzudacPjUdMXhSiPxN")
             // Optional: Log in Firebase UID if available
             if let userID = Auth.auth().currentUser?.uid {
                 Purchases.shared.logIn(userID) { _, _, _ in }
             }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(purchaseManager)
                .environmentObject(RevenueCatManager.shared)
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        // Set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(NeonTheme.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        // Set tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(NeonTheme.background)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
