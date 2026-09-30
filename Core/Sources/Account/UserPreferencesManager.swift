// UserSession.swift
// Core
//
// Created by Vlad Skorinov on 27/06/2026.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
//

import Foundation
import GRDB

@Observable
public final class UserPreferencesManager {
    private var store: LocalStore
    private var preferences: UserPreferences
    
    public init(store: LocalStore, accounts: [Account]) {
        let firstAccount = accounts.first
        
        self.store = store
        preferences = UserPreferences(selectedAccountId: firstAccount?.id, selectedMailboxByAccount: [:])
    }
    
    /// Loads persisted preferences; call once when the app starts.
    public func load() throws {
        preferences = try store.loadPreferences() ?? preferences
    }
    
    public var selectedAccountId: UUID? { preferences.selectedAccountId }
    
    public var selectedMailboxName: String? {
        // even if selectedAccountId doesn't exist the property will default to INBOX
        preferences.selectedMailboxByAccount[selectedAccountId!] ?? "INBOX"
    }
        
    public func selectAccount(_ id: UUID) throws {
        let fallbackId = preferences.selectedAccountId
        
        preferences.selectedAccountId = id
        do {
            try store.savePreferences(preferences)
        } catch {
            preferences.selectedAccountId = fallbackId
            throw AccountError(error)
        }
    }
    
    public func selectMailbox(_ mailbox: String, for accountId: UUID) throws {
        let fallbackMap = preferences.selectedMailboxByAccount
        
        preferences.selectedMailboxByAccount[accountId] = mailbox
        do {
            try store.savePreferences(preferences)
        } catch {
            preferences.selectedMailboxByAccount = fallbackMap
            throw AccountError(error)
        }
    }
    
    /// Assumes mailbox is being selected for current `SessionStorage.selectedAccountId`
    public func selectMailbox(_ mailbox: String) throws {
        guard let currentAccountId = preferences.selectedAccountId else {
            throw AccountError.preferences(.account("No account selected"))
        }
        
        try selectMailbox(mailbox, for: currentAccountId)
    }
}


public struct UserPreferences: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var selectedAccountId: UUID?
    var selectedMailboxByAccount: [UUID: String]
    
    // Single-row database to store state, so should be fine?
    public var id: String
    
    public init(selectedAccountId: UUID?, selectedMailboxByAccount: [UUID: String]) {
        self.selectedAccountId = selectedAccountId
        self.selectedMailboxByAccount = selectedMailboxByAccount
        self.id = "1"
    }
}


public enum PreferencesError: Error, CustomStringConvertible {
    case account(String)

    // MARK: CustomStringConvertible
    public var description: String {
        switch self {
        case .account(let message): message
        }
    }
}
