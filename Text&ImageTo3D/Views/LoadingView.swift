//
//  LoadingView.swift
//  MeshyApp
//
//  Loading view shown while app initializes
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            NeonTheme.background
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Animated 3D cube icon
                ZStack {
                    ForEach(0..<3) { index in
                        Image(systemName: "cube.transparent.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [NeonTheme.neonPurple, NeonTheme.neonCyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(isAnimating ? 0.3 : 1.0)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .frame(width: 100, height: 100)
                .padding(.bottom, 20)

                // App title
                Text("Gen3D")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NeonTheme.neonPurple, NeonTheme.neonCyan, NeonTheme.neonPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: NeonTheme.neonPurple.opacity(0.5), radius: 10, x: 0, y: 5)

                Text("Creating stunning 3D models...")
                    .font(.subheadline)
                    .foregroundColor(NeonTheme.secondaryText)

                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: NeonTheme.neonCyan))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LoadingView()
}
