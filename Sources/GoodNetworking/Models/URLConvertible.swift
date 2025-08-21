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
public protocol URLConvertible: Sendable {

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

// MARK: - Extensions

extension URL {
    
    /// Initialize with optional string.
    ///
    /// Returns `nil` if a `URL` cannot be formed with the string (for example,  if the string
    /// contains characters that are illegal in a URL, or is an empty string, or is `nil`).
    /// - Parameter string: String containing the URL or `nil`
    public init?(_ string: String?) {
        guard let string else { return nil }
        self.init(string: string)
    }
    
    /// Checks if URL contains a non-empty scheme.
    ///
    /// Returns `true` if ``scheme`` is not `nil` and not empty, eg. `https://`
    var hasScheme: Bool {
        if let scheme, !scheme.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    /// Checks if URL contains a non-empty host.
    ///
    /// Returns `true` if ``host`` is not `nil` and not empty, eg. `goodrequest.com`
    var hasHost: Bool {
        if let host, !host.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    /// Checks if URL can be considered an absolute URL.
    ///
    /// Returns `true` if the URL is a file URL or has both host and scheme.
    var isAbsolute: Bool {
        return isFileURL || hasScheme && hasHost
    }
    
}
