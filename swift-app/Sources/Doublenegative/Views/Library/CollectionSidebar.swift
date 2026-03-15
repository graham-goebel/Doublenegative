import SwiftUI
import SwiftData

struct CollectionSidebar: View {
    @Bindable var libraryVM: LibraryViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PhotoCollection.createdAt) private var collections: [PhotoCollection]
    @State private var newName = ""
    @State private var isCreating = false
    @State private var renaming: PhotoCollection?

    var body: some View {
        List(selection: $libraryVM.activeCollectionID) {
            // All Photos
            Label("All Photos", systemImage: "photo.stack")
                .tag(Optional<UUID>.none)

            Section("Collections") {
                ForEach(collections) { col in
                    CollectionRow(collection: col, renaming: $renaming)
                        .tag(Optional(col.id))
                        .contextMenu {
                            Button("Rename") { renaming = col }
                            Button("Delete", role: .destructive) {
                                libraryVM.deleteCollection(col, context: modelContext)
                            }
                        }
                }

                if isCreating {
                    TextField("Name", text: $newName)
                        .onSubmit { createCollection() }
                        .onExitCommand { isCreating = false }
                }
            }
        }
        .navigationTitle("Doublenegative")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        #endif
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("New Collection", systemImage: "folder.badge.plus") {
                    isCreating = true
                    newName = ""
                }
            }
        }
    }

    private func createCollection() {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        libraryVM.createCollection(named: newName, context: modelContext)
        isCreating = false
        newName = ""
    }
}

private struct CollectionRow: View {
    let collection: PhotoCollection
    @Binding var renaming: PhotoCollection?
    @Environment(\.modelContext) private var modelContext
    @State private var editName = ""

    var body: some View {
        if renaming?.id == collection.id {
            TextField("Name", text: $editName)
                .onAppear { editName = collection.name }
                .onSubmit { commitRename() }
                .onExitCommand { renaming = nil }
        } else {
            Label(collection.name, systemImage: "folder")
                .badge(collection.imageCount)
        }
    }

    private func commitRename() {
        let name = editName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty { collection.name = name }
        try? modelContext.save()
        renaming = nil
    }
}
