//
//  ValidationProviding.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 15/10/2024.
//

import Foundation

/// A protocol for providing validation and error transformation in network requests.
///
/// `ValidationProviding` defines the methods required to validate HTTP response codes and data, as well as transforming
/// network errors into more specific error types for better handling.
///
/// - Type Parameters:
///   - Failure: The error type that conforms to `Error` and is used when validation fails.
public protocol ValidationProviding<Failure>: Sendable where Failure: Error {

    associatedtype Failure: Error

    /// Validates the HTTP status code and the corresponding data received from the network response.
    ///
    /// This method is intended to check whether the response's status code is acceptable and whether the received data
    /// conforms to expected standards. If validation fails, the function throws the specified `Failure` error.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code from the network response.
    ///   - data: The data received from the network response.
    /// - Throws: A `Failure` error if the validation fails.
    func validate(statusCode: Int, data: Data?) throws(Failure)

    /// Transforms a general `NetworkError` into a specific error of type `Failure`.
    ///
    /// This method converts a generic network error into a more context-specific `Failure` error type, allowing
    /// more granular handling of different error conditions.
    ///
    /// - Parameter error: The general network error that occurred.
    /// - Returns: A transformed `Failure` error.
    func transformError(_ error: NetworkError) -> Failure

}
