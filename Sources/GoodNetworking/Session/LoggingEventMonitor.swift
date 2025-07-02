//
//  LoggingEventMonitor.swift
//  GoodNetworking
//
//  Created by Matus Klasovity on 30/01/2024.
//

import Combine
import Foundation

//public struct LoggingEventMonitor: EventMonitor, Sendable {
//
//    nonisolated(unsafe) public static var verbose: Bool = true
//    nonisolated(unsafe) public static var prettyPrinted: Bool = true
//    nonisolated(unsafe) public static var maxVerboseLogSizeBytes: Int = 100_000
//
//    /// The `DispatchQueue` onto which Alamofire's root `CompositeEventMonitor` will dispatch events. `.main` by default.
//    public let queue = DispatchQueue(label: C.queueLabel, qos: .background)
//
//    private enum C {
//
//        static let queueLabel = "com.goodrequest.networklogger"
//
//    }
//
//    private let logger: NetworkLogger
//
//    /// Creates a new logging monitor.
//    ///
//    /// - Parameter logger: The logger instance to use for output. If nil, no logging occurs.
//    public init(logger: NetworkLogger, configuration: Configuration = .init()) {
//        self.logger = logger
//    }
//
//    public func request<T>(_ request: DataRequest, didParseResponse response: DataResponse<T, AFError>) {
//        let requestInfoMessage = parseRequestInfo(response: response)
//        let metricsMessage = parse(metrics: response.metrics)
//        let requestBodyMessage = parse(data: request.request?.httpBody, error: response.error as NSError?, prefix: "⬆️ Request body:")
//        let errorMessage: String? = if let afError = response.error {
//            "🚨 Error:\n\(afError)"
//        } else {
//            nil
//        }
//        
//        let responseBodyMessage = if Self.useMimeTypeWhitelist, Self.responseTypeWhiteList.contains(where: { $0 == response.response?.mimeType }) {
//            parse(data: response.data, error: response.error as NSError?, prefix: "⬇️ Response body:")
//        } else {
//            "❓❓❓ Response MIME type not whitelisted (\(response.response?.mimeType ?? "❓")). You can try adding it to whitelist using logMimeType(_ mimeType:)."
//        }
//
//        let logMessage = [
//            requestInfoMessage,
//            metricsMessage,
//            requestBodyMessage,
//            errorMessage,
//            responseBodyMessage
//        ].compactMap { $0 }.joined(separator: "\n")
//
//        switch response.result {
//        case .success:
//            logger.logNetworkEvent(message: logMessage, level: .debug, fileName: #file, lineNumber: #line)
//        case .failure:
//            logger.logNetworkEvent(message: logMessage, level: .error, fileName: #file, lineNumber: #line)
//        }
//    }
//
//}
//
//private extension LoggingEventMonitor {
//
//    func parseRequestInfo<T>(response: DataResponse<T, AFError>) -> String? {
//        guard let request = response.request,
//              let url = request.url?.absoluteString.removingPercentEncoding,
//              let method = request.httpMethod,
//              let response = response.response
//        else {
//            return nil
//        }
//        guard Self.verbose else {
//            return "🚀 \(method)|\(parseResponseStatus(response: response))|\(url)"
//        }
//
//        if let headers = request.allHTTPHeaderFields,
//           !headers.isEmpty,
//           let headersData = try? JSONSerialization.data(withJSONObject: headers, options: [.prettyPrinted]),
//           let headersPrettyMessage = parse(data: headersData, error: nil, prefix: "🏷 Headers:") {
//
//            return "🚀 \(method)|\(parseResponseStatus(response: response))|\(url)\n" + headersPrettyMessage
//        } else {
//            let headers = if let allHTTPHeaderFields = request.allHTTPHeaderFields, !allHTTPHeaderFields.isEmpty {
//                allHTTPHeaderFields.description
//            } else {
//                "empty headers"
//            }
//            return "🚀 \(method)|\(parseResponseStatus(response: response))|\(url)\n🏷 Headers: \(headers)"
//        }
//    }
//
//    func parse(data: Data?, error: NSError?, prefix: String) -> String? {
//        guard Self.verbose else { return nil }
//
//        if let data = data, !data.isEmpty {
//            guard data.count < Self.maxVerboseLogSizeBytes else {
//                return [
//                    prefix,
//                    "Data size is too big!",
//                    "Max size is: \(Self.maxVerboseLogSizeBytes) bytes.",
//                    "Data size is: \(data.count) bytes",
//                    "💡Tip: Change LoggingEventMonitor.maxVerboseLogSizeBytes = \(data.count)"
//                ].joined(separator: "\n")
//            }
//            if let string = String(data: data, encoding: .utf8) {
//                if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
//                   let prettyPrintedData = try? JSONSerialization.data(withJSONObject: jsonData, options: Self.prettyPrinted ? [.prettyPrinted, .withoutEscapingSlashes] : [.withoutEscapingSlashes]),
//                   let prettyPrintedString = String(data: prettyPrintedData, encoding: .utf8) {
//                    return "\(prefix) \n\(prettyPrintedString)"
//                } else {
//                    return "\(prefix)\(string)"
//                }
//            }
//        }
//
//        return nil
//    }
//
//    func parse(metrics: URLSessionTaskMetrics?) -> String? {
//        guard let metrics, Self.verbose else {
//            return nil
//        }
//        return "↗️ Start: \(metrics.taskInterval.start)" + "\n" + "⌛️ Duration: \(metrics.taskInterval.duration)s"
//    }
//
//
//    func parseResponseStatus(response: HTTPURLResponse) -> String {
//        let statusCode = response.statusCode
//        let logMessage = (200 ..< 300).contains(statusCode) ? "✅ \(statusCode)" : "❌ \(statusCode)"
//        return logMessage
//    }
//
//}
//
//public extension LoggingEventMonitor {
//    
//    nonisolated(unsafe) private(set) static var responseTypeWhiteList: [String] = [
//        "application/json",
//        "application/ld+json",
//        "application/xml",
//        "text/plain",
//        "text/csv",
//        "text/html",
//        "text/javascript",
//        "application/rtf"
//    ]
//    
//    nonisolated(unsafe) static var useMimeTypeWhitelist: Bool = true
//
//    nonisolated(unsafe) static func logMimeType(_ mimeType: String) {
//        responseTypeWhiteList.append(mimeType)
//    }
//    
//    nonisolated(unsafe) static func stopLoggingMimeType(_ mimeType: String) {
//        responseTypeWhiteList.removeAll(where: {
//            $0 == mimeType
//        })
//    }
//    
//}
