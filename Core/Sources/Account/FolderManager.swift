// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Manages and contains information for folders for a given ``Account``.
@Observable
public final class FolderManager {
    public let account: Account
    public var folders: [Folder] = []

    public init(account: Account) {
        self.account = account
    }

    public func folderForID(_ id: String) -> Folder? {
        folders.filter { $0.id == id }.first
    }

    public func folderForName(_ name: String) -> Folder? {
        folders.filter { $0.name == name }.first
    }

    public func folderForPath(_ path: String) -> Folder? {
        folders.filter { $0.path == path }.first
    }

    /// Get the immediate parent path of a folder by dropping it's last component.
    func parentPath(of path: String) -> String? {
        guard let range = path.range(of: "/", options: .backwards) else { return nil }
        let parent = String(path[..<range.lowerBound])
        return parent.isEmpty ? nil : parent
    }

    /// Organize folders into a nested structure based on their mailbox paths.
    // TEMP: Due to display limitations folders should be limited to a depth of 3.
    // Any folders with a depth exceeding 3 should appear at level 3.
    // i.e. Folder > Subfolder > Child Subfolder AND Folder > Subfolder > Child Subfolder > Grandchild Subfolder appear at the same level
    // In this instance "Grandchild Subfolder" should appear as "Child Subfolder/Grandchild Subfolder" in the UI.
    public func refreshFolders(mailboxes: [Mailbox]) async {
        // Populate the full list of folders
        for mailbox in mailboxes {
            folders.append(Folder(from: mailbox))
        }

        // Create a set to hold the subfolders that get appended to their parent.
        var toRemove = Set<Folder>()

        // Sort the folders so that subfolders are only listed after their parent.
        let sortedByDepth = folders.sorted { lhs, rhs in
            lhs.path?.split(separator: "/").count ?? 0 > rhs.path?.split(separator: "/").count ?? 0
        }

        for child in sortedByDepth {
            guard let parentPath = parentPath(of: child.path!), let parent = folderForPath(parentPath), let index = folders.firstIndex(of: parent), parent != child else {
                continue
            }

            // TEMP: Limit subfolders to a depth of 3.
            if child.path?.split(separator: "/").count ?? 0 > 3 {
                continue
            }

            if let originalChild = folders.first(where: { $0.path == child.path }) {
                folders[index].subfolders.append(originalChild)
            } else {
                print("Unable to establish child relationship.")
            }

            toRemove.insert(child)
        }

        folders.removeAll { toRemove.contains($0) }
    }
}
