// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

struct EmailListView: View {
    @Environment(SessionManager.self) private var session: SessionManager

    @State private var selections: Set<UUID> = []
    @State private var path = NavigationPath()
    @State private var emails: [Email] = []

    // MARK: UI State
    @State private var showDrawer = false
    #if os(iOS)
    @State var editMode: EditMode = .inactive
    #endif
    @State var error: EmailError?

    func sortEmails(by strategy: SortStrategy) {
        //Not yet implemented
        AlertManager.shared.showAlert = true
        AlertManager.shared.alertTitle = "Sort Emails"
    }

    func selectAll() {
        for email in emails {
            selections.insert(email.id)
        }
    }

    //TODO: replace with backend unread state call
    func markSelectionAsRead() {
        Task {
            do {
                try await session.markAsRead(emails: emails)
                emails = try await session.loadEmails()
            } catch {
                self.error = error
            }
        }
    }

    func deleteSelection() {
        Task {}
    }

    func loadEmails() {
        Task {
            do {
                emails = try await session.loadEmails()
            } catch {
                self.error = EmailError.failedToLoad(error)
            }
        }
    }

    func loadMoreEmails() {
        guard let oldestEmail = emails.last else {
            return
        }

        Task {
            do {
                let additionalEmails = try await session.loadEmails(cursor: oldestEmail.uid)
                emails.append(contentsOf: additionalEmails)
            } catch {
                self.error = error
            }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                if emails.isEmpty {
                    VStack {
                        Text("empty_inbox")
                            .padding(.bottom, 5)
                        Text("new_messages_will_appear")
                            .padding(.bottom, 10)
                        Button {
                            // TODO: trigger login flow
                        } label: {
                            Text("add_another_account")
                        }.buttonBorderShape(.capsule)
                            .buttonStyle(.bordered)
                            .foregroundStyle(.black)
                        Spacer()
                    }.accessibilityHidden(showDrawer)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        List(emails, id: \.id, selection: $selections) { email in
                            NavigationLink {
                                ReadEmailView(email)
                            } label: {
                                EmailCellView(email: email)
                            }
                            .contentShape(Rectangle())
                            #if os(iOS)
                            .simultaneousGesture(
                                LongPressGesture().onEnded { _ in
                                    withAnimation {
                                        editMode = .active
                                    }
                                }
                            )
                            #endif
                            .listRowSeparator(.hidden)
                            .navigationLinkIndicatorVisibility(.hidden)
                            .accessibilityHidden(showDrawer)
                        }

                        ProgressView()
                            .progressViewStyle(.circular)
                            .onAppear {
                                do {
                                    let oldestEmail = emails.first!
                                    let additionalEmails = try session.loadEmails(cursor: oldestEmail.uid)

                                    emails.append(contentsOf: additionalEmails)
                                } catch {
                                    self.error = error
                                }
                            }
                    }
                    #if os(iOS)
                    .environment(\.editMode, $editMode)
                    #endif
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                Button {
                    path.append("compose")
                } label: {
                    Image("compose")
                        .font(.title.weight(.regular))
                        .padding(.all, 12)
                        .padding(.leading, 5)
                        .background(Color(white: 0.9))
                        .foregroundColor(.muted)
                        .clipShape(Circle())
                }.background(.clear)
                    .accessibilityHidden(showDrawer)
                    .padding()
                    .navigationDestination(for: String.self) { destination in
                        if destination == "compose" {
                            ComposeView()
                        }
                    }
                }

                DrawerView(showDrawer: $showDrawer)
                    .accessibilityHidden(!showDrawer)
                    .environment(session)
            }
            .navigationTitle("inbox_header")
            #if os(iOS)
            .navigationBarBackButtonHidden(editMode.isEditing || showDrawer)
            #endif
            .toolbar {
                ToolbarItem(placement: .leading) {
                    Button {
                        withAnimation {
                            showDrawer = true
                        }
                    } label: {
                        Label("Account", systemImage: "line.3.horizontal").labelStyle(.iconOnly)
                    }.accessibilityHidden(showDrawer)
                }
                #if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    if editMode.isEditing == true {
                        Button(
                            "close_button", systemImage: "xmark",
                            action: {
                                withAnimation {
                                    editMode = .inactive
                                }
                            })
                    }
                }
                #endif
                ToolbarItem(placement: .trailing) {
                    Menu {
                        Button(
                            "date_sort_button",
                            action: {
                                sortEmails(by: .date)
                            })
                        Button(
                            "read_status_sort_button",
                            action: {
                                sortEmails(by: .status)
                            })
                        Button(
                            "has_attachments_sort_button",
                            action: {
                                sortEmails(by: .hasAttachments)
                            })
                    } label: {
                        Label("sort_button", systemImage: "line.3.horizontal.decrease", )
                    }.accessibilityHidden(showDrawer)
                }
                ToolbarItem(placement: .trailing) {
                    Menu {
                        #if os(iOS)
                        Button(
                            editMode.isEditing ? "done_button" : "select_all_button",
                            action: {
                                withAnimation {
                                    editMode = editMode.isEditing ? .inactive : .active
                                }
                                selectAll()
                            })
                        #endif
                        Button(
                            "mark_all_read_button",
                            action: {
                                markSelectionAsRead()
                            })
                        Button(
                            "account_sign_out_button",
                            action: {
                                do {
                                    try session.deleteCurrentAccount()
                                } catch {
                                    self.error = error
                                }
                            })
                    } label: {
                        Label("options_button", systemImage: "ellipsis")
                    }.accessibilityHidden(showDrawer)
                }
            }
            .onChange(of: session.selectedMailbox, initial: true) {
                loadEmails()
            }
        }
    }
}

public enum EmailError: Error {
    case failedToLoad(Error)
}

public enum SortStrategy {
    case date
    case status
    case hasAttachments
}

#Preview("Email List") {
    @Previewable @State var flags: FeatureFlags = FeatureFlags(distribution: .current)
    @Previewable @State var store = try! LocalStore()
    @Previewable @State var accountManager = AccountManager(store: store)

    EmailListView()
        .environment(flags)
        .environment(accountManager)
}

private extension ToolbarItemPlacement {
    static var leading: Self {
        #if os(iOS)
        .topBarLeading
        #else
        .automatic
        #endif
    }

    static var trailing: Self {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}
