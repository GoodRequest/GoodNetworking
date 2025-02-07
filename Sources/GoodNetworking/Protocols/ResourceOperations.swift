//
//  ResourceOperations.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 14/08/2024.
//

import Foundation
import Hitch
import Sextant

// MARK: - Creatable

/// Represents a resource that can be created on a remote server.
///
/// Types conforming to `Creatable` define the necessary types and functions for creating a resource on a server.
/// This includes specifying the types for creation requests and responses, and providing methods for making the
/// network request and transforming the responses.
public protocol Creatable: RemoteResource {

    /// The type of request used to create the resource.
    associatedtype CreateRequest: Sendable

    /// The type of response returned after the resource is created.
    associatedtype CreateResponse: NetworkSession.DataType

    /// Creates a new resource on the remote server using the provided session and request data.
    ///
    /// This method performs an asynchronous network request to create a resource, using the specified session and request.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The creation request data.
    /// - Returns: The response object containing the created resource data.
    /// - Throws: A `NetworkError` if the request fails.
    static func create(
        using session: NetworkSession,
        request: CreateRequest
    ) async throws(NetworkError) -> CreateResponse

    /// Constructs an `Endpoint` for the creation request.
    ///
    /// This method is used to convert the creation request data into an `Endpoint` that represents the request details.
    ///
    /// - Parameter request: The creation request data.
    /// - Returns: An `Endpoint` that represents the request.
    /// - Throws: A `NetworkError` if the endpoint cannot be created.
    nonisolated static func endpoint(_ request: CreateRequest) throws(NetworkError) -> Endpoint

    /// Transforms an optional `Resource` into a `CreateRequest`.
    ///
    /// This method can be used to generate a `CreateRequest` from a given `Resource`, if applicable.
    ///
    /// - Parameter resource: The optional resource to be transformed into a request.
    /// - Returns: A `CreateRequest` derived from the resource, or `nil` if not applicable.
    /// - Throws: A `NetworkError` if the transformation fails.
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> CreateRequest?

    /// Transforms the creation response into a `Resource`.
    ///
    /// This method is used to convert the response data from the creation request into a usable `Resource`.
    ///
    /// - Parameter response: The response received from the creation request.
    /// - Returns: A `Resource` derived from the response.
    /// - Throws: A `NetworkError` if the transformation fails.
    nonisolated static func resource(from response: CreateResponse, updating resource: Resource?) throws(NetworkError) -> Resource

}

public extension Creatable {

    /// Creates a new resource on the remote server using the provided session and request data.
    ///
    /// This default implementation performs the network request to create the resource by first obtaining the
    /// `Endpoint` from the `CreateRequest`, then sending the request using the provided `NetworkSession`.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The creation request data.
    /// - Returns: The response object containing the created resource data.
    /// - Throws: A `NetworkError` if the request fails.
    static func create(
        using session: NetworkSession,
        request: CreateRequest
    ) async throws(NetworkError) -> CreateResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: CreateResponse = try await session.request(endpoint: endpoint)
        return response
    }

    /// Provides a default implementation that throws an error indicating the request cannot be derived from the resource.
    ///
    /// This implementation can be overridden by conforming types to provide specific behavior.
    ///
    /// - Parameter resource: The optional resource to be transformed into a request.
    /// - Returns: `nil` by default.
    /// - Throws: A `NetworkError.missingLocalData` if the transformation is not supported.
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> CreateRequest? {
        throw .missingLocalData
    }

}

public extension Creatable where CreateResponse == Resource {

    /// Provides a default implementation that directly returns the response as the `Resource`.
    ///
    /// This implementation can be used when the `CreateResponse` type is the same as the `Resource` type,
    /// allowing the response to be returned directly.
    ///
    /// - Parameter response: The response received from the creation request.
    /// - Returns: The response as a `Resource`.
    /// - Throws: A `NetworkError` if any transformation fails (not applicable in this case).
    nonisolated static func resource(from response: CreateResponse, updating resource: Resource?) throws(NetworkError) -> Resource {
        response
    }

}

// MARK: - Readable

/// Represents a resource that can be read from a remote server.
///
/// Types conforming to `Readable` define the necessary types and functions for reading a resource from a server.
/// This includes specifying the types for read requests and responses, and providing methods for making the
/// network request and transforming the responses.
public protocol Readable: RemoteResource {

    /// The type of request used to read the resource.
    associatedtype ReadRequest: Sendable

    /// The type of response returned after reading the resource.
    associatedtype ReadResponse: NetworkSession.DataType

    /// Reads the resource from the remote server using the provided session and request data.
    ///
    /// This method performs an asynchronous network request to read a resource, using the specified session and request.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The read request data.
    /// - Returns: The response object containing the resource data.
    /// - Throws: A `NetworkError` if the request fails.
    static func read(
        using session: NetworkSession,
        request: ReadRequest
    ) async throws(NetworkError) -> ReadResponse

