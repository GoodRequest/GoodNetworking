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

    @State private var users = Resource(session: .sampleSession, remote: RemoteUser.self)

    // MARK: - View state

    @State private var didLoadList = false

    // MARK: - Properties

    // MARK: - Initialization

    // MARK: - Computed properties

    // MARK: - Body

    var body: some View {
        List {
            Section {
                ForEach(users.elements) { user in
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
                ResourcePager(resource: users)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .redacted(reason: users.state.isAvailable ? [] : [.placeholder])
        .refreshable { await reload() }
        .task { await loadList() }
        .navigationTitle("All employees")
        .navigationBarTitleDisplayMode(.inline)
    }

}

extension UserListScreen {

    func reload() async {
        do {
            try await users.firstPage(forceReload: true)
        } catch {
            print("Error reloading users: \(error.localizedDescription)")
        }
    }

    func loadList() async {
        guard !didLoadList else { return }
        do {
            try await users.firstPage()
        } catch {
            print("Error loading users: \(error.localizedDescription)")
        }
        didLoadList = true
    }

}

// MARK: - Previews

#Preview {
    UserListScreen()
}
