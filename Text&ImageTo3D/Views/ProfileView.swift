//
//  ProfileView.swift
//  MeshyApp
//
//  User profile view
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                NeonTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Profile header
                        VStack(spacing: 15) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(NeonTheme.primaryGradient)
                                    .frame(width: 100, height: 100)
                                    .neonGlow(color: NeonTheme.neonPurple, radius: 20)

                                if let photoURL = authService.user?.photoURL, let url = URL(string: photoURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Text(authService.user?.displayName.prefix(1).uppercased() ?? "U")
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                } else {
                                    Text(authService.user?.displayName.prefix(1).uppercased() ?? "U")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }

                            Text(authService.user?.displayName ?? "User")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(authService.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(NeonTheme.secondaryText)

                            // Subscription badge
                            if let subscription = authService.user?.subscriptionType, subscription != .free {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(NeonTheme.neonPurple)

                                    Text(subscription.displayName)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(NeonTheme.cardBackground)
                                .cornerRadius(20)
                                .neonGlow(color: NeonTheme.neonPurple, radius: 10)
                            }
                        }
                        .padding(.top, 20)

                        // Stats
                        HStack(spacing: 20) {
                            ProfileStatCard(
                                icon: "star.fill",
                                value: "\(authService.user?.credits ?? 0)",
                                label: "Credits",
                                color: NeonTheme.neonCyan
                            )

                            ProfileStatCard(
                                icon: "cube.fill",
                                value: "0",
                                label: "Models",
                                color: NeonTheme.neonPurple
                            )

                            ProfileStatCard(
                                icon: "calendar",
                                value: daysActive,
                                label: "Days Active",
                                color: NeonTheme.neonBlue
                            )
                        }
                        .padding(.horizontal)

                        // Settings sections
                        VStack(spacing: 20) {
                            // Account section
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Account")
                                    .font(.headline)
                                    .foregroundColor(NeonTheme.secondaryText)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)

                                VStack(spacing: 0) {
                                    SettingsRow(
                                        icon: "person.fill",
                                        title: "Edit Profile",
                                        color: NeonTheme.neonPurple
                                    ) {
                                        // Edit profile action
                                    }

                                    Divider()
                                        .background(NeonTheme.neonPurple.opacity(0.2))

                                    SettingsRow(
                                        icon: "lock.fill",
                                        title: "Change Password",
                                        color: NeonTheme.neonBlue
                                    ) {
                                        // Change password action
                                    }

                                    Divider()
                                        .background(NeonTheme.neonPurple.opacity(0.2))

                                    SettingsRow(
                                        icon: "bell.fill",
                                        title: "Notifications",
                                        color: NeonTheme.neonCyan
                                    ) {
                                        // Notifications settings
                                    }
                                }
                                .neonCard()
                            }
                            .padding(.horizontal)

                            // App section
                            VStack(alignment: .leading, spacing: 0) {
                                Text("App")
                                    .font(.headline)
                                    .foregroundColor(NeonTheme.secondaryText)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)

                                VStack(spacing: 0) {
                                    SettingsRow(
                                        icon: "questionmark.circle.fill",
                                        title: "Help & Support",
                                        color: NeonTheme.neonPurple
                                    ) {
                                        // Help action
                                    }

                                    Divider()
                                        .background(NeonTheme.neonPurple.opacity(0.2))

                                    SettingsRow(
                                        icon: "doc.text.fill",
                                        title: "Terms of Service",
                                        color: NeonTheme.neonBlue
                                    ) {
                                        // Terms action
                                    }

                                    Divider()
                                        .background(NeonTheme.neonPurple.opacity(0.2))

                                    SettingsRow(
                                        icon: "hand.raised.fill",
                                        title: "Privacy Policy",
                                        color: NeonTheme.neonCyan
                                    ) {
                                        // Privacy action
                                    }
                                }
                                .neonCard()
                            }
                            .padding(.horizontal)

                            // Danger zone
                            VStack(spacing: 15) {
                                Button(action: { showLogoutAlert = true }) {
                                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(NeonButtonStyle(
                                    gradient: LinearGradient(colors: [NeonTheme.cardBackground], startPoint: .leading, endPoint: .trailing),
                                    glowColor: NeonTheme.neonBlue
                                ))

                                Button(action: { showDeleteAccountAlert = true }) {
                                    Label("Delete Account", systemImage: "trash.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // App version
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(NeonTheme.tertiaryText)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.")
            }
        }
    }

    private var daysActive: String {
        guard let createdAt = authService.user?.createdAt else { return "0" }
        let days = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        return "\(days)"
    }

    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("Sign out failed: \(error)")
        }
    }

    private func deleteAccount() {
        Task {
            do {
                try await authService.deleteAccount()
            } catch {
                print("Delete account failed: \(error)")
            }
        }
    }
}

struct ProfileStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(label)
                .font(.caption)
                .foregroundColor(NeonTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .neonCard()
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)

                Text(title)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(NeonTheme.secondaryText)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}
