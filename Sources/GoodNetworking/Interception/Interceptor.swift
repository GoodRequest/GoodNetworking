//
//  Interceptor.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 07/08/2025.
//

import Foundation

// MARK: - Interceptor

/// Interceptor merges request adaptation and retry behavior.
public protocol Interceptor: Adapter, Retrier {}

// MARK: - Default interceptor

/// Default interceptor does not adapt (modify) requests in any way.
/// Default retrying behaviour is applied as per RFC9110 specification.
///
/// - warning: Retrying is currently not implemented and all requests
/// are resolved as `.doNotRetry`.
public final class DefaultInterceptor: Interceptor {

    public init() {}

    public func adapt(urlRequest: inout URLRequest) async throws(NetworkError) {}

    public func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult {
        #warning("TODO: better default retry logic (handle error type, HTTP method, ...")
        return .doNotRetry
    }

}

// MARK: - Composite interceptor

/// Merges multiple interceptors, adapters and retriers into single interceptor instance.
///
/// Adapters have priority over general interceptors and are executed first when adapting
/// requests. All adapters execute in order they are passed in at initialization.
///
/// Retriers have priority over general interceptors and are executed first when retrying
/// requests. The first retrier to allow retrying the request is used, rest are not executed.
///
/// This behaviour effectively accomplishes that request authentication is executed
/// last, and requests are retried if a specific retrier allows it.
public final class CompositeInterceptor: Interceptor {

    private let interceptors: [Interceptor]
    private let adapters: [Adapter]
    private let retriers: [Retrier]

    public init(
        interceptors: [Interceptor],
        adapters: [Adapter] = [],
        retriers: [Retrier] = []
    ) {
        self.interceptors = interceptors
        self.adapters = adapters
        self.retriers = retriers
    }

    public func adapt(urlRequest: inout URLRequest) async throws(NetworkError) {
        let allAdapters: [Adapter] = adapters + interceptors
        for adapter in allAdapters {
            try await adapter.adapt(urlRequest: &urlRequest)
        }
    }

    public func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult {
        let allRetriers: [Retrier] = retriers + interceptors
        for retrier in allRetriers {
            let retryResult = try await retrier.retry(urlRequest: &urlRequest, for: session, dueTo: error)
            switch retryResult {
            case .doNotRetry:
                continue
            case .retry, .retryAfter:
                return retryResult
            }
        }
        return .doNotRetry
    }

}
