//
//  DefaultValidationProvider.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 15/10/2024.
//

import Foundation

/// A default implementation of the `ValidationProviding` protocol for handling network response validation.
///
/// `DefaultValidationProvider` uses the standard range of HTTP status codes (200-299) to validate network responses.
/// It throws a `NetworkError` when the status code falls outside this range. Additionally, it provides a method
/// for transforming network errors into the `NetworkError` type.
///
/// This validation provider is useful for basic validation of HTTP responses in network requests.
public struct DefaultValidationProvider: ValidationProviding {

    /// The type of error used when validation fails.
    ///
    /// This provider uses `NetworkError` as the failure type.
    public typealias Failure = NetworkError

    /// Creates an instance of `DefaultValidationProvider`.
    ///
    /// This is the default initializer with no parameters, as it does not require any specific setup.
    public init() {}

    /// Validates the HTTP status code and associated data from a network response.
    ///
    /// This method checks if the provided `statusCode` falls within the 200-299 range. If the status code is outside this range,
    /// a `NetworkError.remote` error is thrown, which includes the status code and the associated response data.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code from the network response.
    ///   - data: The data received from the network response.
    /// - Throws: A `NetworkError.remote` if the status code indicates a failure (outside the 200-299 range).
    public func validate(statusCode: Int, data: Data?) throws(Failure) {
        if statusCode < 200 || statusCode >= 300 {
            throw NetworkError.remote(statusCode: statusCode, data: data)
        }
    }

    /// Transforms a given `NetworkError` into another `NetworkError`.
    ///
    /// In this default implementation, the method simply returns the input error as is, without transforming it.
    /// This can be customized in other implementations to provide more granular error handling.
    ///
    /// - Parameter error: The `NetworkError` to be transformed.
    /// - Returns: The same `NetworkError` passed as input.
    public func transformError(_ error: NetworkError) -> NetworkError {
        error
    }

}
