//
//  NeonTheme.swift
//  MeshyApp
//
//  Neon-themed color scheme with purple, blue, and black
//

import SwiftUI

struct NeonTheme {
    // Primary Colors
    static let neonPurple = Color(red: 0.58, green: 0.18, blue: 0.89) // #9430E3
    static let neonBlue = Color(red: 0.0, green: 0.71, blue: 1.0) // #00B5FF
    static let neonPink = Color(red: 0.94, green: 0.18, blue: 0.89) // #F02EE3
    static let neonCyan = Color(red: 0.0, green: 0.98, blue: 0.93) // #00FAED

    // Background Colors
    static let background = Color(red: 0.05, green: 0.05, blue: 0.08) // #0D0D14
    static let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.15) // #1A1A26
    static let darkCard = Color(red: 0.08, green: 0.08, blue: 0.12) // #14141F

    // Gradient Colors
    static let primaryGradient = LinearGradient(
        colors: [neonPurple, neonBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [neonPink, neonPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let glowGradient = LinearGradient(
        colors: [neonCyan, neonBlue, neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Text Colors
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let tertiaryText = Color.white.opacity(0.5)

    // Status Colors
    static let success = Color.green
    static let error = Color.red
    static let warning = Color.orange
    static let info = neonBlue
}

// MARK: - Glow Modifier
struct NeonGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

extension View {
    func neonGlow(color: Color = NeonTheme.neonPurple, radius: CGFloat = 10) -> some View {
        self.modifier(NeonGlowModifier(color: color, radius: radius))
    }
}

// MARK: - Gradient Button Style
struct NeonButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let glowColor: Color

    init(gradient: LinearGradient = NeonTheme.primaryGradient, glowColor: Color = NeonTheme.neonPurple) {
        self.gradient = gradient
        self.glowColor = glowColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(gradient)
            .cornerRadius(16)
            .neonGlow(color: glowColor, radius: configuration.isPressed ? 5 : 10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Style
struct NeonCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NeonTheme.cardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [NeonTheme.neonPurple.opacity(0.3), NeonTheme.neonBlue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: NeonTheme.neonPurple.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func neonCard() -> some View {
        self.modifier(NeonCardModifier())
    }
}
