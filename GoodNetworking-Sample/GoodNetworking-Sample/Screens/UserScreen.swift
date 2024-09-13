//
//  UserScreen.swift
//  GoodNetworking-Sample
//
//  Created by Filip Šašala on 17/07/2024.
//

import Alamofire
import GoodNetworking
import GRAsyncImage
import SwiftUI

struct UserScreen: View {

    // MARK: - Wrappers

    @Resource(session: .sampleSession, remote: RemoteUser.self) var user

    // MARK: - View state

    // MARK: - Properties

    let userId: Int

    // MARK: - Initialization

    // MARK: - Computed properties

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                userView(user: _user.state)
            }
            .padding()
        }
        .refreshable {
            do {
                try await _user.read(forceReload: true)
            } catch {
                print(error)
            }
        }
        .task {
            do {
                try await _user.read(request: UserRequest(id: userId))
            } catch {
                print(error)
            }
        }
        .navigationTitle("User detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadingView() -> some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Loading...")
        }
    }

    @ViewBuilder private func userView(user: ResourceState<User, NetworkError>) -> some View {
        switch user {
        case .idle:
            Text("Resource idle")

        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                Text("Loading...")
            }

        case .failure(let e):
            Text(e.localizedDescription)

        case .available(let user):
            let fields = [
                "ID", "First name", "Last name", "Email"
            ]
            let values = [
                String(user.id), user.firstName, user.lastName, user.email
            ]

            LazyVGrid(columns: [GridItem(), GridItem()]) {
                ForEach(Array(zip(fields, values)), id: \.0) { field, value in
                    Text(field)
                    Text(value)
                }

                Text("Avatar")
                GRAsyncImage(url: user.avatar)
                    .aspectRatio(1, contentMode: .fit)
            }

        default:
            Text("Unknown state")
        }
    }

}

// MARK: - Previews

#Preview {
    UserScreen(userId: 1)
}
