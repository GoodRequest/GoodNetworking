//
//  Retrier.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 07/08/2025.
//

import Foundation

// MARK: - Retrier

public protocol Retrier: Sendable {

    func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult

}

// MARK: - Retry result

public enum RetryResult {

    case doNotRetry
    case retryAfter(TimeInterval)
    case retry

}
