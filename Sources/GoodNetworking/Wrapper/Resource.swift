//
//  Resource.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 08/12/2023.
//

import Alamofire
import SwiftUI

// MARK: - Resource

public struct RawResponse: Sendable {

    var create: (Decodable & Sendable)?
    var read: (Decodable & Sendable)?
    var update: (Decodable & Sendable)?
    var delete: (Decodable & Sendable)?
    var list: (Decodable & Sendable)?

}

@propertyWrapper public struct Resource<R: Remote>: DynamicProperty, Sendable {

    private let session: NetworkSession

    @State private var _remote: R
    @State private var _state: ResourceState<R.Resource, NetworkError>
    @State private var _listState: ResourceState<[R.Resource], NetworkError>
    @State private var _rawResponse: RawResponse = RawResponse()

    public var wrappedValue: R.Resource? {
        get {
            state.value
        }
        nonmutating set {
            updateResource(newValue: newValue)
        }
    }

    private var remote: R {
        @storageRestrictions(initializes: __remote)
        init { __remote = State(initialValue: newValue) }
        get { _remote }
        nonmutating set { _remote = newValue }
    }

    public var state: ResourceState<R.Resource, NetworkError> {
        @storageRestrictions(initializes: __state)
        init { __state = State(initialValue: newValue) }
        get { _state }
        nonmutating set { _state = newValue }
    }

    public var listState: ResourceState<[R.Resource], NetworkError> {
        @storageRestrictions(initializes: __listState)
        init { __listState = State(initialValue: newValue) }
        get { _listState }
        nonmutating set { _listState = newValue }
    }

    public var rawResponse: RawResponse {
        get { _rawResponse }
        nonmutating set { _rawResponse = newValue }
    }

    public var projectedValue: Binding<R.Resource?> {
        Binding(get: {
            wrappedValue
        }, set: { newValue in
            wrappedValue = newValue
        })
    }

    public init(
        wrappedValue: R.Resource? = nil,
        session: NetworkSession,
        remote: R
    ) {
        self.session = session
        self.remote = remote

        if let wrappedValue {
            self.state = .available(wrappedValue)
            self.listState = .available([wrappedValue])
        } else {
            self.state = .idle
            self.listState = .idle
        }
    }

    private func updateResource(newValue: R.Resource?) {
        guard let newValue else {
            Task { await delete() }
            return
        }
        state = .pending(newValue)
        if state.value == nil {
            Task { await create() }
        } else if newValue != state.value {
            Task { await updateRemote() }
        }
    }

}

// MARK: - Operations

extension Resource {

    private var logger: SessionLogger {
        if #available(iOS 14, *) {
            return OSLogLogger()
        } else {
            return PrintLogger()
        }
    }

    public func create() async {
        logger.log(level: .error, message: "CREATE operation not defined for resource \(String(describing: R.self))")
    }

    public func read(forceReload: Bool = false) async {
        logger.log(level: .error, message: "READ operation not defined for resource \(String(describing: R.self))")
    }

    public func updateRemote() async {
        logger.log(level: .error, message: "UPDATE operation not defined for resource \(String(describing: R.self))")
    }

    public func delete() async {
        logger.log(level: .error, message: "DELETE operation not defined for resource \(String(describing: R.self))")
    }

    public func firstPage(forceReload: Bool = false) async {
        logger.log(level: .error, message: "LIST operation not defined for resource \(String(describing: R.self))")
    }

    public func nextPage() async {
        logger.log(level: .error, message: "LIST operation not defined for resource \(String(describing: R.self))")
    }

}

// MARK: - Create

extension Resource where R: RemoteCreate {

    public func create() async {
        guard let request = try? R.request(from: state.value) else { return }
        await create(request: request)
    }

    public func create(request: R.CreateRequest) async {
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
                using: session,
                request: request
            )
            self.rawResponse.create = response

            let resource = try R.resource(from: response)

            self.state = .available(resource)
            self.listState = .available([resource])
        } catch let error {
            if let resource {
                self.state = .stale(resource, error)
                self.listState = .stale([resource], error)
            } else {
                self.state = .failure(error)
                self.listState = .failure(error)
            }
        }
    }

}

// MARK: - Read

extension Resource where R: RemoteRead {

