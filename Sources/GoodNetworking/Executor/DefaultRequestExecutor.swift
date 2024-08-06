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
    public func executeRequest<Result: NetworkSession.DataType, Failure: Error>(
        endpoint: Endpoint,
        session: Session,
        baseURL: String,
        validationProvider: any ValidationProviding<Failure> = DefaultValidationProvider()
    ) async throws(Failure) -> Result {
        return try await catchingFailure(validationProvider: validationProvider) {
            return try await session.request(
                try? endpoint.url(on: baseURL),
                method: endpoint.method,
                parameters: endpoint.parameters?.dictionary,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .goodify(type: Result.self, validator: validationProvider)
            .value
        }
    }

    /// Executes a closure while catching and transforming failures.
    ///
    /// This method provides standardized error handling by:
    /// - Catching and transforming network errors
    /// - Handling Alamofire-specific errors
    /// - Converting errors to the expected failure type
    ///
    /// - Parameters:
    ///   - validationProvider: The provider used to transform any errors.
    ///   - body: The closure to execute.
    /// - Returns: The result of type `Result`.
    /// - Throws: A transformed error if the closure fails.
    func catchingFailure<Result: NetworkSession.DataType, Failure: Error>(
        validationProvider: any ValidationProviding<Failure>,
        body: () async throws -> Result
    ) async throws(Failure) -> Result {
        do {
            return try await body()
        } catch let networkError as NetworkError {
            throw validationProvider.transformError(networkError)
        } catch let error as AFError {
            if let underlyingError = error.underlyingError as? Failure {
                throw underlyingError
            } else if let underlyingError = error.underlyingError as? NetworkError {
                throw validationProvider.transformError(underlyingError)
            } else {
                throw validationProvider.transformError(NetworkError.sessionError)
            }
        } catch {
            throw validationProvider.transformError(NetworkError.sessionError)
        }
    }

}
