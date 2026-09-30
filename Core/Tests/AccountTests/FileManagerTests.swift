// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Testing
import Foundation

struct FileManagerTests {
    @Test func fileExists() throws {
        let url: URL = .temporaryDirectory.appending(path: "Test.txt")
        let data: Data = "Test".data(using: .utf8)!
        try data.write(to: url)
        #expect(try FileManager.default.fileExists(at: url) == true)
        #expect(String(data: try Data(contentsOf: url), encoding: .utf8) == "Test")
        try? FileManager.default.removeItem(at: url)
        #expect(try FileManager.default.fileExists(at: url) == false)
    }
}

struct URLTests {
    @Test func documents() {
        #expect(URL.documents("Test.json").absoluteString.hasSuffix("/Test.json"))
        #expect(URL.documents("Test.txt") == .temporaryDirectory.appending(path: "Test.txt"))
        #expect(URL.documents() == .temporaryDirectory)
    }
}

struct ProcessInfoTests {
    @Test func isTestEnvironment() {
        #expect(ProcessInfo.processInfo.isTestEnvironment == true)
    }
}
