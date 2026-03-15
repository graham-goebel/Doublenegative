import SwiftUI

struct FilmStrip: View {
    @Bindable var editorVM: EditorViewModel
    let images: [ImageItem]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(images) { image in
                        FilmStripCell(
                            image: image,
                            isActive: editorVM.activeImageID == image.id
                        )
                        .id(image.id)
                        .onTapGesture { editorVM.load(image) }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .background(.black)
            .onChange(of: editorVM.activeImageID) { _, id in
                if let id { withAnimation { proxy.scrollTo(id, anchor: .center) } }
            }
        }
    }
}

private struct FilmStripCell: View {
    let image: ImageItem
    let isActive: Bool
    @State private var thumbnail: CGImage?

    var body: some View {
        thumbnailView
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(isActive ? .orange : .clear, lineWidth: 2)
            )
            .opacity(isActive ? 1 : 0.6)
            .task {
                guard thumbnail == nil, let url = image.resolveURL() else { return }
                thumbnail = await url.withSecurityScope {
                    await ImageProcessor.shared.renderThumbnail(from: url, maxSize: 128)
                }
            }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let cg = thumbnail {
            Image(decorative: cg, scale: 1)
                .resizable()
                .scaledToFill()
        } else {
            Color.gray.opacity(0.3)
                .overlay { Image(systemName: "photo").foregroundStyle(.secondary) }
        }
    }
}
