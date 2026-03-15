import SwiftUI

struct DetailSection: View {
    @Bindable var editorVM: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sharpening")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
            LabeledSlider(label: "Amount", value: editorVM.binding(\.sharpening),       range: 0...150,  defaultValue: 0,
                          format: { "\(Int($0))" })
            LabeledSlider(label: "Radius", value: editorVM.binding(\.sharpeningRadius), range: 0.5...3,  step: 0.1, defaultValue: 1,
                          format: { String(format: "%.1f", $0) })
            LabeledSlider(label: "Detail", value: editorVM.binding(\.sharpeningDetail), range: 0...100,  defaultValue: 25,
                          format: { "\(Int($0))" })

            Text("Noise Reduction")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
            LabeledSlider(label: "Luminance", value: editorVM.binding(\.noiseReduction),       range: 0...100, defaultValue: 0,
                          format: { "\(Int($0))" })
            LabeledSlider(label: "Detail",    value: editorVM.binding(\.noiseReductionDetail), range: 0...100, defaultValue: 50,
                          format: { "\(Int($0))" })
            LabeledSlider(label: "Color",     value: editorVM.binding(\.noiseReductionColor),  range: 0...100, defaultValue: 25,
                          format: { "\(Int($0))" })
        }
    }
}