    /// Constructs an `Endpoint` for the read request.
    ///
    /// This method is used to convert the read request data into an `Endpoint` that represents the request details.
    ///
    /// - Parameter request: The read request data.
    /// - Returns: An `Endpoint` that represents the request.
    /// - Throws: A `NetworkError` if the endpoint cannot be created.
    nonisolated static func endpoint(_ request: ReadRequest) throws(NetworkError) -> Endpoint

    /// Transforms an optional `Resource` into a `ReadRequest`.
    ///
    /// This method can be used to generate a `ReadRequest` from a given `Resource`, if applicable.
    ///
    /// - Parameter resource: The optional resource to be transformed into a request.
    /// - Returns: A `ReadRequest` derived from the resource, or `nil` if not applicable.
    /// - Throws: A `NetworkError` if the transformation fails.
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> ReadRequest?

    /// Transforms the read response into a `Resource`.
    ///
    /// This method is used to convert the response data from the read request into a usable `Resource`.
    ///
    /// - Parameter response: The response received from the read request.
    /// - Returns: A `Resource` derived from the response.
    /// - Throws: A `NetworkError` if the transformation fails.
    nonisolated static func resource(from response: ReadResponse, updating resource: Resource?) throws(NetworkError) -> Resource

}

public extension Readable {

    /// Reads the resource from the remote server using the provided session and request data.
    ///
    /// This default implementation performs the network request to read the resource by first obtaining the
    /// `Endpoint` from the `ReadRequest`, then sending the request using the provided `NetworkSession`.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The read request data.
    /// - Returns: The response object containing the resource data.
    /// - Throws: A `NetworkError` if the request fails.
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

    /// Provides a default implementation that returns an empty `Void` request.
    ///
    /// This implementation can be used when the `ReadRequest` type is `Void`, indicating that no request data is needed.
    ///
    /// - Parameter resource: The optional resource to be transformed into a request.
    /// - Returns: An empty `Void` request.
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> ReadRequest? {
        ()
    }

}

public extension Readable where ReadResponse == Resource {

    /// Provides a default implementation that directly returns the response as the `Resource`.
    ///
    /// This implementation can be used when the `ReadResponse` type is the same as the `Resource` type,
    /// allowing the response to be returned directly.
    ///
    /// - Parameter response: The response received from the read request.
    /// - Returns: The response as a `Resource`.
    /// - Throws: A `NetworkError` if any transformation fails (not applicable in this case).
    nonisolated static func resource(from response: ReadResponse, updating resource: Resource?) throws(NetworkError) -> Resource {
        response
    }

}

// MARK: - Query

/// Represents a resource that can be read as a query response from a remote server.
///
/// `Query` extends the `Readable` protocol to add support for resources where the `ReadResponse` is of type `Data`.
/// It provides additional methods for querying and parsing the raw response data.
public protocol Query: Readable where ReadResponse == Data {

    /// Provides the query string for the request.
    ///
    /// This method is used to specify the query parameters for the request.
    ///
    /// - Returns: A string representing the query.
    nonisolated static func query() -> String

}

public extension Query where Resource: Decodable {

    /// Provides a default implementation for parsing the raw response data into a `Resource` using the query.
    ///
    /// This method uses the specified query to extract and decode the data from the response.
    ///
    /// - Parameter response: The raw response data received from the server.
    /// - Returns: The decoded `Resource` object.
    /// - Throws: A `NetworkError` if the parsing or decoding fails.
    nonisolated static func resource(from response: ReadResponse, updating resource: Resource?) throws(NetworkError) -> Resource {
        Sextant.shared.query(response, values: Hitch(string: query())) ?? .placeholder
    }

}

public extension Query {

    /// Reads the raw data from the remote server using the provided session and request data.
    ///
    /// This implementation performs a network request to read the resource as raw data.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The read request data.
    /// - Returns: The raw response data.
    /// - Throws: A `NetworkError` if the request fails.
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

/// Represents a resource that can be updated on a remote server.
///
/// Types conforming to `Updatable` define the necessary types and functions for updating a resource on a server.
/// This includes specifying the types for update requests and responses, and providing methods for making the
/// network request and transforming the responses.
public protocol Updatable: Readable {

    /// The type of request used to update the resource.
    associatedtype UpdateRequest: Sendable

    /// The type of response returned after updating the resource.
    associatedtype UpdateResponse: NetworkSession.DataType

    /// Updates an existing resource on the remote server using the provided session and request data.
    ///
    /// This method performs an asynchronous network request to update a resource, using the specified session and request.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The update request data.
    /// - Returns: The response object containing the updated resource data.
    /// - Throws: A `NetworkError` if the request fails.
    static func update(
        using session: NetworkSession,
        request: UpdateRequest
    ) async throws(NetworkError) -> UpdateResponse

