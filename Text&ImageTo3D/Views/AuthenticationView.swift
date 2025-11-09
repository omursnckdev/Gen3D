//
//  AuthenticationView.swift
//  MeshyApp
//
//  Authentication view with login and sign up
//

import SwiftUI

struct AuthenticationView: View {
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            // Background
            NeonTheme.background
                .ignoresSafeArea()

            if showSignUp {
                SignUpView(showSignUp: $showSignUp)
            } else {
                LoginView(showSignUp: $showSignUp)
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Logo and title
            VStack(spacing: 20) {
                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(NeonTheme.primaryGradient)
                    .neonGlow(color: NeonTheme.neonPurple, radius: 20)

                Text("Meshy 3D")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(NeonTheme.primaryGradient)

                Text("Create stunning 3D models from text or images")
                    .font(.subheadline)
                    .foregroundColor(NeonTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Login form
            VStack(spacing: 20) {
                // Email field
                TextField("Email", text: $email)
                    .textFieldStyle(NeonTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                // Password field
                SecureField("Password", text: $password)
                    .textFieldStyle(NeonTextFieldStyle())
                    .textContentType(.password)

                // Login button
                Button(action: login) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(NeonButtonStyle())
                .disabled(authService.isLoading || email.isEmpty || password.isEmpty)

                // Sign up link
                Button(action: { showSignUp = true }) {
                    Text("Don't have an account? ")
                        .foregroundColor(NeonTheme.secondaryText) +
                    Text("Sign Up")
                        .foregroundColor(NeonTheme.neonPurple)
                        .bold()
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func login() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 30) {
            // Header
            HStack {
                Button(action: { showSignUp = false }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(NeonTheme.neonPurple)
                }
                Spacer()
            }
            .padding(.horizontal, 30)

            Spacer()

            // Logo
            VStack(spacing: 20) {
                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(NeonTheme.primaryGradient)
                    .neonGlow(color: NeonTheme.neonPurple, radius: 20)

                Text("Create Account")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(NeonTheme.primaryGradient)

                Text("Get 10 free credits to start creating")
                    .font(.subheadline)
                    .foregroundColor(NeonTheme.secondaryText)
            }

            // Sign up form
            VStack(spacing: 20) {
                TextField("Display Name", text: $displayName)
                    .textFieldStyle(NeonTextFieldStyle())
                    .textContentType(.name)

                TextField("Email", text: $email)
                    .textFieldStyle(NeonTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(NeonTextFieldStyle())
                    .textContentType(.newPassword)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(NeonTextFieldStyle())
                    .textContentType(.newPassword)

                Button(action: signUp) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(NeonButtonStyle())
                .disabled(authService.isLoading || !isFormValid)
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !displayName.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }

    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            return
        }

        Task {
            do {
                try await authService.signUp(email: email, password: password, displayName: displayName)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Neon Text Field Style
struct NeonTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(NeonTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [NeonTheme.neonPurple.opacity(0.5), NeonTheme.neonBlue.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
            .foregroundColor(.white)
    }
}
