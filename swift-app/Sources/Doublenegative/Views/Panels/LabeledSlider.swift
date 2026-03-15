import SwiftUI

/// A slider with a label and live value readout.
/// Double-tap the value to reset to the default.
struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var defaultValue: Double = 0
    var format: (Double) -> String = { v in
        v == 0 ? "0" : (v > 0 ? "+\(Int(v))" : "\(Int(v))")
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(format(value))
                    .font(.caption.monospaced())
                    .foregroundStyle(value == defaultValue ? .tertiary : .orange)
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(duration: 0.2)) { value = defaultValue }
                    }
            }
            Slider(value: $value, in: range, step: step)
                .tint(.orange)
        }
        .padding(.vertical, 2)
    }
}