    /// Constructs an `Endpoint` for the update request.
    ///
    /// This method is used to convert the update request data into an `Endpoint` that represents the request details.
    ///
    /// - Parameter request: The update request data.
    /// - Returns: An `Endpoint` that represents the request.
    /// - Throws: A `NetworkError` if the endpoint cannot be created.
    nonisolated static func endpoint(_ request: UpdateRequest) throws(NetworkError) -> Endpoint

    /// Transforms an optional `Resource` into an `UpdateRequest`.
    ///
    /// This method can be used to generate an `UpdateRequest` from a given `Resource`, if applicable.
    ///
    /// - Parameter resource: The optional resource to be transformed into a request.
    /// - Returns: An `UpdateRequest` derived from the resource, or `nil` if not applicable.
    /// - Throws: A `NetworkError` if the transformation fails.
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> UpdateRequest?

    nonisolated static func resource(from response: UpdateResponse, updating resource: Resource?) throws(NetworkError) -> Resource

}

public extension Updatable {

    /// Updates an existing resource on the remote server using the provided session and request data.
    ///
    /// This default implementation performs the network request to update the resource by first obtaining the
    /// `Endpoint` from the `UpdateRequest`, then sending the request using the provided `NetworkSession`.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The update request data.
    /// - Returns: The response object containing the updated resource data.
    /// - Throws: A `NetworkError` if the request fails.
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

    /// Provides a default implementation that directly returns the response as the `Resource`.
    ///
    /// This implementation can be used when the `UpdateResponse` type is the same as the `Resource` type,
    /// allowing the response to be returned directly.
    ///
    /// - Parameter response: The response received from the update request.
    /// - Returns: The response as a `Resource`.
    /// - Throws: A `NetworkError` if any transformation fails (not applicable in this case).
    nonisolated static func resource(from response: UpdateResponse, updating resource: Resource?) throws(NetworkError) -> Resource {
        response
    }

}

// MARK: - Deletable

/// Represents a resource that can be deleted from a remote server.
///
/// Types conforming to `Deletable` define the necessary types and functions for deleting a resource on a server.
/// This includes specifying the types for delete requests and responses, and providing methods for making the
/// network request and transforming the responses.
public protocol Deletable: Readable {

    /// The type of request used to delete the resource.
    associatedtype DeleteRequest: Sendable

    /// The type of response returned after deleting the resource.
    associatedtype DeleteResponse: NetworkSession.DataType

    /// Deletes the resource on the remote server using the provided session and request data.
    ///
    /// This method performs an asynchronous network request to delete a resource, using the specified session and request.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The delete request data.
    /// - Returns: The response object indicating the result of the deletion.
    /// - Throws: A `NetworkError` if the request fails.
    @discardableResult
    static func delete(
        using session: NetworkSession,
        request: DeleteRequest
    ) async throws(NetworkError) -> DeleteResponse

    /// Constructs an `Endpoint` for the delete request.
    ///
    /// This method is used to convert the delete request data into an `Endpoint` that represents the request details.
    ///
    /// - Parameter request: The delete request data.
    /// - Returns: An `Endpoint` that represents the request.
    /// - Throws: A `NetworkError` if the endpoint cannot be created.
    nonisolated static func endpoint(_ request: DeleteRequest) throws(NetworkError) -> Endpoint

    /// Transforms an optional `Resource` into a `DeleteRequest`.
    ///
    /// This method can be used to generate a `DeleteRequest` from a given `Resource`, if applicable.
    ///
    /// - Parameter resource: The optional resource to be transformed into a request.
    /// - Returns: A `DeleteRequest` derived from the resource, or `nil` if not applicable.
    /// - Throws: A `NetworkError` if the transformation fails.
    nonisolated static func request(from resource: Resource?) throws(NetworkError) -> DeleteRequest?

    /// Transforms the delete response into a `Resource`.
    ///
    /// This method is used to convert the response data from the delete request into a usable `Resource`.
    ///
    /// - Parameter response: The response received from the delete request.
    /// - Returns: A `Resource` derived from the response.
    /// - Throws: A `NetworkError` if the transformation fails.
    nonisolated static func resource(from response: DeleteResponse, updating resource: Resource?) throws(NetworkError) -> Resource?

}

public extension Deletable {

    /// Deletes the resource on the remote server using the provided session and request data.
    ///
    /// This default implementation performs the network request to delete the resource by first obtaining the
    /// `Endpoint` from the `DeleteRequest`, then sending the request using the provided `NetworkSession`.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The delete request data.
    /// - Returns: The response object indicating the result of the deletion.
    /// - Throws: A `NetworkError` if the request fails.
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

