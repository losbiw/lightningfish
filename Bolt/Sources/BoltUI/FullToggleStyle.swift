// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

extension View {

    /// Full card-style toggle configuration
    public func fullToggleStyle() -> some View {
        toggleStyle(FullToggleStyle())
    }
}

struct FullToggleStyle: ToggleStyle {
    private let systemImage: String = "checkmark"

    // MARK: ToggleStyle
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .padding()
            Spacer()
            Circle()
                .stroke(
                    configuration.isOn ? .blue : .gray,
                    style: StrokeStyle(
                        lineWidth: 2
                    )
                )
                .fill(configuration.isOn ? .blue : .white)
                .padding(3)
                .frame(width: 50, height: 32)
                .overlay {
                    Image(systemName: systemImage)
                        .foregroundColor(.buttonFill)
                }
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isOn ? Color.buttonFillOn : .buttonFill)
                .stroke(configuration.isOn ? .blue : .gray, lineWidth: 1)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                configuration.isOn.toggle()
            }
        }
    }
}

#Preview("Full Toggle Style") {
    @Previewable @State var isOn: Bool = false

    Toggle(isOn: $isOn) {
        Text("Toggle Label")
    }
    .fullToggleStyle()
    .padding()
}

private extension Color {
    static var buttonFillOn: Self { Self(red: 19.0 / 255.0, green: 117.0 / 255.0, blue: 217.0 / 255.0).opacity(0.05) }
    static var buttonFill: Self { Self(.white, Self(red: 28.0 / 255.0, green: 28.0 / 255.0, blue: 30.0 / 255.0)) }
}
