//
//  Post.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 03/01/2024.
//

import Alamofire
import Combine
import SwiftUI

/// Posts data to remote endpoint when requested.
/// See ``Post/response(_:)`` (or ``Post/responseEither(_:)`` when
/// GoodStructs is available).
///
/// When response data is required at the moment of initialization (eg. when a screen is presented),
/// using ``Fetch`` is preferred, as the result is non-optional.
///
/// Resulting data has 4 possible states:
///  - none (no request has been sent yet)
///  - loading (request is being processed)
///  - success (request succeeded, state has associated value containing the response)
///  - failure (request failed, state has associated value containing the error)
///
/// Usage with async/await API:
/// ```swift
/// @Post private var authorization: AuthRequest?
///
/// let response = await _authorization.response(AuthRequest(
///     email: "mail@example.com",
///     password: "p4ssw0rd"
/// ))
/// ```
///
/// Asynchronous usage:
/// ```swift
/// @Post private var authorization: AuthRequest?
///
/// authorization = AuthRequest(
///     email: "mail@example.com",
///     password: "p4ssw0rd"
/// )
///
/// if let error = try? authorization?.result?.unwrapFailure() {
///     Text(error.localizedDescription)
/// }
/// ```
@propertyWrapper public struct Post<Q: Query>: DynamicProperty {

    @ObservedObject @ObservableValue private var observableQuery: Q?
    @ObservedObject @ObservableValue private var dataTask: AnyCancellable?

    private let session: NetworkSession

    public var wrappedValue: Q? {
        get { observableQuery }
        nonmutating set {
            let oldValue = observableQuery
            guard newValue != oldValue else { return }

            observableQuery = newValue

            dataTask?.cancel()
            dataTask = nil

            guard let newValue else { return }
            dataTask = makeDataTask(from: newValue)
        }
    }

    public init(wrappedValue: Q? = nil, session: NetworkSession = .default) {
        self.session = session

        self._observableQuery = ObservedObject(wrappedValue: ObservableValue(wrappedValue))
        self._dataTask = ObservedObject(wrappedValue: ObservableValue(nil))

        guard let wrappedValue else { return }
        self.dataTask = makeDataTask(from: wrappedValue)
    }

    private func makeDataTask(from query: Q) -> AnyCancellable {
        query.dataTaskPublisher(using: session)
            .sink { [self] in observableQuery?.result = $0 }
    }

}

@available(iOS 15.0, *)
public extension Post where Q: Query {

    @discardableResult
    func response(_ value: Q) async throws -> Q.Result {
        let resultPublisher = _observableQuery.wrappedValue.$wrappedValue.map { $0?.result }
        self.wrappedValue = value

        for await result in resultPublisher.values {
            switch result {
            case .none:
                continue

            #if canImport(GoodStructs)
            case .loading:
                continue
            #endif

            case .success(let result):
                return result

            case .failure(let error):
                throw error
            }
        }

        throw AFError.explicitlyCancelled
    }

}

#if canImport(GoodStructs)
import GoodStructs

@available(iOS 15.0, *)
public extension Post where Q: Query {

    @discardableResult
    func responseEither(_ value: Q) async -> Either<Q.Result, AFError> {
        let resultPublisher = _observableQuery.wrappedValue.$wrappedValue.map { $0?.result }
        self.wrappedValue = value

        for await result in resultPublisher.values {
            switch result {
            case .none, .loading:
                continue

            case .success(let result):
                return .left(result)

            case .failure(let error):
                return .right(error)
            }
        }

        return .right(.explicitlyCancelled)
    }

}
#endif
