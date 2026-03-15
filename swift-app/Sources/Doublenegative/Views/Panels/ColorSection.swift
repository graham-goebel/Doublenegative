import SwiftUI

struct ColorSection: View {
    @Bindable var editorVM: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            LabeledSlider(label: "Temperature", value: editorVM.binding(\.temperature), range: -100...100)
            LabeledSlider(label: "Tint",        value: editorVM.binding(\.tint),        range: -100...100)
            LabeledSlider(label: "Saturation",  value: editorVM.binding(\.saturation),  range: -100...100)
            LabeledSlider(label: "Vibrance",    value: editorVM.binding(\.vibrance),    range: -100...100)
        }
    }
}
