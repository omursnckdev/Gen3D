//
//  GenerationViewModel.swift
//  MeshyApp
//
//  Handles Text-to-3D and Image-to-3D generation via Meshy API + Firebase
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

class GenerationViewModel: ObservableObject {
    @Published var generations: [Generation] = []
    @Published var currentGeneration: Generation?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let meshyAPI = MeshyAPIService.shared
    private let firestoreService = FirestoreService.shared
    private let authService = AuthenticationService.shared

    private var generationListeners: [String: ListenerRegistration] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        // Listen to progress notifications from MeshyAPIService
        NotificationCenter.default.publisher(for: Notification.Name("MeshyProgressUpdate"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self,
                      let progress = notification.userInfo?["progress"] as? Int else { return }

                if var current = self.currentGeneration {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        current.progress = progress
                        self.currentGeneration = current
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - TEXT → 3D
    func generateTextTo3D(
        prompt: String,
        artStyle: ArtStyle,
        aiModel: AIModel,
        targetPolycount: Int,
        enablePBR: Bool,
        texturePrompt: String? = nil
    ) async {
        print("🟢 Starting text-to-3D generation...")

        guard let userId = Auth.auth().currentUser?.uid else {
            await showErrorMessage("You must be logged in to generate models.")
            return
        }

        let estimatedCost = aiModel.creditCost + (enablePBR ? 10 : 0)
        guard let userCredits = authService.user?.credits, userCredits >= estimatedCost else {
            await showErrorMessage("Insufficient credits. You need \(estimatedCost) credits.")
            return
        }

        await setGenerating(true)

        do {
            // Create Firestore record
            let generation = Generation(
                userId: userId,
                type: .textTo3D,
                status: .pending,
                progress: 0,
                prompt: prompt,
                artStyle: artStyle,
                aiModel: aiModel,
                enablePBR: enablePBR,
                targetPolycount: targetPolycount,
                createdAt: Date()
            )

            let generationId = try await firestoreService.createGeneration(generation)
            startListeningToGeneration(generationId: generationId)

            // Step 1: Create preview
            let previewTaskId = try await meshyAPI.createTextTo3DPreview(
                prompt: prompt,
                artStyle: artStyle,
                aiModel: aiModel,
                targetPolycount: targetPolycount
            )

            try await firestoreService.updateGenerationStatus(
                generationId: generationId,
                status: .inProgress,
                progress: 10
            )

            try await generationsCollection.document(generationId).updateData([
                "previewTaskId": previewTaskId
            ])

            // Poll preview
            let previewTask = try await meshyAPI.pollTaskStatus(
                taskId: previewTaskId,
                type: .textTo3D
            )

            // Step 2: Refine (add textures)
            let refineTaskId = try await meshyAPI.createTextTo3DRefine(
                previewTaskId: previewTaskId,
                enablePBR: enablePBR,
                texturePrompt: texturePrompt,
                aiModel: aiModel
            )

            try await generationsCollection.document(generationId).updateData([
                "refineTaskId": refineTaskId
            ])

            // Poll refine
            let refineTask = try await meshyAPI.pollTaskStatus(
                taskId: refineTaskId,
                type: .textTo3D
            )

            // Create model document
            let model = createModel3D(from: refineTask, generationId: generationId, userId: userId)
            _ = try await firestoreService.createModel(model)

            // Final updates
            try await firestoreService.updateGenerationStatus(
                generationId: generationId,
                status: .succeeded,
                progress: 100
            )

            try await generationsCollection.document(generationId).updateData([
                "thumbnailURL": refineTask.thumbnail_url as Any,
                "videoURL": refineTask.video_url as Any,
                "completedAt": FieldValue.serverTimestamp()
            ])

            // Deduct credits and refresh user data
            try await firestoreService.updateUserCredits(userId: userId, amount: -estimatedCost)
            await authService.loadCurrentUser()
            await setGenerating(false)

            print("✅ Text-to-3D generation complete.")

        } catch {
            await showErrorMessage("Generation failed: \(error.localizedDescription)")
            await setGenerating(false)
        }
    }

    // MARK: - IMAGE → 3D
    func generateImageTo3D(
        imageURL: String,
        aiModel: AIModel,
        targetPolycount: Int,
        enablePBR: Bool,
        shouldTexture: Bool,
        texturePrompt: String? = nil
    ) async {
        print("🟢 Starting image-to-3D generation...")

        guard let userId = Auth.auth().currentUser?.uid else {
            await showErrorMessage("You must be logged in to generate models.")
            return
        }

        let estimatedCost = aiModel.creditCost + (shouldTexture ? 10 : 0)
        guard let userCredits = authService.user?.credits, userCredits >= estimatedCost else {
            await showErrorMessage("Insufficient credits. You need \(estimatedCost) credits.")
            return
        }

        await setGenerating(true)

        do {
            // Create Firestore record
            let generation = Generation(
                userId: userId,
                type: .imageTo3D,
                status: .pending,
                progress: 0,
                imageURL: imageURL,
                aiModel: aiModel,
                enablePBR: enablePBR,
                targetPolycount: targetPolycount,
                createdAt: Date()
            )

            let generationId = try await firestoreService.createGeneration(generation)
            startListeningToGeneration(generationId: generationId)

            // Create task
            let taskId = try await meshyAPI.createImageTo3D(
                imageURL: imageURL,
                aiModel: aiModel,
                enablePBR: enablePBR,
                shouldTexture: shouldTexture,
                targetPolycount: targetPolycount,
                texturePrompt: texturePrompt
            )

            try await firestoreService.updateGenerationStatus(
                generationId: generationId,
                status: .inProgress,
                progress: 10
            )

            try await generationsCollection.document(generationId).updateData([
                "taskId": taskId
            ])

            // Poll task progress (smooth UI handled automatically)
            let task = try await meshyAPI.pollTaskStatus(taskId: taskId, type: .imageTo3D)

            // Create model record
            let model = createModel3D(from: task, generationId: generationId, userId: userId)
            _ = try await firestoreService.createModel(model)

            // Final Firestore updates
            try await firestoreService.updateGenerationStatus(
                generationId: generationId,
                status: .succeeded,
                progress: 100
            )

            try await generationsCollection.document(generationId).updateData([
                "thumbnailURL": task.thumbnail_url as Any,
                "videoURL": task.video_url as Any,
                "completedAt": FieldValue.serverTimestamp()
            ])

            try await firestoreService.updateUserCredits(userId: userId, amount: -estimatedCost)
            await setGenerating(false)

            print("✅ Image-to-3D generation complete.")

        } catch {
            await showErrorMessage("Generation failed: \(error.localizedDescription)")
            await setGenerating(false)
        }
    }

    // MARK: - Load Generations
    func loadUserGenerations() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let gens = try await firestoreService.getUserGenerations(userId: userId)
            await MainActor.run { self.generations = gens }
        } catch {
            await showErrorMessage("Failed to load generations: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers
    private var generationsCollection: CollectionReference {
        Firestore.firestore().collection("generations")
    }

    private func createModel3D(from task: TaskDetails, generationId: String, userId: String) -> Model3D {
        Model3D(
            id: nil,
            generationId: generationId,
            userId: userId,
            glbURL: task.model_urls?.glb,
            fbxURL: task.model_urls?.fbx,
            objURL: task.model_urls?.obj,
            usdzURL: task.model_urls?.usdz,
            mtlURL: task.model_urls?.mtl,
            baseColorURL: task.texture_urls?.first?.base_color,
            metallicURL: task.texture_urls?.first?.metallic,
            normalURL: task.texture_urls?.first?.normal,
            roughnessURL: task.texture_urls?.first?.roughness,
            thumbnailURL: task.thumbnail_url,
            videoURL: task.video_url,
            hasPBR: task.texture_urls?.first?.metallic != nil,
            createdAt: Date(),
            expiresAt: task.expires_at != nil ? Date(timeIntervalSince1970: TimeInterval(task.expires_at! / 1000)) : nil,
            isDownloaded: false,
            isFavorite: false,
            isPublic: false,
            tags: []
        )
    }

    private func startListeningToGeneration(generationId: String) {
        let listener = firestoreService.listenToGeneration(generationId: generationId) { [weak self] result in
            switch result {
            case .success(let generation):
                Task { @MainActor in
                    guard let self = self else { return }
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.currentGeneration = generation
                    }
                }
            case .failure(let error):
                print("Error listening to generation: \(error)")
            }
        }
        generationListeners[generationId] = listener
    }

    @MainActor private func setGenerating(_ value: Bool) {
        isGenerating = value
    }

    @MainActor private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    func cancelGeneration(generationId: String) async {
        try? await firestoreService.updateGenerationStatus(
            generationId: generationId,
            status: .canceled
        )
    }

    deinit {
        generationListeners.values.forEach { $0.remove() }
    }
}
