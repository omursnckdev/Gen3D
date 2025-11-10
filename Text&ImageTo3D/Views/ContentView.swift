//
//  ContentView.swift
//  MeshyApp
//
//  Main content view with navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if authService.isAuthenticated {
                if authService.user?.hasCompletedOnboarding == false {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            } else {
                AuthenticationView()
            }
        }
        .task {
            await purchaseManager.loadProducts()
            await purchaseManager.checkSubscriptionStatus()

            // Add a small delay to show loading view and avoid flashing AuthView
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            withAnimation {
                isLoading = false
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Create", systemImage: "cube.fill")
                }
                .tag(0)

            GalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "square.grid.3x3.fill")
                }
                .tag(1)

            CreditsView()
                .tabItem {
                    Label("Credits", systemImage: "creditcard.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(NeonTheme.neonPurple)
    }
}
