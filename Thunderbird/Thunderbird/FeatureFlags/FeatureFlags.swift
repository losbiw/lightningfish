// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

private let allowRemoteFlags = "allowRemoteFeatureFlags"

public enum Flag: String {
    case featureX
    case featureY
    case fullDate
}

@MainActor
@Observable final public class FeatureFlags: Sendable {
    public var featureList: [String] = ["fullDate", "featureX", "featureY"]
    //False = feature is turned off
    private var featureSettings: [String: Bool] = [:]
    public var allowRemote: Bool = true
    private var defaultsKey: String

    // Allow user to turn off/on feature flags pulled from Github
    public init(distribution: Distribution) {
        allowRemote = (UserDefaults.standard.value(forKey: allowRemoteFlags) ?? true) as! Bool
        defaultsKey = distribution.defaultsKey
        setDefaultFlags(distribution: distribution)
    }

    private func setDefaultFlags(distribution: Distribution) {
        featureSettings = featureList.reduce(
            into: [:],
            { (dict, key) in
                dict[key] = false
            })
        let storedSettings = (UserDefaults.standard.dictionary(forKey: defaultsKey) ?? [:]) as! [String: Bool]
        featureSettings.merge(storedSettings) { (current, new) in new }
        //if allowed to use url
        if allowRemote {
            Task {
                let remoteSettings: [String: Bool] = await getURLSettings(distribution: distribution)
                featureSettings.merge(remoteSettings) { (current, new) in new }
                UserDefaults.standard.setValue(featureSettings, forKey: defaultsKey)
            }
        }

    }

    public func flagForKey(key: String) -> Bool {
        return featureSettings[key] ?? false
    }
    public func setFlagForKey(key: String, val: Bool) {
        featureSettings[key] = val
        UserDefaults.standard.setValue(featureSettings, forKey: defaultsKey)
    }

    public func setAllowRemoteFlags(allowRemote: Bool) {
        self.allowRemote = allowRemote
        UserDefaults.standard.setValue(allowRemote, forKey: allowRemoteFlags)
    }

    /// Pull current feature flag settings from json URL based on current distribution
    /// Using JSON file in github for visibility
    private func getURLSettings(distribution: Distribution) async -> [String: Bool] {
        var url: URL

        switch distribution {
        // TODO: replace these with our own
        case .debug:
            url = URL(string: "https://thunderbird.github.io/thunderbird-ios/feature_flag_config_debug.json")!
        case .appstore:
            url = URL(string: "https://thunderbird.github.io/thunderbird-ios/feature_flag_config_appstore.json")!
        case .beta:
            url = URL(string: "https://thunderbird.github.io/thunderbird-ios/feature_flag_config_beta.json")!
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(Response.self, from: data)
            return response.flags
        } catch {
            return [:]
        }
    }

    static func resetFeatureFlags(distribution: Distribution = .current) {
        UserDefaults.standard.removeObject(forKey: distribution.defaultsKey)
    }

    static func resetAllowRemoteFlags() {
        UserDefaults.standard.removeObject(forKey: allowRemoteFlags)
    }
}

private struct Response: Decodable {
    let flags: [String: Bool]
}

private extension Distribution {
    var defaultsKey: String {
        switch self {
        case .debug: "featureListDebug"
        case .appstore: "featureListAppStore"
        case .beta: "featureListBeta"
        }
    }
}
