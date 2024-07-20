//
//  UserListScreen.swift
//  GoodNetworking-Sample
//
//  Created by Filip Šašala on 17/07/2024.
//

import GoodNetworking
import SwiftUI
import GoodMacros

struct UserListScreen: View {

    // MARK: - Wrappers

    @Resource(session: .sampleSession, remote: RemoteUser()) var users

    // MARK: - View state

    @State private var didLoadList = false

    // MARK: - Properties

    // MARK: - Initialization

    // MARK: - Computed properties

    // MARK: - Body

    var body: some View {
        List {
            Section {
                ForEach(_users) { user in
                    NavigationLink {
                        UserScreen(userId: user.id)
                    } label: {
                        Text("\(user.firstName) \(user.lastName)")
                    }
                    .frame(height: 300)
                }

                NavigationLink {
                    // UserEditScreen()
                    Text("edit here")
                } label: {
                    Label("Create new", systemImage: "plus")
                }
            } footer: {
                ResourcePager(resource: _users)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .redacted(reason: _users.state.isAvailable ? [] : [.placeholder])
        .refreshable { await reload() }
        .task { await loadList() }
        .navigationTitle("All employees")
        .navigationBarTitleDisplayMode(.inline)
    }

}

extension UserListScreen {

    func reload() async {
        await _users.firstPage(forceReload: true)
    }

    func loadList() async {
        guard !didLoadList else { return }
        await _users.firstPage()
        didLoadList = true
    }

}

// MARK: - Previews

#Preview {
    UserListScreen()
}
