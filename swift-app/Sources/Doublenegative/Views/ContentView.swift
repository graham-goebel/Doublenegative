import SwiftUI
import SwiftData

enum AppMode { case library, develop }

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var libraryVM = LibraryViewModel()
    @State private var editorVM  = EditorViewModel()
    @State private var mode: AppMode = .library
    @State private var showImporter = false

    var body: some View {
        NavigationSplitView {
            CollectionSidebar(libraryVM: libraryVM)
        } content: {
            LibraryView(libraryVM: libraryVM, editorVM: editorVM, mode: $mode)
                .navigationTitle("Library")
        } detail: {
            switch mode {
            case .library:
                ContentUnavailableView(
                    "Select a photo",
                    systemImage: "photo.on.rectangle",
                    description: Text("Double-tap a photo to edit it")
                )
            case .develop:
                if editorVM.activeImage != nil {
                    EditorView(editorVM: editorVM, libraryVM: libraryVM, mode: $mode)
                } else {
                    ContentUnavailableView("No photo selected", systemImage: "photo")
                }
            }
        }
        .toolbar { toolbarContent }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: LibraryViewModel.acceptedTypes,
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                Task { await libraryVM.importImages(urls, into: modelContext) }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Mode switcher — centre on macOS, leading on iPad
        ToolbarItem(placement: .principal) {
            Picker("Mode", selection: $mode) {
                Text("Library").tag(AppMode.library)
                Text("Develop").tag(AppMode.develop)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .disabled(mode == .develop && editorVM.activeImage == nil)
        }

        ToolbarItem(placement: .primaryAction) {
            Button("Import", systemImage: "plus") { showImporter = true }
        }

        // Save button in Develop mode
        if mode == .develop && editorVM.isDirty {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { editorVM.save(context: modelContext) }
                    .keyboardShortcut("s")
            }
        }
    }
}
