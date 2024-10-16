//
//  URLExtensions.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/01/2024.
//

@preconcurrency import Alamofire
import Foundation

/// Extends `Optional<URL>` to conform to `Alamofire.URLConvertible`.
///
/// This extension allows an optional `URL` to be used where `Alamofire.URLConvertible` is required.
/// If the optional `URL` contains a value, it is returned. If the optional is `nil`, a `URLError` with the
/// `badURL` code is thrown.
extension Optional<Foundation.URL>: Alamofire.URLConvertible {

    /// Converts the optional `URL` to a non-optional `URL`.
    ///
    /// If the optional contains a `URL`, it is returned. If the optional is `nil`, a `URLError` with the
    /// `badURL` code is thrown, indicating that the URL could not be converted.
    ///
    /// - Throws: A `URLError(.badURL)` if the optional URL is `nil`.
    /// - Returns: The unwrapped `URL` if available.
    public func asURL() throws -> URL {
        guard let self else { throw URLError(.badURL) }
        return self
    }

}
