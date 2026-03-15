import SwiftUI
import SwiftData

struct EditorView: View {
    @Bindable var editorVM: EditorViewModel
    @Bindable var libraryVM: LibraryViewModel
    @Binding var mode: AppMode
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImageItem.importedAt, order: .reverse) private var allImages: [ImageItem]

    var body: some View {
        VStack(spacing: 0) {
            // Main canvas + right panel
            HStack(spacing: 0) {
                ImageCanvas(editorVM: editorVM)

                Divider()

                EditPanel(editorVM: editorVM)
                    .frame(width: 260)
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Film strip
            FilmStrip(editorVM: editorVM, images: allImages)
                .frame(height: 80)
        }
        .navigationTitle(editorVM.activeImage?.filename ?? "")
        #if os(macOS)
        .navigationSubtitle(exifSummary)
        #endif
        .toolbar { editorToolbar }
    }

    private var exifSummary: String {
        guard let img = editorVM.activeImage else { return "" }
        var parts: [String] = []
        if let iso = img.iso           { parts.append("ISO \(iso)") }
        if let ap  = img.aperture      { parts.append("f/\(ap)") }
        if let ss  = img.shutterSpeed  { parts.append(ss) }
        if let fl  = img.focalLength   { parts.append("\(Int(fl))mm") }
        return parts.joined(separator: "  ·  ")
    }

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .secondaryAction) {
            Button("Undo", systemImage: "arrow.uturn.backward") { editorVM.undo() }
                .disabled(!editorVM.canUndo)
                .keyboardShortcut("z")

            Button("Redo", systemImage: "arrow.uturn.forward") { editorVM.redo() }
                .disabled(!editorVM.canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])

            Divider()

            Button("Reset", systemImage: "arrow.counterclockwise") { editorVM.reset() }
                .disabled(!editorVM.isDirty)
        }

        ToolbarItem(placement: .primaryAction) {
            ExportButton(editorVM: editorVM)
        }
    }
}

// MARK: - Export button with share sheet / save panel

private struct ExportButton: View {
    @Bindable var editorVM: EditorViewModel
    @State private var isExporting = false
    @State private var exportedData: Data?
    #if os(macOS)
    @State private var showSavePanel = false
    #endif

    var body: some View {
        Button("Export", systemImage: "square.and.arrow.up") {
            Task { await export() }
        }
        #if os(iOS)
        .sheet(isPresented: $isExporting) {
            if let data = exportedData {
                ShareSheet(items: [data])
            }
        }
        #endif
    }

    private func export() async {
        let data = await editorVM.exportJPEG()
        guard let data else { return }
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.jpeg]
        panel.nameFieldStringValue = "\(editorVM.activeImage?.filename.deletingPathExtension ?? "export")_edited.jpg"
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
        #else
        exportedData = data
        isExporting  = true
        #endif
    }
}

#if os(iOS)
import UIKit
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
#endif

private extension String {
    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }
}
