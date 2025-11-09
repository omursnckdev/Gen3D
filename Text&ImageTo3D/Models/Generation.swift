//
//  Generation.swift
//  MeshyApp
//
//  Model for tracking 3D generation tasks
//

import Foundation
import FirebaseFirestore

struct Generation: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var type: GenerationType
    var status: GenerationStatus
    var progress: Int
    var taskId: String?
    var previewTaskId: String?
    var refineTaskId: String?

    // Input parameters
    var prompt: String?
    var imageURL: String?
    var artStyle: ArtStyle?
    var aiModel: AIModel
    var enablePBR: Bool
    var targetPolycount: Int

    // Output
    var model3D: Model3D?
    var thumbnailURL: String?
    var videoURL: String?

    var createdAt: Date
    var updatedAt: Date?  // Changed to optional
    var completedAt: Date?

    var errorMessage: String?
    
    // Update initializer
    init(
        id: String? = nil,
        userId: String,
        type: GenerationType,
        status: GenerationStatus,
        progress: Int,
        taskId: String? = nil,
        previewTaskId: String? = nil,
        refineTaskId: String? = nil,
        prompt: String? = nil,
        imageURL: String? = nil,
        artStyle: ArtStyle? = nil,
        aiModel: AIModel,
        enablePBR: Bool,
        targetPolycount: Int,
        model3D: Model3D? = nil,
        thumbnailURL: String? = nil,
        videoURL: String? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,  // Changed to optional with default nil
        completedAt: Date? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.status = status
        self.progress = progress
        self.taskId = taskId
        self.previewTaskId = previewTaskId
        self.refineTaskId = refineTaskId
        self.prompt = prompt
        self.imageURL = imageURL
        self.artStyle = artStyle
        self.aiModel = aiModel
        self.enablePBR = enablePBR
        self.targetPolycount = targetPolycount
        self.model3D = model3D
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.errorMessage = errorMessage
    }

    enum CodingKeys: String, CodingKey {
        case userId, type, status, progress, taskId, previewTaskId, refineTaskId
        case prompt, imageURL, artStyle, aiModel, enablePBR, targetPolycount
        case model3D, thumbnailURL, videoURL
        case createdAt, updatedAt, completedAt, errorMessage
    }
}

enum GenerationType: String, Codable {
    case textTo3D = "text_to_3d"
    case imageTo3D = "image_to_3d"

    var displayName: String {
        switch self {
        case .textTo3D: return "Text to 3D"
        case .imageTo3D: return "Image to 3D"
        }
    }

    var icon: String {
        switch self {
        case .textTo3D: return "text.bubble.fill"
        case .imageTo3D: return "photo.fill"
        }
    }
}

enum GenerationStatus: String, Codable {
    case pending = "PENDING"
    case inProgress = "IN_PROGRESS"
    case succeeded = "SUCCEEDED"
    case failed = "FAILED"
    case canceled = "CANCELED"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .succeeded: return "Completed"
        case .failed: return "Failed"
        case .canceled: return "Canceled"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .inProgress: return "blue"
        case .succeeded: return "green"
        case .failed: return "red"
        case .canceled: return "gray"
        }
    }
}

enum ArtStyle: String, Codable, CaseIterable {
    case realistic = "realistic"
    case sculpture = "sculpture"

    var displayName: String {
        switch self {
        case .realistic: return "Realistic"
        case .sculpture: return "Sculpture"
        }
    }
}

enum AIModel: String, Codable, CaseIterable {
    case meshy4 = "meshy-4"
    case meshy5 = "meshy-5"
    case meshy6 = "meshy-6"
    case latest = "latest"

    var displayName: String {
        switch self {
        case .meshy4: return "Meshy 4"
        case .meshy5: return "Meshy 5"
        case .meshy6: return "Meshy 6 (Premium)"
        case .latest: return "Latest"
        }
    }

    var creditCost: Int {
        switch self {
        case .meshy6: return 20
        default: return 5
        }
    }
}
