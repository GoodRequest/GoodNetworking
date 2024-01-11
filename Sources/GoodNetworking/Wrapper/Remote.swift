//
//  Remote.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 04/01/2024.
//

import Alamofire
import Combine
import SwiftUI

@propertyWrapper public struct Remote<R: Resource>: DynamicProperty {

    @ObservedObject @Observable private var resourceState: ResourceState<R>
    @ObservedObject @Observable private var dataTask: AnyCancellable?

    private let session: NetworkSession
    private let debounce: TimeInterval

    public var wrappedValue: ResourceState<R> {
        get { resourceState }
        nonmutating set {
            let oldValue = resourceState
            guard newValue.resource != oldValue.resource else { return }

            dataTask?.cancel()
            dataTask = nil

            #warning("TODO: deep diff")
            resourceState = newValue

            guard let resource = newValue.resource else { return }
            dataTask = makeDataTask(for: resource)
        }
    }

    public var projectedValue: Binding<R> {
        Binding(get: {
            if wrappedValue.isAvailable {
                return wrappedValue.unwrapped
            } else {
                return R.placeholder
            }
        }, set: { newValue in
            self.wrappedValue = .pending(newValue)
        })
    }

    public init(
        wrappedValue: ResourceState<R>,
        debounce: TimeInterval = 1,
        session: NetworkSession = .default
    ) {
        self.session = session
        self.debounce = debounce

        self._resourceState = ObservedObject(wrappedValue: Observable(wrappedValue))
        self._dataTask = ObservedObject(wrappedValue: Observable(nil))
    }

    private func makeDataTask(for resource: R) -> AnyCancellable {
        let debounce = Just(false).delay(for: RunLoop.SchedulerTimeType.Stride(debounce), scheduler: RunLoop.main)
        let publisher = resource.dataTaskPublisher(using: session)

        return debounce.flatMap { _ in publisher }
            .sink { [self] in resourceState = $0 }
    }

}

// MARK: - Query init

extension Remote {

    public init<Q: Query>(
        wrappedValue: Q,
        debounce: TimeInterval = 1,
        session: NetworkSession = .default,
        using mapping: @escaping (Q.Result?) -> R?
    ) {
        self.session = session
        self.debounce = debounce

        self._resourceState = ObservedObject(wrappedValue: Observable(.loading))
        self._dataTask = ObservedObject(wrappedValue: Observable(nil))

        dataTask = makeDataTask(from: wrappedValue, mapping: mapping)
    }

    public init<Q: Query>(
        wrappedValue: Q,
        debounce: TimeInterval = 1,
        session: NetworkSession = .default
    ) where Q.Result == R {
        self.session = session
        self.debounce = debounce

        self._resourceState = ObservedObject(wrappedValue: Observable(.loading))
        self._dataTask = ObservedObject(wrappedValue: Observable(nil))

        dataTask = makeDataTask(from: wrappedValue, mapping: { $0 })
    }

    private func makeDataTask<Q: Query>(from query: Q, mapping: @escaping (Q.Result?) -> R?) -> AnyCancellable {
        query.dataTaskPublisher(using: session)
            .sink { [self] result in
                switch result {
                case .loading:
                    self.resourceState = .loading

                case .success(let result):
                    if let queryResult = mapping(result) {
                        self.resourceState = .available(queryResult)
                    } else {
                        self.resourceState = .unavailable
                    }

                case .failure(let error):
                    if let currentResource = self.resourceState.resource {
                        self.resourceState = .stale(currentResource, error)
                    } else {
                        self.resourceState = .unavailable
                    }
                }
            }
    }

}
