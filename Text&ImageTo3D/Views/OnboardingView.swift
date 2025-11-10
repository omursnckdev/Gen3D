//
//  OnboardingView.swift
//  MeshyApp
//
//  Onboarding and tutorial view for first-time users
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var currentPage = 0
    @State private var isCompleting = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "cube.transparent.fill",
            title: "Welcome to Gen3D",
            description: "Transform your ideas into stunning 3D models using AI. Create from text descriptions or upload images.",
            color: NeonTheme.neonPurple
        ),
        OnboardingPage(
            icon: "text.bubble.fill",
            title: "Text to 3D Model",
            description: "Describe what you want to create in text, and our AI will generate a detailed 3D model for you. Try prompts like 'A futuristic spaceship with blue neon lights'.",
            color: NeonTheme.neonCyan
        ),
        OnboardingPage(
            icon: "photo.fill",
            title: "Image to 3D Model",
            description: "Upload any image and watch it transform into a fully textured 3D model. Perfect for bringing real objects into the virtual world.",
            color: NeonTheme.neonPink
        ),
        OnboardingPage(
            icon: "star.fill",
            title: "Credits System",
            description: "You start with 100 free credits! Each generation costs credits. Buy more credits or subscribe for monthly credits and premium features.",
            color: NeonTheme.neonCyan
        ),
        OnboardingPage(
            icon: "square.grid.3x3.fill",
            title: "Your Gallery",
            description: "All your creations are saved in the Gallery. View them in AR, download in multiple formats (GLB, FBX, USDZ), and share with others.",
            color: NeonTheme.neonPurple
        ),
        OnboardingPage(
            icon: "arkit",
            title: "AR Viewing",
            description: "Experience your 3D models in augmented reality! Place them in your real environment and see them come to life.",
            color: NeonTheme.neonPink
        )
    ]

    var body: some View {
        ZStack {
            NeonTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: completeOnboarding) {
                        Text("Skip")
                            .foregroundColor(NeonTheme.secondaryText)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                .padding()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[index].color : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.vertical, 20)

                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    if isCompleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: pages[currentPage].color.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .disabled(isCompleting)
            }
        }
    }

    private func completeOnboarding() {
        guard let userId = authService.user?.id else { return }

        isCompleting = true

        Task {
            do {
                // Update Firestore to mark onboarding as completed
                try await FirestoreService.shared.updateOnboardingStatus(userId: userId, completed: true)

                // Reload user data to reflect the change
                await authService.loadCurrentUser()

                isCompleting = false
            } catch {
                print("Failed to complete onboarding: \(error)")
                isCompleting = false
            }
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color.opacity(0.3), page.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                    .shadow(color: page.color.opacity(0.5), radius: 20, x: 0, y: 10)

                Image(systemName: page.icon)
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 20)

            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(NeonTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthenticationService.shared)
}
