//
//  MeshyAPIService.swift
//  MeshyApp
//
//  Service for interacting with Meshy API via Firebase Cloud Functions proxy
//

import Foundation
import Combine

class MeshyAPIService {
    static let shared = MeshyAPIService()

    /// IMPORTANT:
    /// Do NOT store the Meshy API key locally.
    /// All calls go through your secure Firebase proxy instead.
    private let baseURL = "https://us-central1-xt-imageto3d.cloudfunctions.net"

    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Text to 3D (preview + refine)

    /// Create preview (rough model)
    func createTextTo3DPreview(
        prompt: String,
        artStyle: ArtStyle = .realistic,
        aiModel: AIModel = .latest,
        targetPolycount: Int = 30000,
        negativePrompt: String? = nil
    ) async throws -> String {
        let endpoint = "/meshyTextTo3D"
        let url = URL(string: baseURL + endpoint)!
        
        var body: [String: Any] = [
            "mode": "preview",
            "prompt": prompt,
            "art_style": artStyle.rawValue,
            "ai_model": aiModel.rawValue,
            "target_polycount": targetPolycount,
            "should_remesh": true
        ]
        if let negativePrompt = negativePrompt {
            body["negative_prompt"] = negativePrompt
        }

        let (data, response) = try await performRequest(url: url, method: "POST", body: body)
        try validate(response)
        let result = try JSONDecoder().decode(TaskResponse.self, from: data)
        return result.result
    }

    /// Refine stage (add textures / details)
    func createTextTo3DRefine(
        previewTaskId: String,
        enablePBR: Bool = true,
        texturePrompt: String? = nil,
        aiModel: AIModel = .latest
    ) async throws -> String {
        let endpoint = "/meshyTextTo3D"
        let url = URL(string: baseURL + endpoint)!

        var body: [String: Any] = [
            "mode": "refine",
            "preview_task_id": previewTaskId,
            "enable_pbr": enablePBR,
            "ai_model": aiModel.rawValue
        ]
        if let texturePrompt = texturePrompt {
            body["texture_prompt"] = texturePrompt
        }

        let (data, response) = try await performRequest(url: url, method: "POST", body: body)
        try validate(response)
        let result = try JSONDecoder().decode(TaskResponse.self, from: data)
        return result.result
    }

    /// Get task status (text-to-3D)
    func getTextTo3DTask(taskId: String) async throws -> TaskDetails {
        let endpoint = "/meshyGetTask?taskId=\(taskId)"
        let url = URL(string: baseURL + endpoint)!
        let (data, response) = try await performRequest(url: url, method: "GET")
        try validate(response)
        return try decodeTask(from: data)
    }

    // MARK: - Image to 3D

    func createImageTo3D(
        imageURL: String,
        aiModel: AIModel = .latest,
        enablePBR: Bool = true,
        shouldTexture: Bool = true,
        targetPolycount: Int = 30000,
        texturePrompt: String? = nil
    ) async throws -> String {
        let endpoint = "/meshyImageTo3D"
        let url = URL(string: baseURL + endpoint)!

        var body: [String: Any] = [
            "image_url": imageURL,
            "ai_model": aiModel.rawValue,
            "enable_pbr": enablePBR,
            "should_texture": shouldTexture,
            "target_polycount": targetPolycount,
            "should_remesh": true
        ]
        if let texturePrompt = texturePrompt {
            body["texture_prompt"] = texturePrompt
        }

        let (data, response) = try await performRequest(url: url, method: "POST", body: body)
        try validate(response)
        let result = try JSONDecoder().decode(TaskResponse.self, from: data)
        return result.result
    }

    func getImageTo3DTask(taskId: String) async throws -> TaskDetails {
        let endpoint = "/meshyGetTask?taskId=\(taskId)"
        let url = URL(string: baseURL + endpoint)!
        let (data, response) = try await performRequest(url: url, method: "GET")
        try validate(response)
        return try decodeTask(from: data)
    }

    // MARK: - Polling utility

    func pollTaskStatus(
        taskId: String,
        type: GenerationType,
        maxAttempts: Int = 120,
        intervalSeconds: TimeInterval = 5
    ) async throws -> TaskDetails {
        var displayedProgress = 0

        for attempt in 0..<maxAttempts {
            let task = try await (type == .textTo3D
                ? getTextTo3DTask(taskId: taskId)
                : getImageTo3DTask(taskId: taskId))

            let realProgress = task.progress ?? displayedProgress

            switch task.status {
            case "SUCCEEDED":
                // Immediately set to 100% when finished
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: Notification.Name("MeshyProgressUpdate"),
                        object: nil,
                        userInfo: ["progress": 100]
                    )
                }
                return task

            case "FAILED", "CANCELED":
                throw MeshyAPIError.taskFailed(task.task_error?.message ?? "Unknown error")

            default:
                // --- Smooth interpolation ---
                if realProgress <= 10 {
                    // Stage 1: Upload/preprocess
                    displayedProgress = min(displayedProgress + Int.random(in: 1...2), 20)
                } else if realProgress < 90 {
                    // Stage 2: Generate mesh/textures
                    displayedProgress = min(displayedProgress + Int.random(in: 1...3), 90)
                } else {
                    displayedProgress = realProgress
                }

                // Broadcast to UI
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: Notification.Name("MeshyProgressUpdate"),
                        object: nil,
                        userInfo: ["progress": displayedProgress]
                    )
                }

                print("🔄 Progress \(displayedProgress)% (\(attempt + 1)/\(maxAttempts))")
                try await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }

        throw MeshyAPIError.timeout
    }


    // MARK: - Helpers

    private func performRequest(
        url: URL,
        method: String,
        body: [String: Any]? = nil
    ) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return try await URLSession.shared.data(for: request)
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw MeshyAPIError.invalidResponse
        }
    }

    private func decodeTask(from data: Data) throws -> TaskDetails {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(TaskDetails.self, from: data)
    }
}

// MARK: - Codable Models

struct TaskResponse: Codable {
    let result: String
}

struct TaskDetails: Codable {
    let id: String
    let status: String
    let progress: Int?
    let model_urls: ModelURLs?
    let texture_urls: [TextureURL]?
    let thumbnail_url: String?
    let video_url: String?
    let task_error: TaskError?
    let created_at: Int?
    let started_at: Int?
    let finished_at: Int?
    let expires_at: Int?
}

struct ModelURLs: Codable {
    let glb: String?
    let fbx: String?
    let obj: String?
    let mtl: String?
    let usdz: String?
}

struct TextureURL: Codable {
    let base_color: String?
    let metallic: String?
    let normal: String?
    let roughness: String?
}

struct TaskError: Codable {
    let message: String?
}

// MARK: - Errors

enum MeshyAPIError: LocalizedError {
    case invalidResponse
    case taskFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .taskFailed(let message):
            return "Task failed: \(message)"
        case .timeout:
            return "Request timed out"
        }
    }
}
