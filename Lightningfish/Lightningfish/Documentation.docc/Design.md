# App Design

Technical overview of project architecture

## Project Structure

In the context of Thunderbird for iOS (Tfi), "project" means literally an [Xcode project file.](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app) In this case we're using a [workspace](https://developer.apple.com/documentation/xcode/projects-and-workspaces) to develop Tfi as a thin Xcode project that depends on libraries organized into local packages.

### Thunderbird Project

`Thunderbird.xcodeproj` starts with a single SwiftUI app target, `Thunderbird`. Additional targets will be added to support things like widgets, rich notifications and/or watchOS extensions.

#### Documentation

The Xcode project includes a [documentation catalog](https://developer.apple.com/documentation/xcode/adding-supplemental-content-to-a-documentation-catalog) for publishing additional articles (like this one) alongside the generated [DocC](https://www.swift.org/documentation/docc) documentation.

#### Localization

Tfi plans to launch with language support comparable to [Thunderbird for Android](https://github.com/thunderbird/thunderbird-android) (TfA) by using the same [Weblate translations](hosted.weblate.org/projects/tb-android), published as `Localizable.strings`.

User-facing string localization is accomplished using [`LocalizedStringKey`](https://developer.apple.com/documentation/swiftui/localizedstringkey) in SwiftUI.

<doc:Localization> describes how we sync changes from the shared Weblate translations project.

### Feature Package

Features are the backend functionality for the app, mostly a kit of standard, modular mail client components. 

#### `Autoconfiguration`

 [Thunderbird Autoconfiguration](https://www.bucksch.org/1/projects/thunderbird/autoconfiguration), often just "autoconfig," is an XML syndication format where email service providers advertise public mail server settings. Given an email address or host name, `Autoconfiguration` library uses a combination of the [Public Suffix List](https://publicsuffix.org), [MX records](https://en.wikipedia.org/wiki/MX_record) and [ISPDB](https://github.com/thunderbird/autoconfig) to find the correct mail server and OAuth settings.

#### `IMAP` and `SMTP`

Almost every mail server and mail provider support receiving and sending email with [Internet Message Access Protocol](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol) (IMAP) and [Simple Mail Transfer Protocol](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol) (SMTP).

Separate, complementary libraries handle email retrieval and sending for all mail accounts with all providers. Both client implementations use [SwiftNIO](https://opensource.apple.com/projects/swiftnio) for [TCP](https://en.wikipedia.org/wiki/Transmission_Control_Protocol) communication with mail servers.

#### `JMAP`

 [JSON Meta Application Protocol](https://jmap.io) (JMAP)) is a modern, API-based approach to email that uses standard HTTP requests and responses with JSON serialization for transit. `JMAP` feature library is a client implementation of both [JMAP core](https://jmap.io/spec/rfc8620) and [JMAP mail](https://jmap.io/spec/rfc8621) protocols, intended to replace IMAP/SMTP for mail accounts with provider support for JMAP.

### Bolt Package

[Bolt](https://bolt.thunderbird.net) is Thunderbird's design system. `Bolt` package implements the design system as SwiftUI views, colors and type

#### `BoltUI`

Vend SwiftUI design system components.

#### `Editor`

Read and compose messages in [WKWebView.](https://developer.apple.com/documentation/webkit/wkwebview)

### Core Package

App- and system-level services belong to `Core`.

#### `Weblate`

Command-line interface for syncing language translation changes with Weblate project repository

-----

`BoltUI` is unusual, because it depends on SwiftUI and implements views specifically for iOS, macOS and watchOS platforms. Generally, libraries follow these conventions:

* Corresponding test target containing unit test coverage for logic and anything computed; use [Swift Testing.](https://developer.apple.com/documentation/testing)
* Configurable programming interfaces; no user interface, no localization or user-facing strings
* Explicit interfaces and responsibility, encapsulated for being moved into separate repositories and reused in other apps

### Additional Workspace Components

* `docs` is the designated location for publishing web version of project documentation to [GitHub Pages.](https://pages.github.com)
* `Thunderbird.xctestplan` aggregates tests from both app project and packaged libraries.
