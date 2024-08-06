//
//  DeduplicatingRequestExecutor.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 04/02/2025.
//

import Alamofire
import Foundation
import GoodLogger

/// A request executor that deduplicates concurrent requests and provides caching capabilities.
///
/// `DeduplicatingRequestExecutor` implements the `RequestExecuting` protocol and provides additional functionality to:
/// - Deduplicate concurrent requests to the same endpoint by reusing in-flight requests
/// - Cache successful responses for a configurable duration
/// - Clean up expired cache entries automatically
///
/// Example usage:
/// ```swift
/// let executor = DeduplicatingRequestExecutor(taskID: "user_profile", cacheTimeout: 300)
/// let result: UserProfile = try await executor.executeRequest(
///     endpoint: endpoint,
///     session: session,
///     baseURL: "https://api.example.com"
/// )
/// ```
public final actor DeduplicatingRequestExecutor: RequestExecuting, Sendable {

    /// A unique identifier used to track and deduplicate requests
    private let taskID: String
    
    /// The duration in seconds for which successful responses are cached
    private let cacheTimeout: TimeInterval
    
    /// A dictionary storing currently running or cached request tasks
    public var runningRequestTasks: [String: ExecutorTask] = [:]

    /// A private property that provides the appropriate logger based on the iOS version.
    ///
    /// For iOS 14 and later, it uses `OSLogLogger`. For earlier versions, it defaults to `PrintLogger`.
    private var logger: GoodLogger

    /// Creates a new deduplicating request executor.
    ///
    /// - Parameters:
    ///   - taskID: A unique identifier for deduplicating requests
    ///   - cacheTimeout: The duration in seconds for which successful responses are cached. Defaults to 6 seconds.
    ///                   Set to 0 to disable caching.
    public init(taskID: String, cacheTimeout: TimeInterval = 6, logger: GoodLogger? = nil) {
        if let logger {
            self.logger = logger
        } else {
            if #available(iOS 14, *) {
                self.logger = OSLogLogger(logMetaData: false)
            } else {
                self.logger = PrintLogger(logMetaData: false)
            }
        }
        self.taskID = taskID
        self.cacheTimeout = cacheTimeout
    }

    /// Executes a network request with deduplication and caching support.
    ///
    /// This method extends the base `RequestExecuting` functionality by:
    /// - Returning cached responses if available and not expired
    /// - Reusing in-flight requests to the same endpoint
    /// - Caching successful responses for the configured timeout duration
    /// - Automatically cleaning up expired cache entries
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
        runningRequestTasks = runningRequestTasks.filter { !$0.value.exceedsTimeout }

        return try await catchingFailure(validationProvider: validationProvider) {
            if let runningTask = runningRequestTasks[taskID] {
                logger.log(message: "🚀 taskID: \(taskID) Cached value used", level: .info)
                let dataResponse = await runningTask.task.value
                switch dataResponse.result {
                case .success(let value):
                    if let result = value as? Result {
                        return result
                    } else {
                        throw validationProvider.transformError(NetworkError.sessionError)
                    }
                case .failure(let error):
                    throw error
                }
            } else {
                let requestTask = ExecutorTask.TaskType {
                    let result = await session.request(
                        try? endpoint.url(on: baseURL),
                        method: endpoint.method,
                        parameters: endpoint.parameters?.dictionary,
                        encoding: endpoint.encoding,
                        headers: endpoint.headers
                    )
                        .goodify(type: Result.self, validator: validationProvider)
                        .response

                    return result.map { $0 as Result }
                }

                logger.log(message: "🚀 taskID: \(taskID): Task created", level: .info)

                let executorTask: ExecutorTask = ExecutorTask(
                    taskID: taskID,
                    task: requestTask as ExecutorTask.TaskType,
                    cacheTimeout: cacheTimeout
                )

                runningRequestTasks[taskID] = executorTask

                let dataResponse = await requestTask.value
                switch dataResponse.result {
                case .success(let value):
                    logger.log(message: "🚀 taskID: \(taskID): Task finished successfully", level: .info)
                    if cacheTimeout > 0 {
                        runningRequestTasks[taskID]?.finishDate = Date()
                    } else {
                        runningRequestTasks[taskID] = nil
                    }

                    guard let result = value as? Result else {
                        throw validationProvider.transformError(NetworkError.sessionError)
                    }
                    return result

                case .failure(let error):
                    logger.log(message: "🚀 taskID: \(taskID): Task finished with error", level: .error)
                    runningRequestTasks[taskID] = nil
                    throw error
                }
            }
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
