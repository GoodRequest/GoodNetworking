//
//  UserScreen.swift
//  GoodNetworking-Sample
//
//  Created by Filip Šašala on 17/07/2024.
//

import GoodNetworking
import GRAsyncImage
import SwiftUI

struct UserScreen: View {

    // MARK: - State

    @State private var user = Resource(session: .sampleSession, remote: RemoteUser.self)

    // MARK: - Properties

    let userId: Int

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                userView(user: user.state)
            }
            .padding()
        }
        .refreshable {
            do {
                try await user.read(forceReload: true)
            } catch {
                print(error)
            }
        }
        .task {
            do {
                try await user.read(request: UserRequest(id: userId))
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

#Preview {

    UserScreen(userId: 1)

}
