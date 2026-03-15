import SwiftUI
import SwiftData

@Observable
final class EditorViewModel {
    private(set) var activeImage: ImageItem?
    var params: EditParams = .default
    private(set) var savedParams: EditParams = .default
    private(set) var previewImage: CGImage?
    private(set) var thumbnailImage: CGImage?
    private(set) var isRendering = false

    private var history: [EditParams] = [.default]
    private var historyIndex = 0
    private var renderTask: Task<Void, Never>?

    private let processor = ImageProcessor.shared

    deinit { renderTask?.cancel() }

    // MARK: - Derived state

    var isDirty: Bool     { params != savedParams }
    var canUndo: Bool     { historyIndex > 0 }
    var canRedo: Bool     { historyIndex < history.count - 1 }
    var activeImageID: UUID? { activeImage?.id }

    // MARK: - Load

    func load(_ image: ImageItem) {
        guard image.id != activeImage?.id else { return }
        activeImage = image
        let p = image.editParams
        params = p
        savedParams = p
        history = [p]
        historyIndex = 0
        previewImage = nil

        // Load thumbnail immediately, then full preview
        Task { await loadThumbnail() }
        scheduleRender(debounce: 0)
    }

    // MARK: - Parameter updates

    func set<V>(_ keyPath: WritableKeyPath<EditParams, V>, to value: V) {
        params[keyPath: keyPath] = value
        pushHistory()
        scheduleRender()
    }

    /// Returns a `Binding` that reads from `params` and writes through `set(_:to:)` for undo support.
    func binding<V>(_ keyPath: WritableKeyPath<EditParams, V>) -> Binding<V> {
        Binding(
            get: { self.params[keyPath: keyPath] },
            set: { self.set(keyPath, to: $0) }
        )
    }

    func applyRecipe(_ recipe: Recipe) {
        params = recipe.params
        pushHistory()
        scheduleRender(debounce: 0)
    }

    func reset() {
        params = .default
        pushHistory()
        scheduleRender(debounce: 0)
    }

    func undo() {
        guard canUndo else { return }
        historyIndex -= 1
        params = history[historyIndex]
        scheduleRender(debounce: 0)
    }

    func redo() {
        guard canRedo else { return }
        historyIndex += 1
        params = history[historyIndex]
        scheduleRender(debounce: 0)
    }

    // MARK: - Save / Export

    @MainActor
    func save(context: ModelContext) {
        guard let image = activeImage else { return }
        image.editParams = params
        savedParams = params
        try? context.save()
    }

    func exportJPEG() async -> Data? {
        guard let url = resolvedURL() else { return nil }
        return await url.withSecurityScope {
            await processor.exportJPEG(from: url, params: params)
        }
    }

    // MARK: - Private

    private func pushHistory() {
        // Truncate any redo history then append
        history = Array(history.prefix(historyIndex + 1))
        history.append(params)
        if history.count > 50 { history.removeFirst() }
        historyIndex = history.count - 1
    }

    private func scheduleRender(debounce milliseconds: Int = 150) {
        renderTask?.cancel()
        renderTask = Task { [weak self] in
            if milliseconds > 0 {
                try? await Task.sleep(for: .milliseconds(milliseconds))
            }
            guard let self, !Task.isCancelled else { return }
            await self.renderPreview()
        }
    }

    @MainActor
    private func renderPreview() async {
        guard let url = resolvedURL() else { return }
        isRendering = true
        let capturedParams = params
        let result = await url.withSecurityScope {
            await processor.renderPreview(from: url, params: capturedParams)
        }
        // Only apply if params haven't changed while we were rendering
        if params == capturedParams {
            previewImage = result
        }
        isRendering = false
    }

    @MainActor
    private func loadThumbnail() async {
        guard let url = resolvedURL() else { return }
        thumbnailImage = await url.withSecurityScope {
            await processor.renderThumbnail(from: url)
        }
    }

    private func resolvedURL() -> URL? {
        activeImage?.resolveURL()
    }
}
