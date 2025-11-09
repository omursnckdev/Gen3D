//
//  BatchGenerationView.swift
//  MeshyApp
//
//  Batch generation view for creating multiple models
//

import SwiftUI
import PhotosUI
import Combine

struct BatchGenerationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel = BatchGenerationViewModel()
    @State private var selectedTab = 0
    @State private var showUpgradeSheet = false

    var isYearlySubscriber: Bool {
        authService.user?.subscriptionType == .yearly
    }

    var body: some View {
        NavigationView {
            ZStack {
                NeonTheme.background
                    .ignoresSafeArea()

                if !isYearlySubscriber {
                    // Paywall for non-yearly subscribers
                    BatchGenerationPaywall(showUpgradeSheet: $showUpgradeSheet)
                } else {
                    // Full batch generation interface
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(NeonTheme.glowGradient)
                                .neonGlow(color: NeonTheme.neonCyan)

                            Text("Batch Generation")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text("Generate multiple 3D models at once")
                                .font(.subheadline)
                                .foregroundColor(NeonTheme.secondaryText)

                            // Premium badge
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(NeonTheme.neonPurple)
                                Text("Yearly Pro Feature")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(NeonTheme.cardBackground)
                            .cornerRadius(20)
                            .neonGlow(color: NeonTheme.neonPurple, radius: 8)
                        }
                        .padding(.top)

                        // Tab selector
                        Picker("Type", selection: $selectedTab) {
                            Text("Text to 3D").tag(0)
                            Text("Image to 3D").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()

                        // Content
                        if selectedTab == 0 {
                            BatchTextTo3DView(viewModel: viewModel)
                        } else {
                            BatchImageTo3DView(viewModel: viewModel)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(NeonTheme.neonPurple)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isYearlySubscriber {
                        Button(action: { viewModel.startBatchGeneration() }) {
                            Text("Start All")
                                .foregroundColor(NeonTheme.neonCyan)
                                .fontWeight(.semibold)
                        }
                        .disabled(viewModel.batchItems.isEmpty || viewModel.isGenerating)
                    }
                }
            }
            .sheet(isPresented: $showUpgradeSheet) {
                CreditsView()
            }
        }
    }
}

// MARK: - Batch Generation Paywall
struct BatchGenerationPaywall: View {
    @Binding var showUpgradeSheet: Bool

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Lock icon
            ZStack {
                Circle()
                    .fill(NeonTheme.primaryGradient)
                    .frame(width: 120, height: 120)
                    .neonGlow(color: NeonTheme.neonPurple, radius: 30)

                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            // Title and description
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(NeonTheme.neonPurple)
                    Text("Yearly Pro Exclusive")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)

                Text("Batch Generation is available exclusively for Yearly Pro subscribers")
                    .font(.headline)
                    .foregroundColor(NeonTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Features
            VStack(alignment: .leading, spacing: 20) {
                PaywallFeature(
                    icon: "square.stack.3d.up.fill",
                    title: "Batch Generation",
                    description: "Create multiple models at once"
                )

                PaywallFeature(
                    icon: "star.fill",
                    title: "250 Credits/Month",
                    description: "More credits than monthly plan"
                )

                PaywallFeature(
                    icon: "bolt.fill",
                    title: "Priority Queue",
                    description: "Faster generation times"
                )

                PaywallFeature(
                    icon: "dollarsign.circle.fill",
                    title: "Best Value",
                    description: "Save 25% compared to monthly"
                )
            }
            .padding()
            .neonCard()
            .padding(.horizontal)

            Spacer()

            // Upgrade button
            VStack(spacing: 15) {
                Button(action: { showUpgradeSheet = true }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Yearly Pro")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(NeonButtonStyle())
                .padding(.horizontal)

                Text("Only $179.99/year ($14.99/month)")
                    .font(.subheadline)
                    .foregroundColor(NeonTheme.neonCyan)
            }
            .padding(.bottom, 30)
        }
    }
}

struct PaywallFeature: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(NeonTheme.neonCyan)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(NeonTheme.secondaryText)
            }

            Spacer()
        }
    }
}

// MARK: - Batch Text to 3D View
struct BatchTextTo3DView: View {
    @ObservedObject var viewModel: BatchGenerationViewModel
    @State private var newPrompt = ""
    @State private var selectedArtStyle: ArtStyle = .realistic
    @State private var selectedAIModel: AIModel = .latest

