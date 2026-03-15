import SwiftUI
import SwiftData

struct RecipePanel: View {
    @Bindable var editorVM: EditorViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var showSaveSheet = false
    @State private var newRecipeName = ""
    @State private var applyFeedback: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Save current edits as recipe
            Button("Save as Recipe…", systemImage: "plus.square") {
                newRecipeName = ""
                showSaveSheet = true
            }
            .font(.caption)

            if !recipes.isEmpty {
                Divider()
                ForEach(recipes) { recipe in
                    RecipeRow(recipe: recipe) {
                        editorVM.applyRecipe(recipe)
                    } onDelete: {
                        modelContext.delete(recipe)
                        try? modelContext.save()
                    }
                }
            }

            if let feedback = applyFeedback {
                Text(feedback)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            saveSheet
        }
    }

    private var saveSheet: some View {
        NavigationStack {
            Form {
                TextField("Recipe name", text: $newRecipeName)
            }
            .navigationTitle("Save Recipe")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSaveSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRecipe() }
                        .disabled(newRecipeName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(180)])
    }

    private func saveRecipe() {
        let name = newRecipeName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let recipe = Recipe(
            name: name,
            params: editorVM.params,
            sourceImageId: editorVM.activeImageID
        )
        modelContext.insert(recipe)
        try? modelContext.save()
        showSaveSheet = false
    }
}

private struct RecipeRow: View {
    let recipe: Recipe
    let onApply: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                    .font(.caption)
                Text(recipe.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button("Apply", action: onApply)
                .font(.caption)
                .buttonStyle(.borderless)
                .foregroundStyle(.orange)
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
