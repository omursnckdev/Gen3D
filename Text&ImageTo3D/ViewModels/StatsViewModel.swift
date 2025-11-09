//
//  StatsViewModel.swift
//  MeshyApp
//
//  ViewModel for tracking user statistics
//

import Foundation
import FirebaseAuth
import Combine

class StatsViewModel: ObservableObject {
    @Published var totalModels = 0
    @Published var favoriteModels = 0
    @Published var downloadedModels = 0
    
    private let firestoreService = FirestoreService.shared
    
    func loadStats() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Stats: User not authenticated")
            return
        }
        
        print("🔵 Stats: Loading stats for user: \(userId)")
        
        do {
            // Load all models
            let models = try await firestoreService.getUserModels(userId: userId, limit: 1000)
            
            // Calculate stats
            let favorites = models.filter { $0.isFavorite }.count
            let downloads = models.filter { $0.isDownloaded }.count
            
            await MainActor.run {
                self.totalModels = models.count
                self.favoriteModels = favorites
                self.downloadedModels = downloads
            }
            
            print("✅ Stats: Models: \(models.count), Favorites: \(favorites), Downloads: \(downloads)")
        } catch {
            print("❌ Stats: Failed to load: \(error)")
        }
    }
}
