//
//  Interceptor.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 07/08/2025.
//

import Foundation

// MARK: - Interceptor

public protocol Interceptor: Adapter, Retrier {}

// MARK: - No interceptor

public final class NoInterceptor: Interceptor {

    public init() {}

    public func adapt(urlRequest: inout URLRequest) async throws(NetworkError) {}

    public func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult {
        return .doNotRetry
    }

}

// MARK: - Composite interceptor

public final class CompositeInterceptor: Interceptor {

    private let interceptors: [Interceptor]

    public init(interceptors: [Interceptor]) {
        self.interceptors = interceptors
    }

    public func adapt(urlRequest: inout URLRequest) async throws(NetworkError) {
        for adapter in interceptors {
            try await adapter.adapt(urlRequest: &urlRequest)
        }
    }

    public func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult {
        for retrier in interceptors {
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
