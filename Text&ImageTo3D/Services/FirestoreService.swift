//
//  FirestoreService.swift
//  MeshyApp
//
//  Firestore database service
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirestoreService {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Collections

    private var usersCollection: CollectionReference {
        db.collection("users")
    }

    private var generationsCollection: CollectionReference {
        db.collection("generations")
    }

    private var modelsCollection: CollectionReference {
        db.collection("models")
    }

    // MARK: - User Methods

    func createUser(_ user: AppUser) async throws {
        // Use Firebase Auth UID directly
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirestoreError.userNotAuthenticated
        }
        
        print("🔵 FirestoreService: Creating user document for: \(userId)")
        
        // Create a mutable copy of user
        var newUser = user
        newUser.id = nil  // Don't set ID, let Firestore handle it
        
        // Use the Firebase Auth UID as the document ID
        try usersCollection.document(userId).setData(from: newUser)
        print("✅ FirestoreService: User document created")
    }

    func getUser(userId: String) async throws -> AppUser? {
        let snapshot = try await usersCollection.document(userId).getDocument()
        guard var user = try? snapshot.data(as: AppUser.self) else { return nil }
        user.id = userId  // Manually set the document ID
        return user
    }

    func updateLastLogin(userId: String) async throws {
        try await usersCollection.document(userId).updateData([
            "lastLoginAt": FieldValue.serverTimestamp()
        ])
    }

    func updateUserCredits(userId: String, amount: Int) async throws {
        try await usersCollection.document(userId).updateData([
            "credits": FieldValue.increment(Int64(amount))
        ])
    }

    func updateSubscription(userId: String, type: SubscriptionType, endDate: Date?) async throws {
        var data: [String: Any] = [
            "subscriptionType": type.rawValue
        ]

        if let endDate = endDate {
            data["subscriptionEndDate"] = Timestamp(date: endDate)
        }

        try await usersCollection.document(userId).updateData(data)
    }

    func deleteUser(userId: String) async throws {
        // Delete all user's generations
        let generations = try await getUserGenerations(userId: userId)
        for generation in generations {
            if let genId = generation.id {
                try await deleteGeneration(generationId: genId)
            }
        }

        // Delete user document
        try await usersCollection.document(userId).delete()
    }

    // MARK: - Generation Methods

    func createGeneration(_ generation: Generation) async throws -> String {
        print("🔵 Starting generation creation...")
        
        // Verify user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ User not authenticated")
            throw FirestoreError.userNotAuthenticated
        }
        print("✅ User authenticated: \(currentUser.uid)")
        
        // Verify generation has correct userId
        guard generation.userId == currentUser.uid else {
            print("❌ UserId mismatch: generation.userId=\(generation.userId), currentUser=\(currentUser.uid)")
            throw FirestoreError.unauthorizedAccess
        }
        print("✅ UserId matches")
        
        // Don't set the ID - let Firestore handle it
        var newGeneration = generation
        newGeneration.id = nil
        
        print("🔵 Attempting to add document to Firestore...")
        let ref = try generationsCollection.addDocument(from: newGeneration)
        print("✅ Generation created with ID: \(ref.documentID)")
        
        return ref.documentID
    }

    func getGeneration(generationId: String) async throws -> Generation? {
        let snapshot = try await generationsCollection.document(generationId).getDocument()
        guard var generation = try? snapshot.data(as: Generation.self) else { return nil }
        generation.id = generationId  // Manually set the document ID
        return generation
    }

    func updateGeneration(_ generation: Generation) async throws {
        guard let generationId = generation.id else {
            throw FirestoreError.invalidGenerationId
        }

        try generationsCollection.document(generationId).setData(from: generation, merge: true)
    }

    func updateGenerationStatus(
        generationId: String,
        status: GenerationStatus,
        progress: Int? = nil,
        errorMessage: String? = nil
    ) async throws {
        var data: [String: Any] = [
            "status": status.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let progress = progress {
            data["progress"] = progress
        }

        if let errorMessage = errorMessage {
            data["errorMessage"] = errorMessage
        }

        if status == .succeeded {
            data["completedAt"] = FieldValue.serverTimestamp()
        }

        try await generationsCollection.document(generationId).updateData(data)
    }

    func getUserGenerations(userId: String, limit: Int = 50) async throws -> [Generation] {
        let snapshot = try await generationsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> Generation? in
            guard var generation = try? doc.data(as: Generation.self) else { return nil }
            generation.id = doc.documentID  // Manually set the document ID
            return generation
        }
    }

    func deleteGeneration(generationId: String) async throws {
        try await generationsCollection.document(generationId).delete()
    }

    // MARK: - Model Methods

    func createModel(_ model: Model3D) async throws -> String {
        // Verify user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw FirestoreError.userNotAuthenticated
        }
        
        // Don't set the ID - let Firestore handle it
        var newModel = model
        newModel.id = nil
        
        let ref = try modelsCollection.addDocument(from: newModel)
        print("✅ FirestoreService: Model created with ID: \(ref.documentID)")
        return ref.documentID
    }

    func getModel(modelId: String) async throws -> Model3D? {
        let snapshot = try await modelsCollection.document(modelId).getDocument()
        guard var model = try? snapshot.data(as: Model3D.self) else { return nil }
        model.id = modelId  // Manually set the document ID
        return model
    }

    func updateModel(_ model: Model3D) async throws {
        guard let modelId = model.id else {
            throw FirestoreError.invalidModelId
        }

        try modelsCollection.document(modelId).setData(from: model, merge: true)
    }

    func getUserModels(userId: String, limit: Int = 50) async throws -> [Model3D] {
        let snapshot = try await modelsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> Model3D? in
            guard var model = try? doc.data(as: Model3D.self) else { return nil }
            model.id = doc.documentID  // Manually set the document ID
            return model
        }
    }

    func getFavoriteModels(userId: String) async throws -> [Model3D] {
        let snapshot = try await modelsCollection
            .whereField("userId", isEqualTo: userId)
            .whereField("isFavorite", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> Model3D? in
            guard var model = try? doc.data(as: Model3D.self) else { return nil }
            model.id = doc.documentID  // Manually set the document ID
            return model
        }
    }

    func toggleFavorite(modelId: String, isFavorite: Bool) async throws {
        print("🔵 FirestoreService: Toggling favorite for model: \(modelId) to: \(isFavorite)")
        try await modelsCollection.document(modelId).updateData([
            "isFavorite": isFavorite
        ])
        print("✅ FirestoreService: Favorite toggled successfully")
    }

    func deleteModel(modelId: String) async throws {
        print("🔵 FirestoreService: Deleting model: \(modelId)")
        try await modelsCollection.document(modelId).delete()
        print("✅ FirestoreService: Model deleted successfully")
    }

    // MARK: - Real-time Listeners

    func listenToGeneration(
        generationId: String,
        completion: @escaping (Result<Generation, Error>) -> Void
    ) -> ListenerRegistration {
        return generationsCollection.document(generationId).addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(FirestoreError.documentNotFound))
                return
            }

            do {
                var generation = try snapshot.data(as: Generation.self)
                generation.id = snapshot.documentID  // Manually set the document ID
                completion(.success(generation))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Firestore Errors

enum FirestoreError: LocalizedError {
    case invalidUserId
    case invalidGenerationId
    case invalidModelId
    case documentNotFound
    case userNotAuthenticated
    case unauthorizedAccess

    var errorDescription: String? {
        switch self {
        case .invalidUserId:
            return "Invalid user ID"
        case .invalidGenerationId:
            return "Invalid generation ID"
        case .invalidModelId:
            return "Invalid model ID"
        case .documentNotFound:
            return "Document not found"
        case .userNotAuthenticated:
            return "User must be signed in"
        case .unauthorizedAccess:
            return "Unauthorized access"
        }
    }
}
