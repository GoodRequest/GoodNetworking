//
//  Fetch.swift
//  requestWrapper
//
//  Created by Filip Šašala on 08/12/2023.
//

import Alamofire
import Combine
import SwiftUI

/// Fetches data from remote endpoint immediately after initialization.
///
/// Example usage:
/// ```swift
/// @Fetch private var userData = UserDataRequest()
///
/// switch data.result {
/// case .none, .loading:
///     ProgressView()
/// case .success(let userResponse):
///     Text(userResponse.name)
/// case .failure(let error):
///     Text(error.localizedDescription)
/// }
/// ```
@propertyWrapper public struct Fetch<Q: Query>: DynamicProperty {

    @ObservedObject @Observable private var observableQuery: Q
    @ObservedObject @Observable private var dataTask: AnyCancellable?

    private var session: NetworkSession

    public var wrappedValue: Q {
        get { observableQuery }
        nonmutating set {
            let oldValue = observableQuery
            guard newValue != oldValue else { return }

            observableQuery = newValue

            dataTask?.cancel()
            dataTask = nil
            dataTask = makeDataTask(from: newValue)
        }
    }

    public init(wrappedValue: Q, session: NetworkSession = .default) {
        self.session = session

        self._observableQuery = ObservedObject(wrappedValue: Observable(wrappedValue))
        self._dataTask = ObservedObject(wrappedValue: Observable(nil))

        self.dataTask = makeDataTask(from: observableQuery)
    }

    private func makeDataTask(from query: Q) -> AnyCancellable {
        let endpoint = Q.endpoint(query)

        return session.request(endpoint: endpoint)
            .goodify(type: Q.Result.self)
            .receive(on: DispatchQueue.main)
            .map { .success($0) }
            .catch { Just(.failure($0)) }
        #if canImport(GoodStructs)
            .prepend(.loading)
        #endif
        #if DEBUG
            .throttle(for: 1, scheduler: RunLoop.main, latest: true)
        #endif
            .sink { [self] in observableQuery.result = $0 }
    }

}
