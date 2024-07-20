//
//  Remote.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 04/01/2024.
//

import Alamofire
import Combine
import Foundation

extension Alamofire.AFError: @unchecked Sendable {}

// MARK: - Placeholdable

public protocol Placeholdable: Equatable {

    static var placeholder: Self { get }

}

// MARK: - Remote resource

public protocol Remote<Resource>: Sendable {

    associatedtype Resource: (Placeholdable & Sendable)

}

// MARK: - Create

public protocol RemoteCreate: Remote {

    associatedtype CreateRequest: (Encodable & Sendable)
    associatedtype CreateResponse: (Decodable & Sendable)

    func create(
        using session: NetworkSession,
        request: CreateRequest
    ) async throws(NetworkError) -> CreateResponse

    nonisolated static func endpoint(_ request: CreateRequest) throws(NetworkError) -> Endpoint
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> CreateRequest
    nonisolated static func resource(from response: CreateResponse) throws(NetworkError) -> Resource

}

public extension RemoteCreate {

    func create(
        using session: NetworkSession,
        request: CreateRequest
    ) async throws(NetworkError) -> CreateResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: CreateResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

// MARK: - Read

public typealias Query = RemoteRead
public typealias Request = RemoteRead
public protocol RemoteRead: Remote {

    associatedtype ReadRequest: (Encodable & Sendable)
    associatedtype ReadResponse: (Decodable & Sendable)

    func read(
        using session: NetworkSession,
        request: ReadRequest
    ) async throws(NetworkError) -> ReadResponse

    nonisolated static func endpoint(_ request: ReadRequest) throws(NetworkError) -> Endpoint
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> ReadRequest
    nonisolated static func resource(from response: ReadResponse) throws(NetworkError) -> Resource

}

public extension RemoteRead {

    func read(
        using session: NetworkSession,
        request: ReadRequest
    ) async throws(NetworkError) -> ReadResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: ReadResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

// MARK: - Update

public protocol RemoteUpdate: RemoteRead {

    associatedtype UpdateRequest: (Encodable & Sendable)
    associatedtype UpdateResponse: (Decodable & Sendable)

    func update(
        using session: NetworkSession,
        request: UpdateRequest
    ) async throws(NetworkError) -> UpdateResponse

    nonisolated static func endpoint(_ request: UpdateRequest) throws(NetworkError) -> Endpoint
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> UpdateRequest
    nonisolated static func resource(from response: UpdateResponse) throws(NetworkError) -> Resource

}

public extension RemoteUpdate {

    func update(
        using session: NetworkSession,
        request: UpdateRequest
    ) async throws(NetworkError) -> UpdateResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: UpdateResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

// MARK: - Delete

public protocol RemoteDelete: RemoteRead {

    associatedtype DeleteRequest: (Encodable & Sendable)
    associatedtype DeleteResponse: (Decodable & Sendable)

    @discardableResult
    func delete(
        using session: NetworkSession,
        request: DeleteRequest
    ) async throws(NetworkError) -> DeleteResponse

    nonisolated static func endpoint(_ request: DeleteRequest) throws(NetworkError) -> Endpoint
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> DeleteRequest
    nonisolated static func resource(from response: DeleteResponse) throws(NetworkError) -> Resource

}

public extension RemoteDelete {

    @discardableResult
    func delete(
        using session: NetworkSession,
        request: DeleteRequest
    ) async throws(NetworkError) -> DeleteResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: DeleteResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

// MARK: - List

public protocol RemoteList: Remote {

    associatedtype ListRequest: (Encodable & Sendable)
    associatedtype ListResponse: (Decodable & Sendable)

    func list(
        using session: NetworkSession,
        request: ListRequest
    ) async throws(NetworkError) -> ListResponse

    nonisolated static func endpoint(_ request: ListRequest) throws(NetworkError) -> Endpoint
    nonisolated static func firstPageRequest() -> ListRequest
    nonisolated static func nextPageRequest(currentResource: [Resource], lastResponse: ListResponse) -> ListRequest?
    nonisolated static func list(from response: ListResponse, oldValue: [Resource]) -> [Resource]

}

public extension RemoteList {

    nonisolated static func resource(
        from response: ListResponse,
        operation: ResourceOperation
    ) throws(NetworkError) -> Resource {
        throw .localMapError
    }

    nonisolated static func request(
        from resource: Resource,
        operation: ResourceOperation
    ) throws(NetworkError) -> ListRequest {
        throw .localMapError
    }

    nonisolated static func nextPageRequest(
        currentResource: [Resource],
        lastResponse: ListResponse
    ) -> ListRequest? {
        return nil
    }

    func list(
        using session: NetworkSession,
        request: ListRequest
    ) async throws(NetworkError) -> ListResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: ListResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

// MARK: - CRUD

public protocol RemoteCRUD: RemoteCreate, RemoteRead, RemoteUpdate, RemoteDelete {

}

// MARK: - CRUD+L

public protocol RemoteCRUD_L: RemoteCRUD, RemoteList {}

// MARK: - Resource operation

public enum ResourceOperation {

    case create
    case read
    case update
    case delete
    case list

}

// MARK: - Resource state

public enum ResourceState<R, E: Error> {

    case idle
    case loading
    case failure(E)

    case available(R)
    case pending(R)
    case uploading(R)
    case stale(R, E)

    public var isAvailable: Bool {
        switch self {
        case .idle, .loading, .failure:
            return false

        default:
            return true
        }
    }

    public var value: R? {
        switch self {
        case .idle, .loading, .failure:
            return nil

        case .available(let resource), .pending(let resource), .uploading(let resource):
            return resource

        case .stale(let resource, _):
            return resource
        }
    }

    public var unwrapped: R {
        guard let value else { preconditionFailure("Accessing unavailable resource") }
        return value
    }

    public var error: E? {
        switch self {
        case .failure(let error), .stale(_, let error):
            return error

        default:
            return nil
        }
    }

}

// MARK: - Resource state - Placeholdable

extension ResourceState where R: Placeholdable {



}

extension ResourceState: Sendable where R: Sendable, E: Sendable {}

// MARK: - Resource state - Equatable

extension ResourceState: Equatable where R: Equatable, E: Equatable {}

/// Equality check using current resource state when resource itself is not equatable
public func ==<R, E>(lhs: ResourceState<R, E>, rhs: ResourceState<R, E>) -> Bool {
    switch lhs {
    case .idle:
        switch rhs {
        case .idle:
            return true
        default:
            return false
        }
    case .loading:
        switch rhs {
        case .loading:
            return true
        default:
            return false
        }
    case .failure:
        switch rhs {
        case .failure:
            return true
        default:
            return false
        }
    case .available:
        switch rhs {
        case .available:
            return true
        default:
            return false
        }
    case .pending:
        switch rhs {
        case .pending:
            return true
        default:
            return false
        }
    case .uploading:
        switch rhs {
        case .uploading:
            return true
        default:
            return false
        }
    case .stale:
        switch rhs {
        case .stale:
            return true
        default:
            return false
        }
    }
}
