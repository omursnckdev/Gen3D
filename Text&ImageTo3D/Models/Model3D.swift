//
//  Model3D.swift
//  MeshyApp
//
//  Model for generated 3D models
//

import Foundation
import FirebaseFirestore

// MARK: - Model3D
struct Model3D: Codable, Identifiable {
    @DocumentID var id: String?
    var generationId: String
    var userId: String

    // Model URLs
    var glbURL: String?
    var fbxURL: String?
    var objURL: String?
    var usdzURL: String?
    var mtlURL: String?

    // Texture URLs
    var baseColorURL: String?
    var metallicURL: String?
    var normalURL: String?
    var roughnessURL: String?

    // Metadata
    var thumbnailURL: String?
    var videoURL: String?
    var polycount: Int?
    var hasPBR: Bool

    var createdAt: Date
    var expiresAt: Date?
    var isDownloaded: Bool
    var localFileURL: String?

    var isFavorite: Bool
    var isPublic: Bool
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case generationId, userId
        case glbURL, fbxURL, objURL, usdzURL, mtlURL
        case baseColorURL, metallicURL, normalURL, roughnessURL
        case thumbnailURL, videoURL, polycount, hasPBR
        case createdAt, expiresAt, isDownloaded, localFileURL
        case isFavorite, isPublic, tags
    }

    // Computed property for best model URL (prefers AR-ready formats)
    var preferredModelURL: String? {
        usdzURL ?? glbURL ?? fbxURL ?? objURL
    }

    // Check if model has expired
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

// MARK: - Model Format Enum
enum ModelFormat: String, CaseIterable, Codable {
    case glb = "GLB"
    case fbx = "FBX"
    case obj = "OBJ"
    case usdz = "USDZ"

    var fileExtension: String {
        self.rawValue.lowercased()
    }

    var displayName: String {
        switch self {
        case .glb:  return "GLB (.glb)"
        case .fbx:  return "FBX (.fbx)"
        case .obj:  return "OBJ (.obj)"
        case .usdz: return "USDZ (.usdz)"
        }
    }

    var icon: String {
        switch self {
        case .usdz: return "arkit"
        default:    return "cube.fill"
        }
    }

}

// MARK: - Credit Package
struct CreditPackage: Identifiable {
    let id: String
    let credits: Int
    let price: Double
    let productIdentifier: String
    let bonus: Int
    let isPopular: Bool

    var totalCredits: Int {
        credits + bonus
    }

    var pricePerCredit: Double {
        price / Double(totalCredits)
    }
}

// MARK: - Subscription Plan
struct SubscriptionPlan: Identifiable {
    let id: String
    let type: SubscriptionType
    let monthlyCredits: Int
    let price: Double
    let productIdentifier: String
    let features: [String]
    let isPopular: Bool

    var pricePerMonth: Double {
        switch type {
        case .monthly: return price
        case .yearly:  return price / 12
        case .free:    return 0
        }
    }
}
