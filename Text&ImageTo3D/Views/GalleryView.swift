//
//  GalleryView.swift
//  MeshyApp
//
//  Gallery view for browsing 3D models
//

import SwiftUI

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @State private var selectedModel: Model3D?
    @State private var showARView = false
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case recent = "Recent"
    }

    var filteredModels: [Model3D] {
        var models = filterOption == .favorites ? viewModel.favoriteModels : viewModel.models

        if !searchText.isEmpty {
            models = models.filter { model in
                model.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return models
    }

    var body: some View {
        NavigationView {
            ZStack {
                NeonTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(NeonTheme.secondaryText)

                        TextField("Search models...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(NeonTheme.cardBackground)
                    .cornerRadius(12)
                    .padding()

                    // Filter options
                    HStack(spacing: 15) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            FilterButton(
                                title: option.rawValue,
                                isSelected: filterOption == option
                            ) {
                                filterOption = option
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)

                    // Models grid
                    if filteredModels.isEmpty {
                        EmptyGalleryView()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                ForEach(filteredModels) { model in
                                    ModelCard(model: model) {
                                        selectedModel = model
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedModel) { model in
                if let index = viewModel.models.firstIndex(where: { $0.id == model.id }) {
                    ModelDetailView(model: $viewModel.models[index], viewModel: viewModel)
                } else {
                    // fallback if model only exists in favorites
                    if let index = viewModel.favoriteModels.firstIndex(where: { $0.id == model.id }) {
                        ModelDetailView(model: $viewModel.favoriteModels[index], viewModel: viewModel)
                    }
                }
            }


            .task {
                await viewModel.loadUserModels()
                await viewModel.loadFavoriteModels()
            }
            .refreshable {
                await viewModel.loadUserModels()
                await viewModel.loadFavoriteModels()
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : NeonTheme.secondaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    isSelected ? NeonTheme.primaryGradient : LinearGradient(colors: [NeonTheme.cardBackground], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(20)
        }
    }
}

struct ModelCard: View {
    let model: Model3D
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Thumbnail
                AsyncImage(url: URL(string: model.thumbnailURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            NeonTheme.darkCard
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: NeonTheme.neonPurple))
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            NeonTheme.darkCard
                            Image(systemName: "cube.fill")
                                .font(.largeTitle)
                                .foregroundStyle(NeonTheme.primaryGradient)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)

                // Info
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: model.isFavorite ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundColor(model.isFavorite ? NeonTheme.neonPink : NeonTheme.secondaryText)

                        Spacer()

                        if model.isDownloaded {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.caption)
                                .foregroundColor(NeonTheme.neonCyan)
                        }
                    }

                    Text(model.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(NeonTheme.secondaryText)
                }
                .padding(.horizontal, 5)
            }
            .padding(10)
            .neonCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyGalleryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 80))
                .foregroundStyle(NeonTheme.primaryGradient)
                .neonGlow(color: NeonTheme.neonPurple)

            Text("No models yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Start creating 3D models from the Create tab")
                .font(.subheadline)
                .foregroundColor(NeonTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModelDetailView: View {
    @Binding var model: Model3D
    @ObservedObject var viewModel: GalleryViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showARView = false
    @State private var showExportOptions = false
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                NeonTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Model preview
                        AsyncImage(url: URL(string: model.thumbnailURL ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .cornerRadius(20)
                                    .neonGlow(color: NeonTheme.neonPurple, radius: 20)
                            default:
                                Rectangle()
                                    .fill(NeonTheme.cardBackground)
                                    .frame(height: 300)
                                    .cornerRadius(20)
                            }
                        }
                        .padding()

                        // Actions
                        VStack(spacing: 15) {
                            Button(action: { showARView = true }) {
                                Label("View in AR", systemImage: "arkit")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(NeonButtonStyle())

                            HStack(spacing: 15) {
                                Button(action: { toggleFavorite() }) {
                                    HStack {
                                        Image(systemName: model.isFavorite ? "heart.fill" : "heart")
                                        Text(model.isFavorite ? "Unfavorite" : "Favorite")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(NeonButtonStyle(gradient: NeonTheme.accentGradient, glowColor: NeonTheme.neonPink))

                                Button(action: { showExportOptions = true }) {
                                    Label("Export", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(NeonButtonStyle(gradient: NeonTheme.glowGradient, glowColor: NeonTheme.neonCyan))
                            }
                        }
                        .padding(.horizontal)

                        // Model info
                        VStack(alignment: .leading, spacing: 15) {
                            InfoRow(label: "Created", value: model.createdAt.formatted(date: .long, time: .shortened))
                            InfoRow(label: "Format", value: "GLB, FBX, OBJ, USDZ")
                            InfoRow(label: "PBR Textures", value: model.hasPBR ? "Yes" : "No")

                            if let polycount = model.polycount {
                                InfoRow(label: "Polycount", value: "\(polycount)")
                            }
                        }
                        .padding()
                        .neonCard()
                        .padding(.horizontal)

                        // Delete button
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete Model", systemImage: "trash")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
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
            }
            .fullScreenCover(isPresented: $showARView) {
                AdvancedARView(model: model)
            }
            .confirmationDialog("Export Model", isPresented: $showExportOptions) {

                ForEach(ModelFormat.allCases, id: \.self) { format in
                    Button(format.displayName) {
                        exportModel(format: format)
                    }
                }
            }
            .alert("Delete Model", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteModel()
                }
            } message: {
                Text("Are you sure you want to delete this model? This action cannot be undone.")
            }
        }
    }

    private func toggleFavorite() {
        print("🔵 DetailView: Toggle favorite tapped, current state: \(model.isFavorite)")
        
        // Update UI immediately (optimistic update) for instant feedback
        model.isFavorite.toggle()
        print("✅ DetailView: Local UI updated to: \(model.isFavorite)")
        
        // Then sync with Firestore in background
        Task {
            do {
                // Pass the model with the NEW state
                await viewModel.toggleFavorite(model: model)
                print("✅ DetailView: Firestore synced")
                
                // Reload to ensure consistency
                await viewModel.loadUserModels()
                await viewModel.loadFavoriteModels()
            } catch {
                print("❌ DetailView: Failed to sync favorite: \(error)")
                // Revert on error
                await MainActor.run {
                    model.isFavorite.toggle()
                }
            }
        }
    }

    private func exportModel(format: ModelFormat) {


        Task {
            if let url = await viewModel.downloadModel(model: model, format: format) {
                // Share the file
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    
                    var topController = rootVC
                    while let presentedVC = topController.presentedViewController {
                        topController = presentedVC
                    }
                    
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = topController.view
                        popover.sourceRect = CGRect(x: topController.view.bounds.midX,
                                                   y: topController.view.bounds.midY,
                                                   width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                    topController.present(activityVC, animated: true)
                }
            }
        }
    }

    private func deleteModel() {
        Task {
            await viewModel.deleteModel(model: model)
            dismiss()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(NeonTheme.secondaryText)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
}
