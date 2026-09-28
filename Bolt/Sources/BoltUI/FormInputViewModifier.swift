// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

extension View {

    /// Format and label controls and text inputs in the Bolt style.
    public func formInput(_ label: LocalizedStringKey, isRequired: Bool = false, layout: FormInputLayout = .vertical) -> some View {
        modifier(FormInputViewModifier(label, isRequired: isRequired, layout: layout))
    }

    /// Disable text autocorrection and autocapitalization.
    public func autoFormattingDisabled() -> some View {
        autocorrectionDisabled()
            #if !os(macOS)
        .textInputAutocapitalization(.never)
            #endif
    }
}

public enum FormInputLayout: CaseIterable {
    case horizontal, vertical
}

struct FormInputViewModifier: ViewModifier {
    let label: LocalizedStringKey
    let layout: FormInputLayout
    let isRequired: Bool

    init(_ label: LocalizedStringKey, isRequired: Bool, layout: FormInputLayout) {
        self.label = label
        self.layout = layout
        self.isRequired = isRequired
    }

    // MARK: ViewModifier
    func body(content: Content) -> some View {
        switch layout {
        case .horizontal:
            HStack {
                FormInputLabel(label, isRequired: isRequired)
                Spacer()
                content
                    .textFieldStyle(.automatic)
                    .labelsHidden()
            }
        case .vertical:
            VStack(alignment: .leading) {
                FormInputLabel(label, isRequired: isRequired)
                Divider()
                content
                    .textFieldStyle(.automatic)
                    .labelsHidden()
            }
        }
    }
}

#Preview("Form Input View Modifier") {
    @Previewable @State var text: String = ""
    @Previewable @State var isOn: Bool = false

    TextField("Enter text…", text: $text)
        .formInput("Vertical Layout (Default)", isRequired: true)
        .padding()
    Toggle("Toggle", isOn: $isOn)
        .formInput("Horizontal Layout", isRequired: true, layout: .horizontal)
        .padding()
}

private struct FormInputLabel: View {
    let label: LocalizedStringKey
    let isRequired: Bool

    init(_ label: LocalizedStringKey, isRequired: Bool = false) {
        self.label = label
        self.isRequired = isRequired
    }

    // MARK: View
    var body: some View {
        HStack {
            Text(label)
                .textStyle(.subhead)
            if isRequired {
                Label("", systemImage: "burst.fill")
                    .labelStyle(.iconOnly)
                    .textStyle(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview("Form Input Label") {
    FormInputLabel("Form Input Label (Required)", isRequired: true)
    FormInputLabel("Form Input Label")
}
