//
//  GalleryViewModel.swift
//  MeshyApp
//
//  ViewModel for managing 3D model gallery
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

class GalleryViewModel: ObservableObject {
    @Published var models: [Model3D] = []
    @Published var favoriteModels: [Model3D] = []
    @Published var isLoading = false
    @Published var selectedModel: Model3D?
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private let authService = AuthenticationService.shared

    // MARK: - Load Models
    func loadUserModels() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ GalleryViewModel: User not authenticated")
            return
        }
        print("🔵 GalleryViewModel: Loading models for user: \(userId)")

        await setLoading(true)

        do {
            let loadedModels = try await firestoreService.getUserModels(userId: userId)
            print("✅ GalleryViewModel: Loaded \(loadedModels.count) models")
            
            // Log each model
            for (index, model) in loadedModels.enumerated() {
                print("   Model \(index + 1): ID=\(model.id ?? "nil"), isFavorite=\(model.isFavorite), created=\(model.createdAt)")
            }
            
            await MainActor.run {
                self.models = loadedModels
                print("✅ GalleryViewModel: Models set in state, count: \(self.models.count)")
            }
        } catch {
            print("❌ GalleryViewModel: Failed to load models: \(error)")
            await showErrorMessage("Failed to load models: \(error.localizedDescription)")
        }

        await setLoading(false)
    }

    func loadFavoriteModels() async {
        // Use Firebase Auth UID directly
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ GalleryViewModel: User not authenticated")
            return
        }
        print("🔵 GalleryViewModel: Loading favorite models for user: \(userId)")

        do {
            let favorites = try await firestoreService.getFavoriteModels(userId: userId)
            print("✅ GalleryViewModel: Loaded \(favorites.count) favorite models")
            await MainActor.run {
                self.favoriteModels = favorites
            }
        } catch {
            print("❌ GalleryViewModel: Failed to load favorites: \(error)")
            await showErrorMessage("Failed to load favorites: \(error.localizedDescription)")
        }
    }

    // MARK: - Toggle Favorite
    func toggleFavorite(model: Model3D) async {
        guard let modelId = model.id else {
            print("❌ GalleryViewModel: Model has no ID")
            return
        }

        print("🔵 GalleryViewModel: Toggling favorite for model: \(modelId)")

        // ✅ Use current state, not inverse
        let newFavoriteStatus = model.isFavorite
        print("   New favorite status will be: \(newFavoriteStatus)")

        do {
            try await firestoreService.toggleFavorite(modelId: modelId, isFavorite: newFavoriteStatus)
            print("✅ GalleryViewModel: Favorite toggled in Firestore")

            // Update local arrays
            await MainActor.run {
                if let index = models.firstIndex(where: { $0.id == modelId }) {
                    models[index].isFavorite = newFavoriteStatus
                    print("✅ GalleryViewModel: Updated model in main array at index \(index)")
                }

                if newFavoriteStatus {
                    if !favoriteModels.contains(where: { $0.id == modelId }) {
                        favoriteModels.append(model)
                        print("✅ GalleryViewModel: Added to favorites array")
                    }
                } else {
                    favoriteModels.removeAll { $0.id == modelId }
                    print("✅ GalleryViewModel: Removed from favorites array")
                }
            }

        } catch {
            print("❌ GalleryViewModel: Failed to toggle favorite: \(error)")
            await showErrorMessage("Failed to update favorite: \(error.localizedDescription)")
        }
    }


    // MARK: - Delete Model

    func deleteModel(model: Model3D) async {
        guard let modelId = model.id else { return }

        do {
            try await firestoreService.deleteModel(modelId: modelId)

            // Remove from local array
            await MainActor.run {
                models.removeAll { $0.id == modelId }
                favoriteModels.removeAll { $0.id == modelId }
            }
        } catch {
            await showErrorMessage("Failed to delete model: \(error.localizedDescription)")
        }
    }

    // MARK: - Download Model

    func downloadModel(model: Model3D, format: ModelFormat) async -> URL? {
        guard let urlString = getModelURL(for: model, format: format),
              let url = URL(string: urlString) else {
            await showErrorMessage("Model URL not available for format \(format.displayName)")
            return nil
        }

        do {
            let (localURL, _) = try await URLSession.shared.download(from: url)

            // Move to permanent location
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent("\(model.id ?? UUID().uuidString).\(format.fileExtension)")

            try? FileManager.default.removeItem(at: destinationURL) // Remove if exists
            try FileManager.default.moveItem(at: localURL, to: destinationURL)

            // Update model in Firestore
            var updatedModel = model
            updatedModel.isDownloaded = true
            updatedModel.localFileURL = destinationURL.path
            try await firestoreService.updateModel(updatedModel)

            return destinationURL
        } catch {
            await showErrorMessage("Failed to download model: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Helper Methods

    private func getModelURL(for model: Model3D, format: ModelFormat) -> String? {
        switch format {
        case .glb: return model.glbURL
        case .fbx: return model.fbxURL
        case .obj: return model.objURL
        case .usdz: return model.usdzURL
        }
    }

    @MainActor
    private func setLoading(_ value: Bool) {
        isLoading = value
    }

    @MainActor
    private func showErrorMessage(_ message: String) {
        errorMessage = message
    }
}