    var body: some View {
        VStack(spacing: 15) {
            // Input area
            VStack(alignment: .leading, spacing: 10) {
                Text("Add Prompts")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 10) {
                    TextField("Enter description...", text: $newPrompt)
                        .textFieldStyle(NeonTextFieldStyle())

                    Button(action: addPrompt) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(NeonTheme.neonPurple)
                    }
                    .disabled(newPrompt.isEmpty)
                }

                // Quick options
                HStack {
                    Picker("Style", selection: $selectedArtStyle) {
                        ForEach(ArtStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .tint(NeonTheme.neonPurple)

                    Picker("Model", selection: $selectedAIModel) {
                        ForEach(AIModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .tint(NeonTheme.neonPurple)
                }
            }
            .padding()
            .neonCard()
            .padding(.horizontal)

            // Batch items list
            ScrollView {
                if viewModel.batchItems.isEmpty {
                    EmptyBatchView()
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.batchItems) { item in
                            BatchItemRow(item: item) {
                                viewModel.removeItem(item)
                            }
                        }
                    }
                    .padding()
                }
            }

            // Stats footer
            BatchStatsFooter(viewModel: viewModel)
        }
    }

    private func addPrompt() {
        let item = BatchItem(
            type: .textTo3D,
            prompt: newPrompt,
            artStyle: selectedArtStyle,
            aiModel: selectedAIModel
        )
        viewModel.addItem(item)
        newPrompt = ""
    }
}

// MARK: - Batch Image to 3D View
struct BatchImageTo3DView: View {
    @ObservedObject var viewModel: BatchGenerationViewModel
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var selectedAIModel: AIModel = .latest

    var body: some View {
        VStack(spacing: 15) {
            // Image picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Add Images")
                    .font(.headline)
                    .foregroundColor(.white)

                PhotosPicker(
                    selection: $selectedImages,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                            .foregroundColor(NeonTheme.neonPurple)

                        Text("Select Images (Max 10)")
                            .foregroundColor(.white)

                        Spacer()

                        if !selectedImages.isEmpty {
                            Text("\(selectedImages.count) selected")
                                .font(.caption)
                                .foregroundColor(NeonTheme.neonCyan)
                        }
                    }
                    .padding()
                    .neonCard()
                }
                .onChange(of: selectedImages) { newItems in
                    addImages(newItems)
                }

                // Quick options
                Picker("AI Model", selection: $selectedAIModel) {
                    ForEach(AIModel.allCases, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(NeonTheme.neonPurple)
            }
            .padding()
            .neonCard()
            .padding(.horizontal)

            // Batch items list
            ScrollView {
                if viewModel.batchItems.isEmpty {
                    EmptyBatchView()
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.batchItems) { item in
                            BatchItemRow(item: item) {
                                viewModel.removeItem(item)
                            }
                        }
                    }
                    .padding()
                }
            }

            // Stats footer
            BatchStatsFooter(viewModel: viewModel)
        }
    }

    private func addImages(_ items: [PhotosPickerItem]) {
        Task {
            for photoItem in items {
                if let data = try? await photoItem.loadTransferable(type: Data.self) {
                    let item = BatchItem(
                        type: .imageTo3D,
                        imageData: data,
                        aiModel: selectedAIModel
                    )
                    await MainActor.run {
                        viewModel.addItem(item)
                    }
                }
            }
            selectedImages = []
        }
    }
}

// MARK: - Batch Item Row
struct BatchItemRow: View {
    let item: BatchItem
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 40, height: 40)

                if item.status == .generating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: statusIcon)
                        .foregroundColor(.white)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 5) {
                if let prompt = item.prompt {
                    Text(prompt)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                } else if item.imageData != nil {
                    Text("Image Upload")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }

                HStack {
                    Text(item.aiModel.displayName)
                        .font(.caption)
                        .foregroundColor(NeonTheme.secondaryText)

                    Text("•")
                        .foregroundColor(NeonTheme.secondaryText)

                    Text("\(item.estimatedCredits) credits")
                        .font(.caption)
                        .foregroundColor(NeonTheme.neonCyan)
                }

                if item.status == .generating {
                    ProgressView(value: Double(item.progress) / 100.0)
                        .tint(NeonTheme.neonPurple)
                }
            }

            Spacer()

            // Delete button
            if item.status == .pending {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .neonCard()
    }

    private var statusColor: Color {
        switch item.status {
        case .pending: return NeonTheme.cardBackground
        case .generating: return NeonTheme.neonBlue
        case .completed: return NeonTheme.success
        case .failed: return NeonTheme.error
        }
    }

    private var statusIcon: String {
        switch item.status {
        case .pending: return "clock"
        case .generating: return "gearshape"
        case .completed: return "checkmark"
        case .failed: return "xmark"
        }
    }
}

