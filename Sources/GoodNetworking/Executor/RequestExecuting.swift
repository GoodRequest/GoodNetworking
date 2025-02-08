//
//  RequestExecuting.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 03/02/2025.
//

import Alamofire
import Foundation
import GoodLogger

/// A protocol defining the interface for executing network requests.
///
/// `RequestExecuting` provides a standardized way to execute network requests with proper error handling,
/// validation, and type-safe responses. It is designed to work with Alamofire's Session and supports
/// custom validation and error handling through the ValidationProviding protocol.
///
/// Example usage:
/// ```swift
/// struct RequestExecutor: RequestExecuting {
///     func executeRequest<Result, Failure>(
///         endpoint: Endpoint,
///         session: Session,
///         baseURL: String,
///         validationProvider: ValidationProviding
///     ) async throws -> Result {
///         // Implementation details
///     }
/// }
/// ```
public protocol RequestExecuting: Sendable {

    /// Executes a network request and returns the decoded result.
    ///
    /// This method handles the complete lifecycle of a network request, including:
    /// - Request execution using the provided Alamofire session
    /// - Response validation using the validation provider
    /// - Error handling and transformation
    /// - Response decoding into the specified Result type
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint configuration for the request
    ///   - session: The Alamofire session to use for the request
    ///   - baseURL: The base URL to prepend to the endpoint's path
    ///   - validationProvider: Provider for response validation and error transformation
    /// - Returns: The decoded response of type Result
    /// - Throws: An error of type Failure if the request fails or validation fails
    func executeRequest(
        endpoint: Endpoint,
        session: Session,
        baseURL: String
    ) async -> DataResponse<Data?, AFError>

}
