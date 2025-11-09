//
//  AuthenticationService.swift
//  MeshyApp
//
//  Firebase Authentication Service
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import RevenueCat

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()

    @Published var user: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let auth = Auth.auth()
    private let firestoreService = FirestoreService.shared
    private var authStateListener: AuthStateDidChangeListenerHandle?

    private init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }

            if let user = user {
                Task {
                    await self.loadUserData(uid: user.uid)
                }
            } else {
                self.user = nil
                self.isAuthenticated = false
            }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        print("🔵 Auth: Starting sign in for: \(email)")
        isLoading = true
        errorMessage = nil

        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            print("✅ Auth: Sign in successful: \(result.user.uid)")
            await loadUserData(uid: result.user.uid)

            // Update last login
            try await firestoreService.updateLastLogin(userId: result.user.uid)

            isLoading = false
        } catch {
            print("❌ Auth: Sign in failed: \(error)")
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String) async throws {
        print("🔵 Auth: Starting sign up for: \(email)")
        isLoading = true
        errorMessage = nil

        do {
            // Create Firebase Auth user
            let result = try await auth.createUser(withEmail: email, password: password)
            print("✅ Auth: Firebase user created: \(result.user.uid)")

            // Create user profile in Firestore
            // Don't set id - let Firestore handle it
            let newUser = AppUser(
                id: nil,
                email: email,
                displayName: displayName,
                credits: 100 // Welcome bonus
            )

            print("🔵 Auth: Creating Firestore user document...")
            try await firestoreService.createUser(newUser)
            print("✅ Auth: User document created")
            
            await loadUserData(uid: result.user.uid)

            isLoading = false
            print("✅ Auth: Sign up complete")
        } catch {
            print("❌ Auth: Sign up failed: \(error)")
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        print("🔵 Auth: Signing out")
        do {
            try auth.signOut()
            user = nil
            isAuthenticated = false
            print("✅ Auth: Sign out successful")
        } catch {
            print("❌ Auth: Sign out failed: \(error)")
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        print("🔵 Auth: Sending password reset to: \(email)")
        try await auth.sendPasswordReset(withEmail: email)
        print("✅ Auth: Password reset email sent")
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let currentUser = auth.currentUser else {
            throw AuthError.notAuthenticated
        }

        print("🔵 Auth: Deleting account: \(currentUser.uid)")

        // Delete Firestore data
        try await firestoreService.deleteUser(userId: currentUser.uid)

        // Delete Auth account
        try await currentUser.delete()

        user = nil
        isAuthenticated = false
        print("✅ Auth: Account deleted")
    }

    // MARK: - Load User Data

    private func loadUserData(uid: String) async {
        print("🔵 Auth: Loading user data for: \(uid)")
        do {
            if let userData = try await firestoreService.getUser(userId: uid) {
                await MainActor.run {
                    self.user = userData
                    self.isAuthenticated = true
                }
                print("✅ Auth: User data loaded successfully")
            } else {
                print("⚠️ Auth: User data not found")
            }
        } catch {
            print("❌ Auth: Failed to load user data: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load user data: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Load Current User (public method)
    
    func loadCurrentUser() async {
        guard let uid = auth.currentUser?.uid else {
            print("⚠️ Auth: No current user to load")
            return
        }
        await loadUserData(uid: uid)
    }

    // MARK: - Sync RevenueCat Subscription to Firestore
    
    func syncRevenueCatSubscription() async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        print("🔵 Auth: Syncing RevenueCat subscription for user: \(userId)")
        
        // Get customer info from RevenueCat
        let customerInfo = try await Purchases.shared.customerInfo()
        print("🔵 Auth: CustomerInfo retrieved")
        print("🔵 Auth: All entitlements: \(customerInfo.entitlements.all.keys)")
        
        // Check if user has active premium entitlement
        if let entitlement = customerInfo.entitlements["premium"], entitlement.isActive {
            print("✅ Auth: User has active premium subscription")
            print("🔵 Auth: Product ID: \(entitlement.productIdentifier)")
            print("🔵 Auth: Expiration: \(entitlement.expirationDate?.description ?? "none")")
            
            // Determine subscription type based on product identifier
            var subscriptionType: SubscriptionType = .monthly
            var monthlyCredits = 200 // Default to monthly credits
            
            let productId = entitlement.productIdentifier.lowercased()
            print("🔵 Auth: Checking product ID (lowercased): \(productId)")
            
            if productId.contains("year") || productId.contains("annual") {
                subscriptionType = .yearly
                monthlyCredits = 500
                print("✅ Auth: Detected YEARLY subscription - granting \(monthlyCredits) credits")
            } else {
                subscriptionType = .monthly
                monthlyCredits = 200
                print("✅ Auth: Detected MONTHLY subscription - granting \(monthlyCredits) credits")
            }
            
            // Get expiration date
            let expirationDate = entitlement.expirationDate
            
            print("🔵 Auth: Updating Firestore subscription...")
            // Update Firestore with subscription info
            try await firestoreService.updateSubscription(
                userId: userId,
                type: subscriptionType,
                endDate: expirationDate
            )
            print("✅ Auth: Firestore subscription updated")
            
            // Grant monthly credits
            print("🔵 Auth: Current user credits before update: \(user?.credits ?? 0)")
            print("🔵 Auth: Granting \(monthlyCredits) credits to user...")
            
            try await firestoreService.updateUserCredits(userId: userId, amount: monthlyCredits)
            print("✅ Auth: Credits granted successfully")
            
            print("✅ Auth: Subscription synced successfully")
        } else {
            print("⚠️ Auth: No active premium subscription found")
            print("🔵 Auth: Available entitlements: \(customerInfo.entitlements.all.keys.joined(separator: ", "))")
            
            // Update to free if they had a subscription before
            if user?.subscriptionType != .free {
                print("🔵 Auth: Downgrading user to free subscription")
                try await firestoreService.updateSubscription(
                    userId: userId,
                    type: .free,
                    endDate: nil
                )
            }
        }
        
        // Reload user data to reflect changes
        print("🔵 Auth: Reloading user data...")
        await loadUserData(uid: userId)
        print("🔵 Auth: User data reloaded. New credits: \(user?.credits ?? 0)")
    }

    // MARK: - Update User Credits

    func updateCredits(amount: Int) async throws {
        // Use Firebase Auth UID directly
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        try await firestoreService.updateUserCredits(userId: userId, amount: amount)
        await loadUserData(uid: userId)
    }

    // MARK: - Update Subscription

    func updateSubscription(type: SubscriptionType, endDate: Date?) async throws {
        // Use Firebase Auth UID directly
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        try await firestoreService.updateSubscription(
            userId: userId,
            type: type,
            endDate: endDate
        )
        await loadUserData(uid: userId)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        }
    }
}
