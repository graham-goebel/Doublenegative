import SwiftUI

struct ImageCanvas: View {
    @Bindable var editorVM: EditorViewModel
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1
    @GestureState private var gestureOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                previewContent
                    .scaleEffect(scale * gestureScale)
                    .offset(
                        x: offset.width  + gestureOffset.width,
                        y: offset.height + gestureOffset.height
                    )
                    .gesture(magnification.simultaneously(with: drag))
                    .onTapGesture(count: 2) { resetZoom() }

                if editorVM.isRendering {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(12)
                }
            }
        }
    }

    // MARK: - Preview content

    @ViewBuilder
    private var previewContent: some View {
        if let preview = editorVM.previewImage {
            Image(decorative: preview, scale: 1)
                .resizable()
                .scaledToFit()
        } else if let thumb = editorVM.thumbnailImage {
            Image(decorative: thumb, scale: 1)
                .resizable()
                .scaledToFit()
                .blur(radius: 0)           // show thumb while full preview loads
                .overlay { ProgressView() }
        } else {
            ProgressView("Loading…").tint(.white)
        }
    }

    // MARK: - Gestures

    private var magnification: some Gesture {
        MagnifyGesture()
            .updating($gestureScale) { value, state, _ in state = value.magnification }
            .onEnded { value in
                scale = max(0.5, min(8, scale * value.magnification))
                if scale <= 1 { resetZoom() }
            }
    }

    private var drag: some Gesture {
        DragGesture()
            .updating($gestureOffset) { value, state, _ in state = value.translation }
            .onEnded { value in
                offset.width  += value.translation.width
                offset.height += value.translation.height
            }
    }

    private func resetZoom() {
        withAnimation(.spring) {
            scale = 1
            offset = .zero
        }
    }
}
