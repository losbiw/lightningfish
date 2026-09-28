# Contributing to Thunderbird iOS

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Contribution Guidelines](#contributing-to-thunderbird-ios)
- [AI Contributions](#ai-contributions)
- [License](#license)

## Overview
Welcome!

At the moment we are not accepting community contributions as we prepare the app for initial release. Check out the information below to understand contribution guidelines once we open up to the community.

We're writing a totally new version of Thunderbird for iOS, and we're building it as a new [Swift](https://developer.apple.com/swift) and [SwiftUI](https://developer.apple.com/swiftui) app.

Mostly from scratch, because we looked everywhere, but didn't find many open source projects or libraries that suited our needs -- either on Apple platforms or on adjacent, compatible platforms. So, we started from Swift [NIO](https://opensource.apple.com/projects/swiftnio) and [Foundation](https://developer.apple.com/documentation/foundation), and we wrote our own suite of core libraries, with protocol implementations for [IMAP](https://imap.org/imap-protocol), SMTP and [JMAP.](https://jmap.io) We included account autoconfiguration, persistence and secure keychain storage for passwords and tokens. We even wrote our own [MIME](https://datatracker.ietf.org/doc/html/rfc6838) encoding and decoding.

We wrote the modern email engine that iOS Thunderbird needed… Most of it. Maybe you can help with what's left to implement:

* [IMAP mailbox append](https://github.com/thunderbird/thunderbird-ios/issues/238)
* [IMAP mailbox search and filters](https://github.com/thunderbird/thunderbird-ios/issues/219)
* [URLSession task(s) for JMAP attachments](https://github.com/thunderbird/thunderbird-ios/issues/68)
* [URLSession task(s) for JMAP submission](https://github.com/thunderbird/thunderbird-ios/issues/74)

And we're still missing a core library for [OAuth 2](https://datatracker.ietf.org/doc/html/rfc6749) support, which is planned but not started. (Until OAuth support is implemented, email accounts have to authenticate with a password, app-password or bearer token.)

SwiftUI work on the main app has started, but we're still very early in the design process and not ready for contributions yet. Join the [public TestFlight](https://testflight.apple.com/join/ER3hRBSz) to see just how early in the process we are, and keep tabs on the project. We'll be sure to let everyone know when we open to contribution.

The core team's day to day activities are tracked in our [sprint board](https://github.com/orgs/thunderbird/projects/23/views/1). The board and our roadmap will be updated to align with our roadmap as we develop. 

## Getting Started

Code isn't the only way to contribute:

* Translate iOS and Android Thunderbird into the languages you speak from the [Weblate project web site.](https://hosted.weblate.org/projects/tb-android)
* Report bugs or propose features by [opening a new issue on GitHub.](https://github.com/thunderbird/thunderbird-ios/issues) Please check the issues for duplicates before submitting.
* Thunderbird is supported by financial contributions from users like you. [Make a financial contribution today](https://www.thunderbird.net/donate/mobile/?form=tfa)!
* We have a number of [other contribution](https://blog.thunderbird.net/2024/09/contribute-to-thunderbird-for-android/) opportunities available.
* Make sure to check out the [Mozilla Community Participation Guidelines](https://www.mozilla.org/about/governance/policies/participation/)

<!-- TODO: Issue template(s) for bug report and feature request -->

To contribute code, you need a free [GitHub](https://github.com) account and access to a Mac running the latest stable [Xcode](https://developer.apple.com/xcode), Apple's IDE for for making apps.

Fork the [Thunderbird iOS repository on GitHub] and choose the preset configuration for contributing to the main project. Then, clone your fork, open `Thunderbird.xcworkspace` in Xcode, wait for packages to resolve, build and run.

Thunderbird iOS project is boring by design. We won't accept any changes to the project that introduce additional build tooling or project configuration steps external to Xcode, because we want to keep contributing as reasonable and accessible to the next contributor.

<!-- TODO: Pull request template -->

In the spirit of making this project accessible to as many potential contributors as possible, we'll take contributions as they come. If you prefer directions and approvals up front, before you write a line of code, [open a new issue on GitHub](https://github.com/thunderbird/thunderbird-ios/issues) and ask, or describe what you want to do. Or send us the pull request as both question and answer, and we'll figure it out.

## AI Contributions

AI contributions to open source projects is a controversial and complicated topic. We are working on guidelines and documentation for how we as a team are handling these contributions. For the moment, please indicate if and how AI was used in a contribution. If we suspect a contribution is AI generated with no human contribution we may reject it for security reasons. Keep an eye out for more detailed guidelines.


## Style and Conventions

Thunderbird iOS project is very lightly linted using the [swift-format tool](https://github.com/swiftlang/swift-format) that is bundled with Xcode and used internally by [SourceKit LSP.](https://github.com/swiftlang/sourcekit-lsp) Linter enforcement is concerned exclusively with legibility affordances like:

* `GroupNumericLiterals` requires inserting underscores as thousands separators in numeric literals, e.g., `1_000_000`.
* `TypeNamesShouldBeCapitalized` preserves reasonability of type signatures.

Please use conventional Swift code style when contributing, but our main concern is keeping it easy for each other to read. The Xcode defaults are sufficient.

Pull requests trigger a GitHub Action that runs swift-format using the [repository rules](https://github.com/thunderbird/thunderbird-ios/blob/main/.swift-format), and non-passing format checks will block merging.

To run swift-format locally from shell, first check that your working directory is the repository root, as running swift-format from home will recursively, in-place lint and format _every_ source code file:

```
cd File/Path/To/thunderbird-ios/
```

```
xcrun swift-format format . --parallel --recursive --in-place
```

Complete list of available [`swift-format` rules](https://github.com/swiftlang/swift-format/blob/main/Documentation/RuleDocumentation.md)

## License
```
Thunderbird for iOS is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/
```
The above license statement is automatically generated when a new file is created. Please do not remove the generated header and license information.

<!-- TODO: List additional conventions -->