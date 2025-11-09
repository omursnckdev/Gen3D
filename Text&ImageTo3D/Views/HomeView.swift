//
//  HomeView.swift
//  MeshyApp
//
//  Home view with creation options
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var statsViewModel = StatsViewModel()
    @State private var showTextTo3D = false
    @State private var showImageTo3D = false
    @State private var showBatchGeneration = false

    var body: some View {
        NavigationView {
            ZStack {
                NeonTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Welcome header
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Welcome back,")
                                .font(.title3)
                                .foregroundColor(NeonTheme.secondaryText)

                            Text(authService.user?.displayName ?? "Creator")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(NeonTheme.primaryGradient)

                            // Credits display
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(NeonTheme.neonCyan)
                                Text("\(authService.user?.credits ?? 0) credits")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(NeonTheme.cardBackground)
                            .cornerRadius(20)
                            .neonGlow(color: NeonTheme.neonCyan, radius: 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                        // Creation options
                        VStack(spacing: 20) {
                            Text("What would you like to create?")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            // Text to 3D card
                            CreationOptionCard(
                                title: "Text to 3D",
                                description: "Generate 3D models from text descriptions",
                                icon: "text.bubble.fill",
                                gradient: NeonTheme.primaryGradient,
                                glowColor: NeonTheme.neonPurple
                            ) {
                                showTextTo3D = true
                            }
                            .padding(.horizontal)

                            // Image to 3D card
                            CreationOptionCard(
                                title: "Image to 3D",
                                description: "Convert images into 3D models",
                                icon: "photo.fill",
                                gradient: NeonTheme.accentGradient,
                                glowColor: NeonTheme.neonPink
                            ) {
                                showImageTo3D = true
                            }
                            .padding(.horizontal)

                            // Batch generation card (Yearly Pro only)
                            CreationOptionCard(
                                title: "Batch Generation",
                                description: "Yearly Pro exclusive feature",
                                icon: "square.stack.3d.up.fill",
                                gradient: NeonTheme.glowGradient,
                                glowColor: NeonTheme.neonCyan,
                                isPremium: true
                            ) {
                                showBatchGeneration = true
                            }
                            .padding(.horizontal)
                        }

                        // Quick stats
                        VStack(spacing: 15) {
                            Text("Your Stats")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 15) {
                                StatCard(
                                    icon: "cube.fill",
                                    value: "\(statsViewModel.totalModels)",
                                    label: "Models Created"
                                )

                                StatCard(
                                    icon: "heart.fill",
                                    value: "\(statsViewModel.favoriteModels)",
                                    label: "Favorites"
                                )

                                StatCard(
                                    icon: "arrow.down.circle.fill",
                                    value: "\(statsViewModel.downloadedModels)",
                                    label: "Downloads"
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await statsViewModel.loadStats()
            }
            .refreshable {
                await statsViewModel.loadStats()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshGallery"))) { _ in
                Task {
                    await statsViewModel.loadStats()
                }
            }
            .sheet(isPresented: $showTextTo3D) {
                TextTo3DView()
            }
            .sheet(isPresented: $showImageTo3D) {
                ImageTo3DView()
            }
            .sheet(isPresented: $showBatchGeneration) {
                BatchGenerationView()
            }
        }
    }
}

struct CreationOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let gradient: LinearGradient
    let glowColor: Color
    var isPremium: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundStyle(gradient)
                        .frame(width: 70, height: 70)
                        .background(NeonTheme.darkCard)
                        .cornerRadius(15)

                    if isPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(NeonTheme.neonPurple)
                            .padding(4)
                            .background(Circle().fill(NeonTheme.cardBackground))
                            .offset(x: 8, y: -8)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        if isPremium {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(NeonTheme.neonPurple)
                        }
                    }

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(NeonTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(NeonTheme.neonPurple)
            }
            .padding(20)
            .neonCard()
            .neonGlow(color: glowColor, radius: 15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(NeonTheme.neonBlue)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(label)
                .font(.caption)
                .foregroundColor(NeonTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .neonCard()
    }
}
