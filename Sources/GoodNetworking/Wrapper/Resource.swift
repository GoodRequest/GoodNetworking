//
//  Resource.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 08/12/2023.
//

import Alamofire
import SwiftUI
import GoodLogger

// MARK: - Resource

public struct RawResponse: Sendable {

    var create: (Decodable & Sendable)?
    var read: (Decodable & Sendable)?
    var update: (Decodable & Sendable)?
    var delete: (Decodable & Sendable)?
    var list: (Decodable & Sendable)?

}

@available(iOS 17.0, *)
@MainActor @Observable public final class Resource<R: RemoteResource> {

    private var session: FutureSession
    private var rawResponse: RawResponse = RawResponse()
    private var remote: R.Type

    private(set) public var state: ResourceState<R.Resource, NetworkError>
    private var listState: ResourceState<[R.Resource], NetworkError>
    private var listParameters: Any?

    public var value: R.Resource? {
        get {
            state.value
        }
        set {
            if let newValue {
                state = .pending(newValue)
                listState = .pending([newValue])
            } else {
                state = .idle
                listState = .idle
            }
        }
    }

    public init(
        wrappedValue: R.Resource? = nil,
        session: NetworkSession,
        remote: R.Type
    ) {
        self.session = FutureSession { session }
        self.remote = remote

        if let wrappedValue {
            self.state = .available(wrappedValue)
            self.listState = .available([wrappedValue])
        } else {
            self.state = .idle
            self.listState = .idle
        }
    }

    public init(
        session: FutureSession? = nil,
        remote: R.Type
    ) {
        self.session = session ?? .placeholder
        self.remote = remote
        self.state = .idle
        self.listState = .idle
    }

    @discardableResult
    public func session(_ networkSession: NetworkSession) -> Self {
        self.session = FutureSession { networkSession }
        return self
    }

    @discardableResult
    public func session(_ futureSession: FutureSession) -> Self {
        self.session = futureSession
        return self
    }

    @discardableResult
    public func session(_ sessionSupplier: @escaping FutureSession.FutureSessionSupplier) -> Self {
        self.session = FutureSession(sessionSupplier)
        return self
    }

    @discardableResult
    public func initialResource(_ newValue: R.Resource) -> Self {
        self.state = .available(newValue)
        self.listState = .available([newValue])
        return self
    }

}

// MARK: - Operations

@available(iOS 17.0, *)
extension Resource {

    private var logger: GoodLogger {
        if #available(iOS 14, *) {
            return OSLogLogger()
        } else {
            return PrintLogger()
        }
    }

    public func create() async throws {
        logger
            .log(
                message: "CREATE operation not defined for resource \(String(describing: R.self))",
                level: .error,
                privacy: .auto
            )
    }

    public func read(forceReload: Bool = false) async throws {
        logger
            .log(
                message: "READ operation not defined for resource \(String(describing: R.self))",
                level: .error,
                privacy: .auto
            )
    }

    public func updateRemote() async throws {
        logger
            .log(
                message: "UPDATE operation not defined for resource \(String(describing: R.self))",
                level: .error,
                privacy: .auto
            )
    }

    public func delete() async throws {
        logger
            .log(
                message: "DELETE operation not defined for resource \(String(describing: R.self))",
                level: .error,
                privacy: .auto
            )
    }

    public func firstPage(parameters: Any? = nil, forceReload: Bool = false) async throws {
        logger
            .log(
                message: "LIST operation not defined for resource \(String(describing: R.self))",
                level: .error,
                privacy: .auto
            )
        logger.log(message: "Check type of parameters passed to this resource.", level: .error, privacy: .auto)
        logger.log(message: "Current parameters type: \(type(of: parameters))", level: .error, privacy: .auto)
    }

    public func nextPage() async throws {
        logger
            .log(
                message: "LIST operation not defined for resource \(String(describing: R.self))",
                level: .error,
                privacy: .auto
            )
    }

}

// MARK: - Create

@available(iOS 17.0, *)
extension Resource where R: Creatable {

    public func create() async throws {
        guard let request = try R.request(from: state.value) else {
            return logger
                .log(
                    message: "Creating nil resource always fails! Use create(request:) with a custom request or supply a resource to create.",
                    level: .error
                )
        }
        try await create(request: request)
    }

    public func create(request: R.CreateRequest) async throws {
        let resource = state.value
        if let resource {
            self.state = .uploading(resource)
            self.listState = .uploading([resource])
        } else {
            self.state = .loading
            self.listState = .loading
        }

        do {
            let response = try await remote.create(
                using: session(),
                request: request
            )
            self.rawResponse.create = response

            let resource = try R.resource(from: response, updating: resource)
            try Task.checkCancellation()

            self.state = .available(resource)
            self.listState = .available([resource])
        } catch let error as NetworkError {
            if let resource {
                self.state = .stale(resource, error)
                self.listState = .stale([resource], error)
            } else {
                self.state = .failure(error)
                self.listState = .failure(error)
            }

            throw error
        } catch {
            throw error
        }
    }

}

// MARK: - Read

@available(iOS 17.0, *)
extension Resource where R: Readable {

