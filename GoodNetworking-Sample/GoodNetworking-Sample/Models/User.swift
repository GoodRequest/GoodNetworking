//
//  User.swift
//  GoodNetworking-Sample
//
//  Created by Filip Šašala on 17/07/2024.
//

import Foundation
import GoodNetworking

// MARK: - Model

struct User: Codable, Identifiable, WithCustomDecoder {

    static let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase

    var id: Int
    var email: String
    var firstName: String
    var lastName: String
    var avatar: URL?

}

// MARK: - Read request

struct UserRequest: Encodable {

    let id: Int

}

// MARK: - Read response

struct UserResponse: Codable, WithCustomDecoder, Equatable {

    static let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase

    let data: User

}

// MARK: - List request

struct UserListRequest: Encodable {

    let page: Int

}

// MARK: - List response

struct UserListResponse: Decodable, WithCustomDecoder {

    static let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase

    let data: [User]

    let total: Int
    let page: Int
    let totalPages: Int
    let perPage: Int

    var hasNextPage: Bool {
        page < totalPages
    }

}

// MARK: - Placeholder

extension User: Placeholdable {

    static let placeholder: User = User(
        id: 0,
        email: "empty@example.com",
        firstName: "John",
        lastName: "Apple",
        avatar: nil
    )

}

// MARK: - Remote

struct RemoteUser: Readable {

    typealias Resource = User
    typealias ReadRequest = UserRequest
    typealias ReadResponse = UserResponse

    nonisolated static func endpoint(_ request: ReadRequest) throws(NetworkError) -> Endpoint {
        SampleEndpoint.singleUser(id: request.id)
    }

    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> ReadRequest? {
        guard let resource else { throw .missingLocalData }
        return UserRequest(id: resource.id)
    }

    nonisolated static func resource(from response: ReadResponse, updating resource: Resource?) throws(NetworkError) -> Resource {
        response.data
    }

}

extension RemoteUser: Listable {

    typealias ListRequest = UserListRequest
    typealias ListResponse = UserListResponse

    nonisolated static func endpoint(_ request: ListRequest) throws(NetworkError) -> Endpoint {
        SampleEndpoint.listUsers(page: request.page)
    }

    nonisolated static func firstPageRequest(withParameters: Any?) -> UserListRequest {
        ListRequest(page: 1)
    }

    nonisolated static func nextPageRequest(
        currentResource: [User],
        parameters: Any?,
        lastResponse: UserListResponse
    ) -> UserListRequest? {
        print(lastResponse.page, "/", lastResponse.totalPages)
        if lastResponse.totalPages > lastResponse.page {
            return UserListRequest(page: lastResponse.page + 1)
        } else {
            return nil
        }
    }

    nonisolated static func list(from response: ListResponse, oldValue: [Resource]) -> [Resource] {
        let lastPage = oldValue.count / response.perPage

        if oldValue.count > 0 && lastPage < response.page {
            return oldValue + response.data
        } else if oldValue.isEmpty {
            return response.data
        } else {
            return oldValue
        }
    }

}
