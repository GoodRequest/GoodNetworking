//
//  ResultProviding.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 30/01/2025.
//

import Foundation
import Alamofire

/// A protocol for providing results asynchronously from network requests.
///
/// `ResultProviding` defines a method that asynchronously resolves a result of a generic type.
/// Classes or structures that conform to this protocol can implement their own logic for determining and returning the result.
///
/// This protocol is particularly useful for:
/// - Caching network responses
/// - Transforming raw network data into domain models
/// - Implementing custom result resolution strategies
/// - Handling offline-first scenarios
///
/// Example usage:
/// ```swift
/// struct CacheProvider: ResultProviding {
///     func resolveResult<Result: Sendable>(endpoint: Endpoint) async -> Result? {
///         // Check cache and return cached value if available
///         return try? await cache.object(for: endpoint.cacheKey)
///     }
/// }
/// ```
public protocol ResultProviding: Sendable {

    /// Resolves and returns the result asynchronously for a given endpoint.
    ///
    /// This method fetches or computes the result, potentially involving asynchronous operations such as:
    /// - Retrieving data from a local cache
    /// - Transforming network responses
    /// - Applying business logic to raw data
    /// - Combining multiple data sources
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint configuration for which to resolve the result
    /// - Returns: The resolved result of type `Result`, or `nil` if no result could be resolved
    /// - Note: The implementation should be thread-safe and handle errors appropriately
    func resolveResult<Result: Sendable>(endpoint: Endpoint) async -> Result?

}
