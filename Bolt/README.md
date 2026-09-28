# Bolt Design System

[Bolt](https://bolt.thunderbird.net) is Thunderbird's design system.

`Bolt` package implements [Bolt Design System](https://github.com/thunderbird/bolt-design-system) components as [SwiftUI](https://developer.apple.com/swiftui) views, colors, fonts and symbols.

* [`BoltUI`](#boltui)

## `BoltUI` <a name="boltui"></a>

### Accessibility

Bolt components implemented in SwiftUI support the Apple platforms' built-in APIs for low- and no-vision users:

* [VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover)
* [Increased Contrast](https://developer.apple.com/documentation/swiftui/colorschemecontrast)
* [Dynamic Type](https://developer.apple.com/videos/play/wwdc2024/10074)

### Localization

Bolt components that display user content and/or require interface labels, like button text, expect both to be already localized. All interface labels are configurable by main app, which is responsible for localization.
