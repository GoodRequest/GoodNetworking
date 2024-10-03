//
//  ResourceOperations.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 14/08/2024.
//

#warning("TODO: Add documentation")

import Foundation
import Hitch
import Sextant

// MARK: - Creatable

public typealias Post = Creatable
public protocol Creatable: RemoteResource {

    associatedtype CreateRequest: (Sendable)
    associatedtype CreateResponse: (Decodable & Sendable)

    static func create(
        using session: NetworkSession,
        request: CreateRequest
    ) async throws(NetworkError) -> CreateResponse

    nonisolated static func endpoint(_ request: CreateRequest) throws(NetworkError) -> Endpoint
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> CreateRequest?
    nonisolated static func resource(from response: CreateResponse) throws(NetworkError) -> Resource

}

public extension Creatable {

    static func create(
        using session: NetworkSession,
        request: CreateRequest
    ) async throws(NetworkError) -> CreateResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: CreateResponse = try await session.request(endpoint: endpoint)
        return response
    }

    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> CreateRequest? {
        throw .missingLocalData
    }

}

public extension Creatable where CreateResponse == Resource {

    nonisolated static func resource(from response: CreateResponse) throws(NetworkError) -> Resource {
        response
    }

}

// MARK: - Readable

public protocol Readable: RemoteResource {

    associatedtype ReadRequest: (Sendable)
    associatedtype ReadResponse: (Decodable & Sendable)

    static func read(
        using session: NetworkSession,
        request: ReadRequest
    ) async throws(NetworkError) -> ReadResponse

    nonisolated static func endpoint(_ request: ReadRequest) throws(NetworkError) -> Endpoint
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> ReadRequest?
    nonisolated static func resource(from response: ReadResponse) throws(NetworkError) -> Resource

}

public extension Readable {

    static func read(
        using session: NetworkSession,
        request: ReadRequest
    ) async throws(NetworkError) -> ReadResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: ReadResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

public extension Readable where ReadRequest == Void {

    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> ReadRequest? {
        ()
    }

}

public extension Readable where ReadResponse == Resource {

    nonisolated static func resource(from response: ReadResponse) throws(NetworkError) -> Resource {
        response
    }

}

// MARK: - Readable - Query

public protocol Query: Readable where ReadResponse == Data {

    nonisolated static func query() -> String

}

public extension Query where Resource: Decodable {

    nonisolated static func resource(from response: ReadResponse) throws(NetworkError) -> Resource {
        Sextant.shared.query(response, values: Hitch(string: query())) ?? .placeholder
    }

}

public extension Query {

    static func read(
        using session: NetworkSession,
        request: ReadRequest
    ) async throws(NetworkError) -> ReadResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: ReadResponse = try await session.requestRaw(endpoint: endpoint)
        return response
    }

}

// MARK: - Updatable

public typealias Update = Updatable
public protocol Updatable: Readable {

    associatedtype UpdateRequest: (Sendable)
    associatedtype UpdateResponse: (Decodable & Sendable)

    static func update(
        using session: NetworkSession,
        request: UpdateRequest
    ) async throws(NetworkError) -> UpdateResponse

    nonisolated static func endpoint(_ request: UpdateRequest) throws(NetworkError) -> Endpoint
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> UpdateRequest?
    nonisolated static func resource(from response: UpdateResponse) throws(NetworkError) -> Resource

}

public extension Updatable {

    static func update(
        using session: NetworkSession,
        request: UpdateRequest
    ) async throws(NetworkError) -> UpdateResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: UpdateResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

public extension Updatable where UpdateResponse == Resource {

    nonisolated static func resource(from response: UpdateResponse) throws(NetworkError) -> Resource {
        response
    }

}

// MARK: - Deletable

public protocol Deletable: Readable {

    associatedtype DeleteRequest: (Sendable)
    associatedtype DeleteResponse: (Decodable & Sendable)

    @discardableResult
    static func delete(
        using session: NetworkSession,
        request: DeleteRequest
    ) async throws(NetworkError) -> DeleteResponse

    nonisolated static func endpoint(_ request: DeleteRequest) throws(NetworkError) -> Endpoint
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> DeleteRequest?
    nonisolated static func resource(from response: DeleteResponse) throws(NetworkError) -> Resource

}

public extension Deletable {

    @discardableResult
    static func delete(
        using session: NetworkSession,
        request: DeleteRequest
    ) async throws(NetworkError) -> DeleteResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: DeleteResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

public extension Deletable where DeleteResponse == Resource {

    nonisolated static func resource(from response: DeleteResponse) throws(NetworkError) -> Resource {
        response
    }

}

// MARK: - Listable

public protocol Listable: RemoteResource {

    associatedtype ListRequest: (Sendable)
    associatedtype ListResponse: (Decodable & Sendable)

    static func list(
        using session: NetworkSession,
        request: ListRequest
    ) async throws(NetworkError) -> ListResponse

    nonisolated static func endpoint(_ request: ListRequest) throws(NetworkError) -> Endpoint
    nonisolated static func firstPageRequest() -> ListRequest
    nonisolated static func nextPageRequest(currentResource: [Resource], lastResponse: ListResponse) -> ListRequest?
    nonisolated static func list(from response: ListResponse, oldValue: [Resource]) -> [Resource]

}

public extension Listable {

    nonisolated static func nextPageRequest(
        currentResource: [Resource],
        lastResponse: ListResponse
    ) -> ListRequest? {
        return nil
    }

    static func list(
        using session: NetworkSession,
        request: ListRequest
    ) async throws(NetworkError) -> ListResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: ListResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

// MARK: - All CRUD operations

public protocol CRUDable: Creatable, Readable, Updatable, Deletable {}

// MARK: - CRUD + Listable

public protocol CRUDLable: CRUDable, Listable {}
