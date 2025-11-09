//
//  ARViewContainer.swift
//  MeshyApp
//
//  ARKit integration for viewing 3D models in augmented reality
//

import SwiftUI
import RealityKit
import ARKit
import QuickLook

struct ARViewContainer: UIViewRepresentable {
    let modelURL: URL
    @Binding var isPlaced: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        arView.session.run(config)

        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        // Optional: improve gesture responsiveness
        arView.gestureRecognizers?.forEach { $0.delaysTouchesBegan = false }

        context.coordinator.arView = arView
        context.coordinator.loadModel()

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(modelURL: modelURL, isPlaced: $isPlaced)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject {
        let modelURL: URL
        @Binding var isPlaced: Bool
        weak var arView: ARView?
        var modelEntity: ModelEntity?

        init(modelURL: URL, isPlaced: Binding<Bool>) {
            self.modelURL = modelURL
            self._isPlaced = isPlaced
        }

        // MARK: - Load Model
        func loadModel() {
            Task {
                do {
                    let entity = try await ModelEntity.loadModel(contentsOf: modelURL)

                    await MainActor.run {
                        entity.generateCollisionShapes(recursive: true)
                        entity.scale = SIMD3<Float>(0.01, 0.01, 0.01)
                        self.modelEntity = entity
                        print("✅ Model loaded successfully: \(modelURL.lastPathComponent)")
                    }
                } catch {
                    print("❌ Failed to load model: \(error)")
                }
            }
        }

        // MARK: - Handle Tap to Place
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView,
                  let modelEntity = modelEntity else { return }

            let location = recognizer.location(in: arView)
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)

            guard let firstResult = results.first else {
                print("⚠️ No plane detected at tap point.")
                return
            }

            // Create anchor
            let anchor = AnchorEntity(world: firstResult.worldTransform)

            // Clone and prepare model
            let clonedModel = modelEntity.clone(recursive: true)
            clonedModel.generateCollisionShapes(recursive: true)
            clonedModel.isEnabled = true

            // Smooth appear animation
            let targetScale = SIMD3<Float>(0.2, 0.2, 0.2)
            clonedModel.scale = targetScale * 0.01

            // Add to scene
            anchor.addChild(clonedModel)
            arView.scene.addAnchor(anchor)

            // Install gestures after addition
            DispatchQueue.main.async {
                arView.installGestures([.translation, .rotation, .scale], for: clonedModel)
            }

            // Animate growth
            clonedModel.move(
                to: Transform(scale: targetScale,
                              rotation: clonedModel.orientation,
                              translation: clonedModel.position),
                relativeTo: clonedModel.parent,
                duration: 0.25,
                timingFunction: .easeOut
            )

            isPlaced = true
            print("✅ Model placed in AR scene.")
        }
    }
}

// MARK: - AR Quick Look
struct ARQuickLookView: UIViewControllerRepresentable {
    let modelURL: URL

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            let preview = QLPreviewController()
            preview.dataSource = context.coordinator
            vc.present(preview, animated: true)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(modelURL: modelURL)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let modelURL: URL
        init(modelURL: URL) { self.modelURL = modelURL }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            modelURL as QLPreviewItem
        }
    }
}
