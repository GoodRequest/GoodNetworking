//
//  DeduplicatingResultProvider.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 03/02/2025.
//

import Foundation

/// A protocol for providing results asynchronously.
///
/// `ResultProviding` defines a method that asynchronously resolves a result of a generic type.
/// Classes or structures that conform to this protocol can implement their own logic for determining and returning the result.
public actor DeduplicatingResultProvider: ResultProviding, Sendable {

    // Shared in-memory cache
    private static var cache: [String: (value: Sendable, finishDate: Date)] = [:]

    private let taskId: String
    private let cacheTimeout: TimeInterval
    private var shouldUpdateOnStore: Bool = false

    /// A private property that provides the logger
    private var logger: NetworkLogger?

    public init(taskId: String, cacheTimeout: TimeInterval = 6, logger: NetworkLogger?) {
        self.taskId = taskId
        self.cacheTimeout = cacheTimeout
        self.logger = logger
    }

    /// Generates a unique cache key using the endpoint and taskId
    private func cacheKey(for endpoint: Endpoint) -> String {
        return "\(taskId)_\(endpoint.path)"
    }

    /// Checks if the cached response has expired
    private func isCacheValid(for key: String) -> Bool {
        guard let cachedEntry = Self.cache[key] else { return false }
        return Date().timeIntervalSince(cachedEntry.finishDate) < cacheTimeout
    }

    /// Stores a result in the cache manually (Can be called externally)
    public func storeResult<Result: Sendable>(_ result: Result, for endpoint: Endpoint) async {
        let key = cacheKey(for: endpoint)

        if shouldUpdateOnStore {
            shouldUpdateOnStore = false
            Self.cache[key] = (value: result, finishDate: Date())
            logger?.logNetworkEvent(message: "Value updated for \(key)", level: .info, fileName: #file, lineNumber: #line)
        } else {
            logger?.logNetworkEvent(message: "Already cached \(key)", level: .info, fileName: #file, lineNumber: #line)
        }
    }

    /// Resolves and returns the result asynchronously.
    ///
    /// This method fetches or computes the result, potentially involving asynchronous operations.
    ///
    /// - Returns: The resolved result.
    public func resolveResult<Result: Sendable>(endpoint: Endpoint) async -> Result? {
        let key = cacheKey(for: endpoint)

        // Return cached response if available and valid
        if isCacheValid(for: key), let cachedValue = Self.cache[key]?.value as? Result {
            logger?.logNetworkEvent(message: "Cache hit for \(key)", level: .info, fileName: #file, lineNumber: #line)
            return cachedValue
        } else {
            shouldUpdateOnStore = true
            return nil
        }
    }

}
