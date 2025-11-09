//
//  User.swift
//  MeshyApp
//
//  User model for Firebase authentication and Firestore
//

import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var photoURL: String?
    var credits: Int
    var subscriptionType: SubscriptionType
    var subscriptionEndDate: Date?
    var createdAt: Date
    var lastLoginAt: Date

    enum CodingKeys: String, CodingKey {
        // Removed 'id' - @DocumentID handles it automatically
        case email
        case displayName
        case photoURL
        case credits
        case subscriptionType
        case subscriptionEndDate
        case createdAt
        case lastLoginAt
    }

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        photoURL: String? = nil,
        credits: Int = 0,
        subscriptionType: SubscriptionType = .free,
        subscriptionEndDate: Date? = nil,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date()
    ) {
        // Don't set self.id - @DocumentID manages it
        // self.id = id  // Remove this line
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.credits = credits
        self.subscriptionType = subscriptionType
        self.subscriptionEndDate = subscriptionEndDate
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
}

enum SubscriptionType: String, Codable {
    case free = "free"
    case monthly = "monthly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .monthly: return "Monthly Pro"
        case .yearly: return "Yearly Pro"
        }
    }

    var monthlyCredits: Int {
        switch self {
        case .free: return 0
        case .monthly: return 200
        case .yearly: return 250
        }
    }
}