    /// Provides a default implementation that directly returns the response as the `Resource`.
    ///
    /// This implementation can be used when the `DeleteResponse` type is the same as the `Resource` type,
    /// allowing the response to be returned directly.
    ///
    /// - Parameter response: The response received from the delete request.
    /// - Returns: The response as a `Resource`.
    /// - Throws: A `NetworkError` if any transformation fails (not applicable in this case).
    nonisolated static func resource(from response: DeleteResponse, updating resource: Resource?) throws(NetworkError) -> Resource? {
        response
    }

}
// MARK: - Listable

/// Represents a resource that can be listed (retrieved in bulk) from a remote server.
///
/// Types conforming to `Listable` define the necessary types and functions for retrieving a list of resources from a server.
/// This includes specifying the types for list requests and responses, and providing methods for making the network request,
/// managing pagination, and transforming responses.
public protocol Listable: RemoteResource {

    /// The type of request used to list the resources.
    associatedtype ListRequest: Sendable

    /// The type of response returned after listing the resources.
    associatedtype ListResponse: NetworkSession.DataType

    /// Lists the resources from the remote server using the provided session and request data.
    ///
    /// This method performs an asynchronous network request to retrieve a list of resources, using the specified session and request.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The list request data.
    /// - Returns: The response object containing the list of resources.
    /// - Throws: A `NetworkError` if the request fails.
    static func list(
        using session: NetworkSession,
        request: ListRequest
    ) async throws(NetworkError) -> ListResponse

    /// Constructs an `Endpoint` for the list request.
    ///
    /// This method is used to convert the list request data into an `Endpoint` that represents the request details.
    ///
    /// - Parameter request: The list request data.
    /// - Returns: An `Endpoint` that represents the request.
    /// - Throws: A `NetworkError` if the endpoint cannot be created.
    nonisolated static func endpoint(_ request: ListRequest) throws(NetworkError) -> Endpoint

    /// Provides the first page request for listing resources.
    ///
    /// This method is used to define the initial request for retrieving the first page of resources.
    ///
    /// - Returns: The `ListRequest` representing the first page request.
    nonisolated static func firstPageRequest(withParameters: Any?) -> ListRequest

    nonisolated static func nextPageRequest(
        currentResource: [Resource],
        parameters: Any?,
        lastResponse: ListResponse
    ) -> ListRequest?

    /// Combines the new response with the existing list of resources.
    ///
    /// This method is used to merge the response from the list request with an existing list of resources.
    ///
    /// - Parameters:
    ///   - response: The new response data.
    ///   - oldValue: The existing list of resources.
    /// - Returns: A new array of `Resource` combining the old and new data.
    nonisolated static func list(from response: ListResponse, oldValue: [Resource]) -> [Resource]

}

public extension Listable {

    /// Provides a default implementation for fetching the next page request.
    ///
    /// By default, this method returns `nil`, indicating that pagination is not supported.
    ///
    /// - Parameters:
    ///   - currentResource: The current list of resources.
    ///   - lastResponse: The last response received.
    /// - Returns: `nil` by default, indicating no next page request.
    nonisolated static func nextPageRequest(
        currentResource: [Resource],
        parameters: Any?,
        lastResponse: ListResponse
    ) -> ListRequest? {
        return nil
    }

    /// Lists the resources from the remote server using the provided session and request data.
    ///
    /// This default implementation performs the network request to list the resources by first obtaining the
    /// `Endpoint` from the `ListRequest`, then sending the request using the provided `NetworkSession`.
    ///
    /// - Parameters:
    ///   - session: The network session used to perform the request.
    ///   - request: The list request data.
    /// - Returns: The response object containing the list of resources.
    /// - Throws: A `NetworkError` if the request fails.
    static func list(
        using session: NetworkSession,
        request: ListRequest
    ) async throws(NetworkError) -> ListResponse {
        let endpoint: Endpoint = try Self.endpoint(request)
        let response: ListResponse = try await session.request(endpoint: endpoint)
        return response
    }

}

// MARK: - All CRUD Operations

/// Represents a resource that supports Create, Read, Update, and Delete operations.
///
/// Types conforming to `CRUDable` define the necessary functions to perform all basic CRUD operations (Create, Read, Update, Delete).
/// This protocol combines the individual capabilities of `Creatable`, `Readable`, `Updatable`, and `Deletable`.
public protocol CRUDable: Creatable, Readable, Updatable, Deletable {}

// MARK: - CRUD + Listable

/// Represents a resource that supports full CRUD operations as well as bulk listing.
///
/// Types conforming to `CRUDLable` support all basic CRUD operations (Create, Read, Update, Delete) and also provide
/// capabilities for retrieving lists of resources using the `Listable` protocol.
public protocol CRUDLable: CRUDable, Listable {}
