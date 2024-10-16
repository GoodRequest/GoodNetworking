//
//  BaseUrlProviding.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 20/09/2024.
//

import Foundation

/// A protocol for providing the base URL for network requests.
///
/// `BaseUrlProviding` defines a method that asynchronously resolves the base URL used for network requests.
/// Classes or structures that conform to this protocol can implement their own logic for determining and returning the base URL.
public protocol BaseUrlProviding: Sendable {

    /// Resolves and returns the base URL for network requests asynchronously.
    ///
    /// This method is used to fetch or compute the base URL, potentially involving asynchronous operations.
    /// If the base URL cannot be resolved, the method returns `nil`.
    ///
    /// - Returns: The resolved base URL as a `String`, or `nil` if the URL could not be determined.
    func resolveBaseUrl() async -> String?
    
}

extension String: BaseUrlProviding {

    /// Returns the string itself as the base URL.
    ///
    /// This extension allows any `String` instance to conform to `BaseUrlProviding`, returning itself as the base URL.
    ///
    /// - Returns: The string instance as the base URL.
    public func resolveBaseUrl() async -> String? { self }

}
