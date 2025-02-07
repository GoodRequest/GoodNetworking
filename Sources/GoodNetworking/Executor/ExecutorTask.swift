//
//  ExecutorTask.swift
//
//
//  Created by Matus Klasovity on 06/08/2024.
//

import Foundation
import Alamofire

/// A class that represents an asynchronous network task with caching capabilities.
///
/// `ExecutorTask` encapsulates a network request task along with metadata for caching and timeout management.
/// It provides functionality to track task completion time and determine if cached results have expired.
///
/// Example usage:
/// ```swift
/// let task = ExecutorTask(
///     taskId: "fetch_user",
///     task: Task { ... },
///     cacheTimeout: 300 // 5 minutes
/// )
/// ```
public final class ExecutorTask {

    /// Type alias for the underlying asynchronous task that handles network responses
    typealias TaskType = Task<DataResponse<Data?, AFError>, Never>

    /// The date when the task completed execution. `nil` if the task hasn't finished.
    var finishDate: Date?
    
    /// A unique identifier for the task
    let taskId: String
    
    /// The underlying asynchronous task
    let task: TaskType

    /// The duration in seconds after which cached results are considered stale
    private let cacheTimeout: TimeInterval

    /// Indicates whether the cached result has exceeded its timeout period
    ///
    /// Returns `true` if the task has finished and the time since completion exceeds
    /// the cache timeout. Returns `false` if the task hasn't finished or is within
    /// the timeout period.
    var exceedsTimeout: Bool {
        guard let finishDate else { return false }
        return Date().timeIntervalSince(finishDate) > cacheTimeout
    }

    /// Creates a new executor task
    ///
    /// - Parameters:
    ///   - taskId: A unique identifier for the task
    ///   - task: The underlying asynchronous task
    ///   - cacheTimeout: The duration in seconds after which cached results are considered stale
    init(taskId: String, task: TaskType, cacheTimeout: TimeInterval) {
        self.taskId = taskId
        self.task = task
        self.cacheTimeout = cacheTimeout
    }

}
