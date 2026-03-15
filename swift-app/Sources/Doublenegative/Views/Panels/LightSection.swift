import SwiftUI

struct LightSection: View {
    @Bindable var editorVM: EditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            LabeledSlider(label: "Exposure",   value: editorVM.binding(\.exposure),   range: -5...5,     step: 0.05,
                          format: { String(format: "%+.2f", $0) })
            LabeledSlider(label: "Contrast",   value: editorVM.binding(\.contrast),   range: -100...100)
            LabeledSlider(label: "Highlights", value: editorVM.binding(\.highlights), range: -100...100)
            LabeledSlider(label: "Shadows",    value: editorVM.binding(\.shadows),    range: -100...100)
            LabeledSlider(label: "Whites",     value: editorVM.binding(\.whites),     range: -100...100)
            LabeledSlider(label: "Blacks",     value: editorVM.binding(\.blacks),     range: -100...100)
        }
    }
}