    // forceReload is default true, when resource is already set, calling read() is expected to always reload the data
    public func read(forceReload: Bool = true) async throws {
        let resource = state.value
        guard let request = try R.request(from: resource) else {
            self.state = .idle
            return logger
                .log(
                    message: "Requesting nil resource always fails! Use read(request:forceReload:) with a custom request or supply a resource to read.",
                    level: .error
                )
        }

        try await read(request: request, forceReload: forceReload)
    }

    public func read(request: R.ReadRequest, forceReload: Bool = false) async throws {
        guard !state.isAvailable || forceReload else {
            return logger.log(message: "Skipping read - value already exists", level: .info, privacy: .auto)
        }

        let resource = state.value
        self.state = .loading
        self.listState = .loading

        do {
            let response = try await remote.read(
                using: session(),
                request: request
            )
            self.rawResponse.read = response

            let resource = try R.resource(from: response, updating: resource)
            try Task.checkCancellation()

            self.state = .available(resource)
            self.listState = .available([resource])
        } catch let error as NetworkError {
            if let resource {
                self.state = .stale(resource, error)
                self.listState = .stale([resource], error)
            } else {
                self.state = .failure(error)
                self.listState = .failure(error)
            }

            throw error
        } catch {
            throw error
        }
    }

}

// MARK: - Update

@available(iOS 17.0, *)
extension Resource where R: Updatable {

    public func updateRemote() async throws {
        guard let request = try R.request(from: state.value) else {
            return logger
                .log(
                    message: "Updating resource to nil always fails! Use DELETE instead.",
                    level: .error
                )
        }
        try await updateRemote(request: request)
    }

    public func updateRemote(request: R.UpdateRequest) async throws {
        let resource = state.value
        if let resource {
            self.state = .uploading(resource)
            self.listState = .uploading([resource])
        } else {
            self.state = .loading
            self.listState = .loading
        }

        do {
            let response = try await remote.update(
                using: session(),
                request: request
            )
            self.rawResponse.update = response

            let resource = try R.resource(from: response, updating: resource)
            try Task.checkCancellation()

            self.state = .available(resource)
            self.listState = .available([resource])
        } catch let error as NetworkError {
            if let resource {
                self.state = .stale(resource, error)
                self.listState = .stale([resource], error)
            } else {
                self.state = .failure(error)
                self.listState = .failure(error)
            }

            throw error
        } catch {
            throw error
        }
    }

}

// MARK: - Delete

@available(iOS 17.0, *)
extension Resource where R: Deletable {

    public func delete() async throws {
        guard let request = try R.request(from: state.value) else {
            return logger
                .log(
                    message: "Deleting nil resource always fails. Use delete(request:) with a custom request or supply a resource to delete.",
                    level: .error
                )
        }
        try await delete(request: request)
    }

    public func delete(request: R.DeleteRequest) async throws {
        self.state = .loading
        self.listState = .loading

        do {
            let response = try await remote.delete(
                using: session(),
                request: request
            )
            self.rawResponse.delete = response

            let resource = try R.resource(from: response, updating: state.value)
            try Task.checkCancellation()

            if let resource {
                // case with partial/soft delete only
                self.state = .available(resource)
                self.listState = .available([resource])
            } else {
                self.state = .idle
                #warning("TODO: vymazat z listu iba prave vymazovany element")
                self.listState = .idle
            }
        } catch let error as NetworkError {
            self.state = .failure(error)
            self.listState = .failure(error)

            throw error
        } catch {
            throw error
        }
    }

}

// MARK: - List

@available(iOS 17.0, *)
extension Resource where R: Listable {

    public var elements: [R.Resource] {
        if let list = listState.value {
            return list
        } else {
            return Array.init(repeating: .placeholder, count: 3)
        }
    }

    public var startIndex: Int {
        elements.startIndex
    }

    public var endIndex: Int {
        elements.endIndex
    }

    public func firstPage(parameters: Any? = nil, forceReload: Bool = false) async throws {
        if !(listState.value?.isEmpty ?? true) || forceReload {
            self.listState = .idle
            self.state = .loading
        }
        self.listParameters = parameters

        let firstPageRequest = R.firstPageRequest(withParameters: parameters)
        try await list(request: firstPageRequest)
    }

    public func nextPage() async throws {
        guard let nextPageRequest = nextPageRequest() else { return }
        try await list(request: nextPageRequest)
    }

    internal func nextPageRequest() -> R.ListRequest? {
        guard let currentList = listState.value,
              let lastResponse = rawResponse.list as? R.ListResponse
        else {
            return nil
        }

        return R.nextPageRequest(
            currentResource: currentList,
            parameters: self.listParameters,
            lastResponse: lastResponse
        )
    }

    public func list(request: R.ListRequest) async throws {
        if !state.isAvailable {
            self.state = .loading
        }

        do {
            let response = try await remote.list(
                using: session(),
                request: request
            )
            self.rawResponse.list = response

            let list = R.list(from: response, oldValue: listState.value ?? [])
            self.listState = .available(list)

            let resource = list.first
            if let resource {
                self.state = .available(resource)
            } else {
                self.state = .idle
            }
        } catch let error {
            self.state = .failure(error)
            self.listState = .failure(error)

            throw error
        }
    }

}