    public func read(forceReload: Bool = false) async {
        let resource = state.value
        guard let request = try? R.request(from: resource) else {
            self.state = .idle
            return
        }

        await read(request: request, forceReload: forceReload)
    }

    public func read(request: R.ReadRequest, forceReload: Bool = false) async {
        guard !state.isAvailable || forceReload else { return }

        self.state = .loading
        self.listState = .loading

        do {
            let response = try await remote.read(
                using: session,
                request: request
            )
            self.rawResponse.read = response

            let resource = try R.resource(from: response)

            self.state = .available(resource)
            self.listState = .available([resource])
        } catch let error {
            self.state = .failure(error)
            self.listState = .failure(error)
        }
    }

}

// MARK: - Update

extension Resource where R: RemoteUpdate {

    public func updateRemote() async {
        guard let request = try? R.request(from: state.value) else { return }
        await updateRemote(request: request)
    }

    public func updateRemote(request: R.UpdateRequest) async {
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
                using: session,
                request: request
            )
            self.rawResponse.update = response

            let resource = try R.resource(from: response)

            self.state = .available(resource)
            self.listState = .available([resource])
        } catch let error {
            if let resource {
                self.state = .stale(resource, error)
                self.listState = .stale([resource], error)
            } else {
                self.state = .failure(error)
                self.listState = .failure(error)
            }
        }
    }

}

// MARK: - Delete

extension Resource where R: RemoteDelete {

    public func delete() async {
        guard let request = try? R.request(from: state.value) else { return }
        await delete(request: request)
    }

    public func delete(request: R.DeleteRequest) async {
        self.state = .loading
        self.listState = .loading

        do {
            let response = try await remote.delete(
                using: session,
                request: request
            )
            self.rawResponse.delete = response

            self.state = .idle
            self.listState = .idle
        } catch let error {
            self.state = .failure(error)
            self.listState = .failure(error)
        }
    }

}

// MARK: - List

extension Resource: Sequence where R: RemoteList {

    public typealias Element = R.Resource

}

extension Resource: Collection where R: RemoteList {

    internal var listElements: [R.Resource] {
        if let list = listState.value {
            return list
        } else {
            return Array.init(repeating: .placeholder, count: 3)
        }
    }

    public subscript(position: Int) -> R.Resource {
        _read {
            if listElements.indices.contains(position) {
                yield listElements[position]
            } else {
                yield .placeholder
            }
        }
    }

}
extension Resource: BidirectionalCollection where R: RemoteList {}

extension Resource: RandomAccessCollection where R: RemoteList {

    public var startIndex: Int {
        listElements.startIndex
    }

    public var endIndex: Int {
        listElements.endIndex
    }

    public func firstPage(forceReload: Bool = false) async {
        if !(listState.value?.isEmpty ?? true) || forceReload {
            self.listState = .idle
            self.state = .loading
        }

        let firstPageRequest = R.firstPageRequest()
        await list(request: firstPageRequest)
    }

    public func nextPage() async {
        guard let nextPageRequest = nextPageRequest() else { return }
        await list(request: nextPageRequest)
    }

    internal func nextPageRequest() -> R.ListRequest? {
        guard let currentList = listState.value,
              let lastResponse = rawResponse.list as? R.ListResponse
        else {
            return nil
        }

        return R.nextPageRequest(
            currentResource: currentList,
            lastResponse: lastResponse
        )
    }

    public func list(request: R.ListRequest) async {
        if !state.isAvailable {
            self.state = .loading
        }

        do {
            let response = try await remote.list(
                using: session,
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
        }
    }

}

@available(iOS 14.0, *)
public struct ResourcePager<R: RemoteList>: View {

    @State private var isFinished = false
    private let resource: () -> Resource<R>

    public init(resource: @escaping @autoclosure () -> Resource<R>) {
        self.resource = resource
    }

    public var body: some View {
        Group {
            if !isFinished {
                ProgressView()
            } else {
                Rectangle().frame(width: 0, height: 0).hidden()
            }
        }
        .onAppear { Task.detached { await getNextPage() }}
    }

    private func getNextPage() async {
        if let nextPage = resource().nextPageRequest() {
            isFinished = false
            await resource().list(request: nextPage)
        } else {
            isFinished = true
        }
    }

}
