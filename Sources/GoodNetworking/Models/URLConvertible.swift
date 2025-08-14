//
//  URLConvertible.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

import Foundation

// MARK: - URLConvertible

/// `URLConvertible` defines a function that asynchronously resolves the base URL used for network requests.
/// Classes or structs that conform to this protocol can implement their own logic for determining and returning the base URL.
public protocol URLConvertible {

    /// Resolves and returns the base URL for network requests asynchronously.
    ///
    /// This method is used to fetch or compute the base URL, potentially involving asynchronous operations.
    /// If the base URL cannot be resolved, the method returns `nil`.
    ///
    /// - Returns: The resolved URL or `nil` if the URL could not be constructed.
    func resolveUrl() async -> URL?

}

// MARK: - Default implementations

extension Optional<URL>: URLConvertible {

    public func resolveUrl() async -> URL? {
        self
    }

}

extension URL: URLConvertible {

    public func resolveUrl() async -> URL? {
        self
    }

}

extension String: URLConvertible {

    public func resolveUrl() async -> URL? {
        URL(string: self)
    }

}
