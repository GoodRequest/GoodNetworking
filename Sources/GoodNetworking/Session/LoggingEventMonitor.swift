//
//  LoggingEventMonitor.swift
//  GoodNetworking
//
//  Created by Matus Klasovity on 30/01/2024.
//

/// A network event monitor that provides detailed logging of network requests and responses.
///
/// `LoggingEventMonitor` implements Alamofire's `EventMonitor` protocol to log network activity in a structured
/// and configurable way. It supports:
///
/// - Request/response body logging with size limits and pretty printing
/// - Header logging
/// - Performance metrics and slow request warnings
/// - MIME type whitelisting for response logging
/// - Configurable log prefixes and formatting
///
/// Example usage:
/// ```swift
/// let logger = ConsoleLogger()
/// let monitor = LoggingEventMonitor(logger: logger)
///
/// // Configure logging options
/// LoggingEventMonitor.configure { config in
///     config.verbose = true
///     config.prettyPrinted = true
///     config.maxVerboseLogSizeBytes = 200_000
/// }
/// ```
///
/// The monitor can be added to a network session configuration:
/// ```swift
/// let config = NetworkSessionConfiguration(eventMonitors: [monitor])
/// let session = NetworkSession(configuration: config)
/// ```
@preconcurrency import Alamofire
import Combine
import GoodLogger
import Foundation

public struct LoggingEventMonitor: EventMonitor, Sendable {

    nonisolated(unsafe) private static var configuration = Configuration()

    /// Configuration options for the logging monitor.
    public struct Configuration {
        /// Whether to log detailed request/response information. Defaults to `true`.
        var verbose: Bool = true
        
        /// Whether to pretty print JSON responses. Defaults to `true`.
        var prettyPrinted: Bool = true
        
        /// Maximum size in bytes for verbose logging of request/response bodies. Defaults to 100KB.
        var maxVerboseLogSizeBytes: Int = 100_000
        
        /// Threshold in seconds above which requests are marked as slow. Defaults to 1 second.
        var slowRequestThreshold: TimeInterval = 1.0
        
        /// Emoji prefixes used in log messages.
        var prefixes = Prefixes()
        
        /// Whether to only log responses with whitelisted MIME types. Defaults to `true`.
        var useMimeTypeWhitelist: Bool = true

        /// Emoji prefixes used to categorize different types of log messages.
        public struct Prefixes {
            var request = "🚀"
            var response = "⬇️" 
            var error = "🚨"
            var headers = "🏷"
            var metrics = "⌛️"
            var success = "✅"
            var failure = "❌"
        }
    }

    /// Updates the monitor's configuration.
    ///
    /// - Parameter updates: A closure that modifies the configuration.
    public static func configure(_ updates: (inout Configuration) -> Void) {
        var config = configuration
        updates(&config)
        configuration = config
    }

    /// The queue on which logging events are dispatched.
    public let queue = DispatchQueue(label: C.queueLabel, qos: .background)

    private enum C {
        static let queueLabel = "com.goodrequest.networklogger"
    }

    private let logger: (any GoodLogger)?

    /// Creates a new logging monitor.
    ///
    /// - Parameter logger: The logger instance to use for output. If nil, no logging occurs.
    public init(logger: (any GoodLogger)?) {
        self.logger = logger
    }

    public func request<T>(_ request: DataRequest, didParseResponse response: DataResponse<T, AFError>) {
        let requestSize = request.request?.httpBody?.count ?? 0
        let responseSize = response.data?.count ?? 0

        let requestInfoMessage = parseRequestInfo(response: response)
        let metricsMessage = parse(metrics: response.metrics)
        let requestBodyMessage = parse(
            data: request.request?.httpBody,
            error: response.error as NSError?,
            prefix: "\(Self.configuration.prefixes.request) Request body (\(formatBytes(requestSize))):"
        )
        let errorMessage: String? = if let afError = response.error {
            "\(Self.configuration.prefixes.error) Error:\n\(afError)"
        } else {
            nil
        }

        let responseBodyMessage = if
            Self.configuration.useMimeTypeWhitelist,
            Self.responseTypeWhiteList.contains(where: { $0 == response.response?.mimeType })
        {
            parse(
                data: response.data,
                error: response.error as NSError?,
                prefix: "\(Self.configuration.prefixes.response) Response body (\(formatBytes(responseSize))):"
            )
        } else {
            "❓❓❓ Response MIME type not whitelisted (\(response.response?.mimeType ?? "❓"))"
        }

        let logMessage = [
            requestInfoMessage,
            metricsMessage,
            requestBodyMessage,
            errorMessage,
            responseBodyMessage
        ].compactMap { $0 }.joined(separator: "\n")

        switch response.result {
        case .success:
            logger?.log(message: logMessage, level: .debug)
        case .failure:
            logger?.log(message: logMessage, level: .fault)
        }
    }

}

