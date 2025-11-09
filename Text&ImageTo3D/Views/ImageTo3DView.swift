//
//  ImageTo3DView.swift
//  MeshyApp
//
//  Image to 3D generation view
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseAuth

struct ImageTo3DView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel = GenerationViewModel()

    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var uploadedImageURL: String?
    @State private var texturePrompt = ""
    @State private var selectedAIModel: AIModel = .latest
    @State private var targetPolycount: Double = 30000
    @State private var enablePBR = true
    @State private var shouldTexture = true
    @State private var showAdvancedOptions = false
    @State private var isGenerating = false
    @State private var isUploading = false
    @State private var showSuccess = false

    var estimatedCredits: Int {
        selectedAIModel.creditCost + (shouldTexture ? 10 : 0)
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
                            Image(systemName: "photo.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(NeonTheme.accentGradient)
                                .neonGlow(color: NeonTheme.neonPink)

                            Text("Image to 3D")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text("Upload an image to convert to 3D")
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
                                .foregroundColor(NeonTheme.neonPink)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .neonCard()
                        .padding(.horizontal)

                        // Image picker
                        VStack(spacing: 15) {
                            if let imageData = selectedImageData,
                               let uiImage = UIImage(data: imageData) {
                                // Display selected image
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .cornerRadius(20)
                                    .neonGlow(color: NeonTheme.neonPink, radius: 15)

                                PhotosPicker(selection: $selectedImage, matching: .images) {
                                    Label("Change Image", systemImage: "photo.fill")
                                        .foregroundColor(NeonTheme.neonPurple)
                                }
                            } else {
                                // Image picker button
                                PhotosPicker(selection: $selectedImage, matching: .images) {
                                    VStack(spacing: 15) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 50))
                                            .foregroundStyle(NeonTheme.accentGradient)

                                        Text("Select Image")
                                            .font(.headline)
                                            .foregroundColor(.white)

                                        Text("JPG, PNG supported")
                                            .font(.caption)
                                            .foregroundColor(NeonTheme.secondaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .neonCard()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .onChange(of: selectedImage) { newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }

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
                                    // Texture toggle
                                    Toggle(isOn: $shouldTexture) {
                                        VStack(alignment: .leading) {
                                            Text("Generate Textures")
                                                .foregroundColor(.white)
                                            Text("+10 credits")
                                                .font(.caption)
                                                .foregroundColor(NeonTheme.secondaryText)
                                        }
                                    }
                                    .tint(NeonTheme.neonPurple)

                                    // PBR toggle
                                    Toggle(isOn: $enablePBR) {
                                        Text("Enable PBR Maps")
                                            .foregroundColor(.white)
                                    }
                                    .tint(NeonTheme.neonPurple)
                                    .disabled(!shouldTexture)

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
                            if isUploading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Uploading...")
                                }
                                .frame(maxWidth: .infinity)
                            } else if isGenerating {
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
                        .buttonStyle(NeonButtonStyle(gradient: NeonTheme.accentGradient, glowColor: NeonTheme.neonPink))
                        .disabled(selectedImageData == nil || isGenerating || isUploading || (authService.user?.credits ?? 0) < estimatedCredits)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
                
                // Show progress overlay during generation
                if isGenerating, let currentGen = viewModel.currentGeneration {
                    GenerationProgressView(generation: currentGen)
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
            .alert("Success!", isPresented: $showSuccess) {
                Button("View Models") {
                    dismiss()
                }
                Button("Generate Another") {
                    selectedImage = nil
                    selectedImageData = nil
                    texturePrompt = ""
                    showSuccess = false
                }
            } message: {
                Text("Your 3D model has been generated successfully!")
            }
        }
    }

    private func generate() {
        print("🟢 GENERATE BUTTON TAPPED!")
        
        guard let imageData = selectedImageData else {
            print("❌ No image data selected")
            return
        }

        isUploading = true

        Task {
            do {
                print("🔵 Uploading image to Firebase Storage...")
                
                // Use Firebase Auth UID directly
                guard let userId = Auth.auth().currentUser?.uid else {
                    print("❌ User not authenticated")
                    isUploading = false
                    return
                }
                
                // Upload image to Firebase Storage
                let storage = Storage.storage()
                let imageRef = storage.reference().child("uploads/\(userId)/\(UUID().uuidString).jpg")

                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"

                _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
                print("✅ Image uploaded")

                // Get download URL
                let downloadURL = try await imageRef.downloadURL()
                print("✅ Download URL obtained: \(downloadURL.absoluteString)")

                isUploading = false
                isGenerating = true

                print("🔵 Starting generateImageTo3D...")
                // Generate 3D model
                await viewModel.generateImageTo3D(
                    imageURL: downloadURL.absoluteString,
                    aiModel: selectedAIModel,
                    targetPolycount: Int(targetPolycount),
                    enablePBR: enablePBR,
                    shouldTexture: shouldTexture,
                    texturePrompt: texturePrompt.isEmpty ? nil : texturePrompt
                )

                isGenerating = false
                
                // Show success if no errors
                if viewModel.errorMessage == nil {
                    print("✅ Generation completed successfully!")
                    showSuccess = true
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshGallery"), object: nil)
                    // Load updated generations
                    await viewModel.loadUserGenerations()
                } else {
                    print("❌ Generation failed")
                }

            } catch {
                isUploading = false
                isGenerating = false
                print("❌ Upload/Generation failed: \(error)")
                viewModel.errorMessage = "Upload failed: \(error.localizedDescription)"
                viewModel.showError = true
            }
        }
    }
}

// Add GenerationProgressView if you don't have it already
struct GenerationProgressView: View {
    let generation: Generation
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: Double(generation.progress), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: NeonTheme.neonPurple))
                    .frame(width: 200)
                
                Text("\(generation.progress)%")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(generation.status.displayName)
                    .font(.subheadline)
                    .foregroundColor(NeonTheme.secondaryText)
                
                if let prompt = generation.prompt {
                    Text(prompt)
                        .font(.caption)
                        .foregroundColor(NeonTheme.tertiaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                }
            }
            .padding(40)
            .background(NeonTheme.cardBackground)
            .cornerRadius(20)
            .neonGlow(color: NeonTheme.neonPurple, radius: 15)
        }
    }
}
