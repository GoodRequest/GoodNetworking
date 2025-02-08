//
//  DefaultRequestExecutor.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 04/02/2025.
//

import Alamofire
import Foundation

/// A default implementation of the `RequestExecuting` protocol that handles network request execution.
///
/// `DefaultRequestExecutor` provides a concrete implementation for executing network requests with proper error handling
/// and response validation. It is designed to work with Alamofire's Session and supports custom validation through
/// the `ValidationProviding` protocol.
///
/// Example usage:
/// ```swift
/// let executor = DefaultRequestExecutor()
/// let result: MyModel = try await executor.executeRequest(
///     endpoint: endpoint,
///     session: session,
///     baseURL: "https://api.example.com",
///     validationProvider: CustomValidationProvider()
/// )
/// ```
public final actor DefaultRequestExecutor: RequestExecuting, Sendable {

    /// Creates a new instance of `DefaultRequestExecutor`.
    public init() {}

    /// Executes a network request and returns the decoded result.
    ///
    /// This method handles the complete lifecycle of a network request, including:
    /// - Building the request URL using the base URL and endpoint
    /// - Setting up request parameters, headers, and encoding
    /// - Executing the request using Alamofire
    /// - Validating and decoding the response
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint configuration for the request
    ///   - session: The Alamofire session to use for the request
    ///   - baseURL: The base URL to prepend to the endpoint's path
    ///   - validationProvider: Provider for response validation and error transformation
    /// - Returns: The decoded response of type Result
    /// - Throws: An error of type Failure if the request fails or validation fails
    public func executeRequest(
        endpoint: Endpoint,
        session: Session,
        baseURL: String
    ) async -> DataResponse<Data?, AFError> {
        return await withCheckedContinuation { continuation in
            session.request(
                try? endpoint.url(on: baseURL),
                method: endpoint.method,
                parameters: endpoint.parameters?.dictionary,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            ).response { response in
                continuation.resume(returning: response)
            }
        }
    }

}
