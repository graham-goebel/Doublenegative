import SwiftUI
import SwiftData

struct EditPanel: View {
    @Bindable var editorVM: EditorViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HistogramView(image: editorVM.previewImage)
                    .frame(height: 64)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                Divider().padding(.vertical, 6)

                Group {
                    DisclosureGroup("Light") {
                        LightSection(editorVM: editorVM)
                    }
                    Divider()
                    DisclosureGroup("Color") {
                        ColorSection(editorVM: editorVM)
                    }
                    Divider()
                    DisclosureGroup("Detail") {
                        DetailSection(editorVM: editorVM)
                    }
                    Divider()
                    DisclosureGroup("Recipes") {
                        RecipePanel(editorVM: editorVM)
                    }
                }
                .padding(.horizontal, 12)
                .disclosureGroupStyle(PanelDisclosureStyle())
            }
        }
        .background(.background.secondary)
    }
}

// MARK: - Minimal disclosure style

private struct PanelDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack {
                    configuration.label
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                        .textCase(.uppercase)
                    Spacer()
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if configuration.isExpanded {
                configuration.content
                    .padding(.bottom, 8)
            }
        }
    }
}