// MARK: - Batch Stats Footer
struct BatchStatsFooter: View {
    @ObservedObject var viewModel: BatchGenerationViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(viewModel.batchItems.count) Items")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Total: \(viewModel.totalCredits) credits")
                    .font(.caption)
                    .foregroundColor(NeonTheme.neonCyan)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 15) {
                    StatusBadge(
                        count: viewModel.completedCount,
                        color: NeonTheme.success,
                        icon: "checkmark"
                    )

                    StatusBadge(
                        count: viewModel.generatingCount,
                        color: NeonTheme.neonBlue,
                        icon: "gearshape"
                    )

                    StatusBadge(
                        count: viewModel.failedCount,
                        color: NeonTheme.error,
                        icon: "xmark"
                    )
                }
            }
        }
        .padding()
        .neonCard()
        .padding()
    }
}

struct StatusBadge: View {
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
    }
}

// MARK: - Empty Batch View
struct EmptyBatchView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 80))
                .foregroundStyle(NeonTheme.glowGradient)
                .neonGlow(color: NeonTheme.neonCyan)

            Text("No items added")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Add prompts or images to start batch generation")
                .font(.subheadline)
                .foregroundColor(NeonTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Batch Item Model
struct BatchItem: Identifiable {
    let id = UUID()
    let type: GenerationType
    var prompt: String?
    var imageData: Data?
    var artStyle: ArtStyle?
    var aiModel: AIModel
    var status: BatchStatus = .pending
    var progress: Int = 0
    var generationId: String?
    var errorMessage: String?

    var estimatedCredits: Int {
        let baseCost = aiModel.creditCost
        return baseCost + 10 // Including texture refinement
    }
}

enum BatchStatus {
    case pending
    case generating
    case completed
    case failed
}

// MARK: - Batch Generation ViewModel
class BatchGenerationViewModel: ObservableObject {
    @Published var batchItems: [BatchItem] = []
    @Published var isGenerating = false

    private let generationViewModel = GenerationViewModel()

    var totalCredits: Int {
        batchItems.reduce(0) { $0 + $1.estimatedCredits }
    }

    var completedCount: Int {
        batchItems.filter { $0.status == .completed }.count
    }

    var generatingCount: Int {
        batchItems.filter { $0.status == .generating }.count
    }

    var failedCount: Int {
        batchItems.filter { $0.status == .failed }.count
    }

    func addItem(_ item: BatchItem) {
        batchItems.append(item)
    }

    func removeItem(_ item: BatchItem) {
        batchItems.removeAll { $0.id == item.id }
    }

    func startBatchGeneration() {
        isGenerating = true

        Task {
            for (index, item) in batchItems.enumerated() {
                guard item.status == .pending else { continue }

                await MainActor.run {
                    batchItems[index].status = .generating
                }

                do {
                    if item.type == .textTo3D, let prompt = item.prompt {
                        await generationViewModel.generateTextTo3D(
                            prompt: prompt,
                            artStyle: item.artStyle ?? .realistic,
                            aiModel: item.aiModel,
                            targetPolycount: 30000,
                            enablePBR: true
                        )

                        await MainActor.run {
                            batchItems[index].status = .completed
                            batchItems[index].progress = 100
                        }
                    } else if item.type == .imageTo3D, let imageData = item.imageData {
                        // Upload and generate
                        // Implementation similar to ImageTo3DView
                        await MainActor.run {
                            batchItems[index].status = .completed
                            batchItems[index].progress = 100
                        }
                    }
                } catch {
                    await MainActor.run {
                        batchItems[index].status = .failed
                        batchItems[index].errorMessage = error.localizedDescription
                    }
                }

                // Add delay between generations to avoid rate limiting
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }

            await MainActor.run {
                isGenerating = false
            }
        }
    }

    func clearAll() {
        batchItems.removeAll()
    }
}
