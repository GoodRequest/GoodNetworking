//
//  DeduplicatingResultProvider.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 03/02/2025.
//

import Foundation
import GoodLogger
import GoodNetworking

/// A sample implementation of a deduplicating result provider that caches responses in memory.
///
/// This is a sample implementation showing how to use the `ResultProviding` protocol to cache and deduplicate
/// network requests. It should not be used in production code directly, but rather serve as an example
/// of how to implement similar functionality.
///
/// The provider uses a static cache to store responses and implements basic timeout-based invalidation.
/// For production use cases, consider:
/// - Using a more robust caching mechanism
/// - Implementing proper cache eviction
/// - Adding thread safety mechanisms
/// - Handling cache invalidation on memory warnings
/// - Adding proper error handling
public actor SampleDeduplicatingResultProvider: ResultProviding, Sendable {

    // Sample in-memory cache - not recommended for production use
    private static var cache: [String: (value: Sendable, finishDate: Date)] = [:]

    private let taskId: String
    private let cacheTimeout: TimeInterval
    private var shouldUpdateOnStore: Bool = false

    /// A private property that provides the appropriate logger based on the iOS version.
    /// This is just for demonstration purposes.
    ///
    /// For iOS 14 and later, it uses `OSLogLogger`. For earlier versions, it defaults to `PrintLogger`.
    private var logger: GoodLogger {
        if #available(iOS 14, *) {
            return OSLogLogger(logMetaData: false)
        } else {
            return PrintLogger(logMetaData: false)
        }
    }

    /// Creates a new instance of the sample deduplicating provider
    /// - Parameters:
    ///   - taskId: A unique identifier for the task
    ///   - cacheTimeout: How long cached values remain valid (in seconds)
    public init(taskId: String, cacheTimeout: TimeInterval = 6) {
        self.taskId = taskId
        self.cacheTimeout = cacheTimeout
    }

    /// Generates a unique cache key using the endpoint and taskId.
    /// This is a simple implementation for demonstration purposes.
    private func cacheKey(for endpoint: Endpoint) -> String {
        return "\(taskId)_\(endpoint.path)"
    }

    /// Checks if the cached response has expired.
    /// This is a basic timeout-based implementation for demonstration.
    private func isCacheValid(for key: String) -> Bool {
        guard let cachedEntry = Self.cache[key] else { return false }
        return Date().timeIntervalSince(cachedEntry.finishDate) < cacheTimeout
    }

    /// Stores a result in the cache manually (Can be called externally).
    /// This is a simplified implementation for demonstration purposes.
    public func storeResult<Result: Sendable>(_ result: Result, for endpoint: Endpoint) async {
        let key = cacheKey(for: endpoint)

        if shouldUpdateOnStore {
            shouldUpdateOnStore = false
            Self.cache[key] = (value: result, finishDate: Date())
            logger.log(message: "Value updated for \(key)")
        } else {
            logger.log(message: print("Already cached \(key)"))
        }
    }

    /// Resolves and returns the result asynchronously.
    /// This is a sample implementation showing basic caching behavior.
    ///
    /// - Parameter endpoint: The endpoint to resolve the result for
    /// - Returns: The cached result if available and valid, nil otherwise
    public func resolveResult<Result: Sendable>(endpoint: Endpoint) async -> Result? {
        let key = cacheKey(for: endpoint)

        // Return cached response if available and valid
        if isCacheValid(for: key), let cachedValue = Self.cache[key]?.value as? Result {
            logger.log(message: "Cache hit for \(key)")
            return cachedValue
        } else {
            shouldUpdateOnStore = true
            return nil
        }
    }

}
