//
//  AdvancedARView.swift
//  MeshyApp
//
//  Fully functional AR view with placement, animation, delete & clear-all.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

// MARK: - Advanced AR View
struct AdvancedARView: View {
    let model: Model3D
    @Environment(\.dismiss) var dismiss
    @StateObject private var arViewModel = ARViewModel()

    @State private var showControls = true
    @State private var showSettings = false

    var body: some View {
        ZStack {
            AdvancedARViewContainer(model: model, viewModel: arViewModel)
                .ignoresSafeArea()

            // MARK: - Top Controls
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(NeonTheme.cardBackground.opacity(0.8))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(NeonTheme.cardBackground.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .opacity(showControls ? 1 : 0)

                Spacer()

                // MARK: - Bottom Controls
                if showControls {
                    VStack(spacing: 15) {
                        if !arViewModel.placedObjects.isEmpty {
                            Text("Tap to animate • Pinch to scale • Drag to move • Long-press to delete")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(NeonTheme.cardBackground.opacity(0.8))
                                .cornerRadius(20)
                        }

                        HStack(spacing: 15) {
                            ARActionButton(icon: "cube.fill", title: "Place", color: NeonTheme.neonPurple) {
                                arViewModel.placementMode = .single
                            }

                            ARActionButton(icon: "play.fill", title: "Animate", color: NeonTheme.neonBlue) {
                                arViewModel.playAnimation()
                            }

                            ARActionButton(icon: "camera.fill", title: "Photo", color: NeonTheme.neonCyan) {
                                arViewModel.takeScreenshot()
                            }

                            ARActionButton(icon: "trash.fill", title: "Clear", color: NeonTheme.neonPink) {
                                arViewModel.requestClearAll = true
                            }
                        }
                        .padding()
                        .background(NeonTheme.cardBackground.opacity(0.8))
                        .cornerRadius(25)
                    }
                    .padding()
                }
            }

            // MARK: - Settings Panel
            if showSettings {
                ARSettingsPanel(viewModel: arViewModel)
                    .transition(.move(edge: .trailing))
            }
        }
        .statusBar(hidden: true)
        .onTapGesture { withAnimation { showControls.toggle() } }
    }
}

// MARK: - Advanced AR View Container
struct AdvancedARViewContainer: UIViewRepresentable {
    let model: Model3D
    @ObservedObject var viewModel: ARViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)

        // Add coaching overlay
        let coaching = ARCoachingOverlayView()
        coaching.session = arView.session
        coaching.goal = .horizontalPlane
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coaching)

        // Gestures
        arView.addGestureRecognizer(UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        ))

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.8
        arView.addGestureRecognizer(longPress)

        context.coordinator.arView = arView
        context.coordinator.loadModel()

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.viewModel = viewModel

        // Clear-all command from view model
        if viewModel.requestClearAll {
            context.coordinator.clearAllAnchors()
            viewModel.requestClearAll = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model, viewModel: viewModel)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject {
        let model: Model3D
        var viewModel: ARViewModel
        var arView: ARView?
        var modelEntity: ModelEntity?
        var placedAnchors: [AnchorEntity] = []

        init(model: Model3D, viewModel: ARViewModel) {
            self.model = model
            self.viewModel = viewModel
        }

        // MARK: - Load model
        func loadModel() {
            guard let urlString = model.usdzURL ?? model.glbURL,
                  let remoteURL = URL(string: urlString) else {
                print("❌ Invalid model URL")
                return
            }

            Task {
                do {
                    print("🔵 Downloading model: \(remoteURL)")
                    let (data, response) = try await URLSession.shared.data(from: remoteURL)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        print("❌ Server error")
                        return
                    }

                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("usdz")
                    try data.write(to: tempURL)

                    let entity = try await ModelEntity.loadModel(contentsOf: tempURL)
                    await MainActor.run {
                        self.modelEntity = entity
                        entity.generateCollisionShapes(recursive: true)
                        self.viewModel.availableAnimations = entity.availableAnimations.map { $0.name ?? "Animation" }
                    }
                    print("✅ Model loaded successfully")

                } catch {
                    print("❌ Model load failed: \(error)")
                }
            }
        }

        // MARK: - Tap to Place or Animate
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = recognizer.location(in: arView)

            // Animate if tapped on existing entity
            if let entity = arView.entity(at: location) as? ModelEntity {
                if let anim = entity.availableAnimations.first {
                    entity.playAnimation(anim.repeat())
                }
                return
            }

            // Place if placement mode active
            guard viewModel.placementMode != .none, let modelEntity = modelEntity else { return }
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
            guard let result = results.first else { return }

            let anchor = AnchorEntity(world: result.worldTransform)
            let clone = modelEntity.clone(recursive: true)
            clone.scale = SIMD3<Float>(repeating: 0.001)
            
            // Prepare the model for gestures
            clone.generateCollisionShapes(recursive: true)

            // Add the model to anchor and scene
            anchor.addChild(clone)
            arView.scene.addAnchor(anchor)

            // Install gestures *after* it’s visible
            DispatchQueue.main.async {
                arView.installGestures([.translation, .rotation, .scale], for: clone)
            }

            placedAnchors.append(anchor)
            viewModel.placedObjects.append(clone)


            // Scale animation
            clone.move(
                to: Transform(scale: SIMD3<Float>(repeating: viewModel.modelScale),
                              rotation: clone.transform.rotation,
                              translation: clone.transform.translation),
                relativeTo: clone.parent,
                duration: 0.3,
                timingFunction: .easeOut
            )

            // Disable placement after one item if single mode
            if viewModel.placementMode == .single {
                viewModel.placementMode = .none
            }
        }

        // MARK: - Long Press to Delete One
        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard let arView = arView, recognizer.state == .began else { return }
            let location = recognizer.location(in: arView)
            guard let entity = arView.entity(at: location),
                  let anchor = entity.anchor else { return }

            // Shrink animation then remove
            entity.move(
                to: Transform(scale: SIMD3<Float>(repeating: 0.01),
                              rotation: entity.transform.rotation,
                              translation: entity.transform.translation),
                relativeTo: entity.parent,
                duration: 0.15,
                timingFunction: .easeInOut
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                arView.scene.removeAnchor(anchor)
                self.placedAnchors.removeAll { $0 == anchor }
                self.viewModel.placedObjects.removeAll { $0.anchor?.anchoring == anchor.anchoring }
            }
        }

        // MARK: - Clear All
        func clearAllAnchors() {
            guard let arView = arView else { return }
            print("🗑️ Clearing \(placedAnchors.count) anchors...")

            for anchor in placedAnchors {
                anchor.children.forEach { child in
                    if let model = child as? ModelEntity {
                        model.move(
                            to: Transform(scale: SIMD3<Float>(repeating: 0.01),
                                          rotation: model.transform.rotation,
                                          translation: model.transform.translation),
                            relativeTo: model.parent,
                            duration: 0.15,
                            timingFunction: .easeInOut
                        )
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    arView.scene.removeAnchor(anchor)
                }
            }

            placedAnchors.removeAll()
            viewModel.placedObjects.removeAll()
            print("✅ Scene cleared")
        }
    }
}

