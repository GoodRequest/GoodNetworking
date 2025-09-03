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

/// Result of a retry operation.
///
/// See ``Retrier``.
public enum RetryResult: Sendable {

    /// Request will not be retried
    case doNotRetry
    
    /// Request will be retried only after the specified time interval has passed
    case retryAfter(TimeInterval)
    
    /// Request will be retried immediately
    case retry

}
