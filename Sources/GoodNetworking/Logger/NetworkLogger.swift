//
//  NetworkLogger.swift
//  GoodNetworking
//
//  Created by Matus Klasovity on 09/06/2025.
//

import Foundation

public enum LogLevel: String, CaseIterable {
    case debug
    case info
    case warning
    case error
}

public protocol NetworkLogger: Sendable {
    /// Logs the given message with a specific log level, file name, and line number.
    func logNetworkEvent(
        message: Any,
        level: LogLevel,
        fileName: String,
        lineNumber: Int
    )
}
 