// MARK: - AR View Model
class ARViewModel: ObservableObject {
    @Published var placementMode: PlacementMode = .single
    @Published var placedObjects: [ModelEntity] = []
    @Published var availableAnimations: [String] = []
    @Published var modelScale: Float = 0.2
    @Published var physicsEnabled = false
    @Published var occlusionEnabled = true
    @Published var dynamicLightingEnabled = true
    @Published var shadowsEnabled = true
    @Published var requestClearAll: Bool = false

    enum PlacementMode { case none, single, multiple }

    func playAnimation() {
        for entity in placedObjects {
            if let anim = entity.availableAnimations.first {
                entity.playAnimation(anim.repeat())
            }
        }
    }

    func takeScreenshot() {
        if let window = UIApplication.shared.windows.first {
            UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, 0)
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let image = image {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }

    func clearAll() { requestClearAll = true }
}

// MARK: - AR Action Button
struct ARActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 70, height: 70)
            .background(color.opacity(0.3))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(color, lineWidth: 1)
            )
        }
    }
}

// MARK: - AR Settings Panel
struct ARSettingsPanel: View {
    @ObservedObject var viewModel: ARViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AR Settings")
                .font(.title2).bold()
                .foregroundColor(.white)

            VStack(alignment: .leading) {
                Text("Model Scale: \(String(format: "%.2f", viewModel.modelScale))")
                    .foregroundColor(.white)
                Slider(value: $viewModel.modelScale, in: 0.001...0.3)
                    .tint(NeonTheme.neonPurple)
            }

            Divider().background(NeonTheme.neonPurple.opacity(0.3))

            Toggle("Physics", isOn: $viewModel.physicsEnabled).tint(NeonTheme.neonPurple)
            Toggle("Occlusion", isOn: $viewModel.occlusionEnabled).tint(NeonTheme.neonPurple)
            Toggle("Dynamic Lighting", isOn: $viewModel.dynamicLightingEnabled).tint(NeonTheme.neonPurple)
            Toggle("Shadows", isOn: $viewModel.shadowsEnabled).tint(NeonTheme.neonPurple)

            Spacer()
        }
        .padding()
        .frame(width: 300)
        .background(NeonTheme.cardBackground.opacity(0.95))
        .cornerRadius(20)
    }
}
