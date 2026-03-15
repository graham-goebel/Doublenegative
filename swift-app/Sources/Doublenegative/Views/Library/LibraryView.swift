import SwiftUI
import SwiftData

struct LibraryView: View {
    @Bindable var libraryVM: LibraryViewModel
    @Bindable var editorVM: EditorViewModel
    @Binding var mode: AppMode
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ImageItem.importedAt, order: .reverse) private var allImages: [ImageItem]

    private var images: [ImageItem] {
        guard let colID = libraryVM.activeCollectionID else { return allImages }
        return allImages.filter { img in img.collections.contains { $0.id == colID } }
    }

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 4)]

    var body: some View {
        ScrollView {
            if images.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(images) { image in
                        ThumbnailCell(
                            image: image,
                            isSelected: libraryVM.selectedImageIDs.contains(image.id)
                        )
                        .onTapGesture {
                            libraryVM.toggleSelection(image, multiSelect: false)
                        }
                        .onTapGesture(count: 2) {
                            openInDevelop(image)
                        }
                        #if os(macOS)
                        .simultaneousGesture(
                            TapGesture().modifiers(.command).onEnded {
                                libraryVM.toggleSelection(image, multiSelect: true)
                            }
                        )
                        #endif
                        .contextMenu { contextMenu(for: image) }
                    }
                }
                .padding(8)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            Task { await libraryVM.importImages(urls, into: modelContext) }
            return true
        }
        .overlay(alignment: .bottom) {
            if libraryVM.isImporting {
                importingBanner
            }
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        ContentUnavailableView(
            "No Photos",
            systemImage: "photo.badge.plus",
            description: Text("Tap Import or drag photos here")
        )
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var importingBanner: some View {
        Label("Importing…", systemImage: "arrow.down.circle")
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .padding(.bottom, 16)
    }

    @ViewBuilder
    private func contextMenu(for image: ImageItem) -> some View {
        Button("Edit") { openInDevelop(image) }
        Divider()
        Button("Delete", role: .destructive) {
            libraryVM.deleteImages([image], context: modelContext)
        }
    }

    // MARK: - Actions

    private func openInDevelop(_ image: ImageItem) {
        libraryVM.selectedImageIDs = [image.id]
        editorVM.load(image)
        mode = .develop
    }
}

// MARK: - Thumbnail cell

struct ThumbnailCell: View {
    let image: ImageItem
    let isSelected: Bool
    @State private var thumbnail: CGImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailImage
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipped()

            if image.isEdited {
                Circle()
                    .fill(.orange)
                    .frame(width: 8, height: 8)
                    .padding(5)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(isSelected ? .orange : .clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .task {
            guard thumbnail == nil, let url = image.resolveURL() else { return }
            thumbnail = await url.withSecurityScope {
                await ImageProcessor.shared.renderThumbnail(from: url)
            }
        }
    }

    private var thumbnailImage: Image {
        if let cg = thumbnail {
            return Image(decorative: cg, scale: 1)
        }
        return Image(systemName: "photo")
    }
}
