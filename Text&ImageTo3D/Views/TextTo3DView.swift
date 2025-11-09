//
//  TextTo3DView.swift
//  MeshyApp
//
//  Text to 3D generation view
//

import SwiftUI

struct TextTo3DView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel = GenerationViewModel()

    @State private var prompt = ""
    @State private var texturePrompt = ""
    @State private var selectedArtStyle: ArtStyle = .realistic
    @State private var selectedAIModel: AIModel = .latest
    @State private var targetPolycount: Double = 30000
    @State private var enablePBR = true
    @State private var showAdvancedOptions = false
    @State private var isGenerating = false

    var estimatedCredits: Int {
        selectedAIModel.creditCost + (enablePBR ? 10 : 0)
    }

    var body: some View {
        NavigationView {
            ZStack {
                NeonTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "text.bubble.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(NeonTheme.primaryGradient)
                                .neonGlow(color: NeonTheme.neonPurple)

                            Text("Text to 3D")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text("Describe what you want to create")
                                .font(.subheadline)
                                .foregroundColor(NeonTheme.secondaryText)
                        }
                        .padding(.top)

                        // Credits display
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(NeonTheme.neonCyan)
                            Text("Available: \(authService.user?.credits ?? 0) credits")
                                .foregroundColor(.white)

                            Spacer()

                            Text("Cost: \(estimatedCredits)")
                                .foregroundColor(NeonTheme.neonPurple)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .neonCard()
                        .padding(.horizontal)

                        // Prompt input
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)

                            ZStack(alignment: .topLeading) {
                                if prompt.isEmpty {
                                    Text("E.g., A futuristic spaceship with blue neon lights")
                                        .foregroundColor(NeonTheme.tertiaryText)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                }

                                TextEditor(text: $prompt)
                                    .frame(height: 120)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .foregroundColor(.white)
                            }
                            .background(NeonTheme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(NeonTheme.neonPurple.opacity(0.5), lineWidth: 1)
                            )

                            Text("\(prompt.count)/600 characters")
                                .font(.caption)
                                .foregroundColor(NeonTheme.tertiaryText)
                        }
                        .padding(.horizontal)

                        // Art style selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Art Style")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack(spacing: 15) {
                                ForEach(ArtStyle.allCases, id: \.self) { style in
                                    StyleButton(
                                        title: style.displayName,
                                        isSelected: selectedArtStyle == style
                                    ) {
                                        selectedArtStyle = style
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // AI Model selection
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AI Model")
                                .font(.headline)
                                .foregroundColor(.white)

                            VStack(spacing: 10) {
                                ForEach(AIModel.allCases, id: \.self) { model in
                                    ModelSelectionRow(
                                        model: model,
                                        isSelected: selectedAIModel == model
                                    ) {
                                        selectedAIModel = model
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Advanced options
                        VStack(alignment: .leading, spacing: 10) {
                            Button(action: { showAdvancedOptions.toggle() }) {
                                HStack {
                                    Text("Advanced Options")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Spacer()

                                    Image(systemName: showAdvancedOptions ? "chevron.up" : "chevron.down")
                                        .foregroundColor(NeonTheme.neonPurple)
                                }
                            }

                            if showAdvancedOptions {
                                VStack(alignment: .leading, spacing: 15) {
                                    // PBR toggle
                                    Toggle(isOn: $enablePBR) {
                                        VStack(alignment: .leading) {
                                            Text("Enable PBR Textures")
                                                .foregroundColor(.white)
                                            Text("+10 credits")
                                                .font(.caption)
                                                .foregroundColor(NeonTheme.secondaryText)
                                        }
                                    }
                                    .tint(NeonTheme.neonPurple)

                                    // Polycount slider
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Target Polycount: \(Int(targetPolycount))")
                                            .foregroundColor(.white)

                                        Slider(value: $targetPolycount, in: 100...100000, step: 1000)
                                            .tint(NeonTheme.neonPurple)
                                    }

                                    // Texture prompt
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Texture Prompt (Optional)")
                                            .foregroundColor(.white)

                                        TextField("Additional texture details", text: $texturePrompt)
                                            .textFieldStyle(NeonTextFieldStyle())
                                    }
                                }
                                .padding()
                                .neonCard()
                            }
                        }
                        .padding(.horizontal)

                        // Generate button
                        Button(action: generate) {
                            if isGenerating {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Generating...")
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Text("Generate 3D Model")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(NeonButtonStyle())
                        .disabled(prompt.isEmpty || isGenerating || (authService.user?.credits ?? 0) < estimatedCredits)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(NeonTheme.neonPurple)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                     Button("OK", role: .cancel) { }
                 } message: {
                     Text(viewModel.errorMessage ?? "Unknown error occurred")
                 }
        }
    }

    private func generate() {
        print("🟢 GENERATE BUTTON TAPPED!")
        isGenerating = true

        Task {
            do {
                print("🔵 Starting generateTextTo3D...")
                await viewModel.generateTextTo3D(
                    prompt: prompt,
                    artStyle: selectedArtStyle,
                    aiModel: selectedAIModel,
                    targetPolycount: Int(targetPolycount),
                    enablePBR: enablePBR,
                    texturePrompt: texturePrompt.isEmpty ? nil : texturePrompt
                )
                
                print("✅ Generation completed successfully!")
                isGenerating = false
                dismiss()
                NotificationCenter.default.post(name: NSNotification.Name("RefreshGallery"), object: nil)

            } catch {
                print("❌ Generation failed: \(error.localizedDescription)")
                isGenerating = false
                // TODO: Show error alert to user
            }
        }
    }
}

struct StyleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : NeonTheme.secondaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    isSelected ? NeonTheme.primaryGradient : LinearGradient(colors: [NeonTheme.cardBackground], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : NeonTheme.neonPurple.opacity(0.3), lineWidth: 1)
                )
        }
        .neonGlow(color: isSelected ? NeonTheme.neonPurple : .clear, radius: 8)
    }
}

struct ModelSelectionRow: View {
    let model: AIModel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("\(model.creditCost) credits")
                        .font(.caption)
                        .foregroundColor(NeonTheme.neonCyan)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(NeonTheme.neonPurple)
                }
            }
            .padding()
            .background(isSelected ? NeonTheme.cardBackground : NeonTheme.darkCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? NeonTheme.neonPurple : Color.clear, lineWidth: 2)
            )
        }
    }
}
