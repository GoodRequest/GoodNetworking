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
/// let executor = DeduplicatingRequestExecutor(taskId: "user_profile", cacheTimeout: 300)
/// let result: UserProfile = try await executor.executeRequest(
///     endpoint: endpoint,
///     session: session,
///     baseURL: "https://api.example.com"
/// )
/// ```
public final actor DeduplicatingRequestExecutor: RequestExecuting, Sendable, Identifiable {

    /// A unique identifier used to track and deduplicate requests
    private let taskId: String?

    #warning("Timeout should be configurable based on taskId")
    /// The duration in seconds for which successful responses are cached
    private let cacheTimeout: TimeInterval

    /// A dictionary storing currently running or cached request tasks
    public static var runningRequestTasks: [String: ExecutorTask] = [:]

    /// A private property that provides the appropriate logger based on the iOS version.
    ///
    /// For iOS 14 and later, it uses `OSLogLogger`. For earlier versions, it defaults to `PrintLogger`.
    private var logger: GoodLogger

    /// Creates a new deduplicating request executor.
    ///
    /// - Parameters:
    ///   - taskId: A unique identifier for deduplicating requests
    ///   - cacheTimeout: The duration in seconds for which successful responses are cached. Defaults to 6 seconds.
    ///                   Set to 0 to disable caching.
    public init(taskId: String? = nil, cacheTimeout: TimeInterval = 6, logger: GoodLogger? = nil) {
        if let logger {
            self.logger = logger
        } else {
            if #available(iOS 14, *) {
                self.logger = OSLogLogger(logMetaData: false)
            } else {
                self.logger = PrintLogger(logMetaData: false)
            }
        }
        self.taskId = taskId
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
    public func executeRequest(
        endpoint: Endpoint,
        session: Session,
        baseURL: String
    ) async -> DataResponse<Data?, AFError> {
        DeduplicatingRequestExecutor.runningRequestTasks = DeduplicatingRequestExecutor.runningRequestTasks
            .filter { !$0.value.exceedsTimeout }

            guard let taskId = self.taskId ?? (try? endpoint.url(on: baseURL).absoluteString) else {
                return DataResponse(
                    request: nil,
                    response: nil,
                    data: nil,
                    metrics: nil,
                    serializationDuration: 0.0,
                    result: .failure(.invalidURL(url: URL(string: "\(baseURL)/\(endpoint.path)")))
                )
            }
        
            if let runningTask = DeduplicatingRequestExecutor.runningRequestTasks[taskId] {
                logger.log(message: "🚀 taskId: \(taskId) Cached value used", level: .info)
                return await runningTask.task.value
            } else {
                let requestTask = ExecutorTask.TaskType {
                    return await withCheckedContinuation { continuation in
                        session.request(
                            try? endpoint.url(on: baseURL),
                            method: endpoint.method,
                            parameters: endpoint.parameters?.dictionary,
                            encoding: endpoint.encoding,
                            headers: endpoint.headers
                        )
                        .validate()
                        .response { response in
                            continuation.resume(returning: response)
                        }
                    }
                }

                logger.log(message: "🚀 taskId: \(taskId): Task created", level: .info)

                let executorTask: ExecutorTask = ExecutorTask(
                    taskId: taskId,
                    task: requestTask as ExecutorTask.TaskType,
                    cacheTimeout: cacheTimeout
                )

                DeduplicatingRequestExecutor.runningRequestTasks[taskId] = executorTask

                let dataResponse = await requestTask.value
                switch dataResponse.result {
                case .success:
                    logger.log(message: "🚀 taskId: \(taskId): Task finished successfully", level: .info)

                    if cacheTimeout > 0 {
                        DeduplicatingRequestExecutor.runningRequestTasks[taskId]?.finishDate = Date()
                    } else {
                        DeduplicatingRequestExecutor.runningRequestTasks[taskId] = nil
                    }

                    return dataResponse

                case .failure:
                    logger.log(message: "🚀 taskId: \(taskId): Task finished with error", level: .error)
                    DeduplicatingRequestExecutor.runningRequestTasks[taskId] = nil
                    return dataResponse
                }
            }

    }

}