private extension LoggingEventMonitor {

    func parseRequestInfo<T>(response: DataResponse<T, AFError>) -> String? {
        guard let request = response.request,
              let url = request.url?.absoluteString.removingPercentEncoding,
              let method = request.httpMethod,
              let response = response.response
        else {
            return nil
        }
        guard Self.configuration.verbose else {
            return "\(Self.configuration.prefixes.request) \(method)|\(parseResponseStatus(response: response))|\(url)"
        }

        if let headers = request.allHTTPHeaderFields,
           !headers.isEmpty,
           let headersData = try? JSONSerialization.data(withJSONObject: headers, options: [.prettyPrinted]),
           let headersPrettyMessage = parse(data: headersData, error: nil, prefix: "\(Self.configuration.prefixes.headers) Headers:") {

            return "\(Self.configuration.prefixes.request) \(method)|\(parseResponseStatus(response: response))|\(url)\n" + headersPrettyMessage
        } else {
            let headers = if let allHTTPHeaderFields = request.allHTTPHeaderFields, !allHTTPHeaderFields.isEmpty {
                allHTTPHeaderFields.description
            } else {
                "empty headers"
            }
            return "\(Self.configuration.prefixes.request) \(method)|\(parseResponseStatus(response: response))|\(url)\n\(Self.configuration.prefixes.headers) Headers: \(headers)"
        }
    }

    func parse(data: Data?, error: NSError?, prefix: String) -> String? {
        guard Self.configuration.verbose else { return nil }

        if let data = data, !data.isEmpty {
            guard data.count < Self.configuration.maxVerboseLogSizeBytes else {
                return [
                    prefix,
                    "Data size is too big!",
                    "Max size is: \(Self.configuration.maxVerboseLogSizeBytes) bytes.",
                    "Data size is: \(data.count) bytes",
                    "💡Tip: Change LoggingEventMonitor.maxVerboseLogSizeBytes = \(data.count)"
                ].joined(separator: "\n")
            }
            if let string = String(data: data, encoding: .utf8) {
                if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                   let prettyPrintedData = try? JSONSerialization.data(withJSONObject: jsonData, options: Self.configuration.prettyPrinted ? [.prettyPrinted, .withoutEscapingSlashes] : [.withoutEscapingSlashes]),
                   let prettyPrintedString = String(data: prettyPrintedData, encoding: .utf8) {
                    return "\(prefix) \n\(prettyPrintedString)"
                } else {
                    return "\(prefix)\(string)"
                }
            }
        }

        return nil
    }

    func parse(metrics: URLSessionTaskMetrics?) -> String? {
        guard let metrics, Self.configuration.verbose else {
            return nil
        }

        let duration = metrics.taskInterval.duration
        let warning = duration > Self.configuration.slowRequestThreshold ? " ⚠️ Slow Request!" : ""

        return [
            "↗️ Start: \(metrics.taskInterval.start)",
            "\(Self.configuration.prefixes.metrics) Duration: \(String(format: "%.3f", duration))s\(warning)"
        ].joined(separator: "\n")
    }


    func parseResponseStatus(response: HTTPURLResponse) -> String {
        let statusCode = response.statusCode
        let logMessage = (200 ..< 300).contains(statusCode)
        ? "\(Self.configuration.prefixes.success) \(statusCode)"
        : "\(Self.configuration.prefixes.failure) \(statusCode)"

        return logMessage
    }

    private func formatBytes(_ bytes: Int) -> String {
        let units = ["B", "KB", "MB"]
        var size = Double(bytes)
        var unitIndex = 0

        while size > 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }

        return String(format: "%.1f %@", size, units[unitIndex])
    }

}

public extension LoggingEventMonitor {

    /// List of MIME types that will be logged when `useMimeTypeWhitelist` is enabled.
    nonisolated(unsafe) private(set) static var responseTypeWhiteList: [String] = [
        "application/json",
        "application/ld+json",
        "application/xml",
        "text/plain",
        "text/csv",
        "text/html",
        "text/javascript",
        "application/rtf"
    ]

    /// Adds a MIME type to the whitelist for response logging.
    ///
    /// - Parameter mimeType: The MIME type to whitelist
    nonisolated(unsafe) static func logMimeType(_ mimeType: String) {
        responseTypeWhiteList.append(mimeType)
    }

    /// Removes a MIME type from the whitelist for response logging.
    ///
    /// - Parameter mimeType: The MIME type to remove
    nonisolated(unsafe) static func stopLoggingMimeType(_ mimeType: String) {
        responseTypeWhiteList.removeAll{ $0 == mimeType }
    }

}
