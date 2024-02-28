//
//  LoggingEventMonitor.swift
//  
//
//  Created by Matus Klasovity on 30/01/2024.
//

import Foundation
import Alamofire
import Combine

public class LoggingEventMonitor: EventMonitor {

    public static var verbose: Bool = true
    public static var prettyPrinted: Bool = true
    public static var maxVerboseLogSizeBytes: Int = 100_000

    private var messages: PassthroughSubject<String, Never>?
    public lazy var messagesPublisher = messages?.eraseToAnyPublisher()

    public let queue = DispatchQueue(label: C.queueLabel, qos: .background)

    private enum C {

        static let queueLabel = "com.goodrequest.networklogger"

    }

    private var logger: (any SessionLogger)?

    public init(logger: (any SessionLogger)?) {
        self.logger = logger
    }

    public func request<T>(_ request: DataRequest, didParseResponse response: DataResponse<T, AFError>) {
        let requestInfoMessage = parseRequestInfo(request: response.request)
        let metricsMessage = parse(metrics: response.metrics)
        let requestBodyMessage = parse(data: request.request?.httpBody, error: response.error as NSError?, prefix: "⬆️ Request body:")
        let responseStatusMessage = parseResponseStatus(response: response.response)
        let errorMessage: String? = if let afError = response.error {
            "🚨 Error:\n\(afError)"
        } else {
            nil
        }
        
        let responseBodyMessage = if Self.useMimeTypeWhitelist, Self.responseTypeWhiteList.contains(where: { $0 == response.response?.mimeType }) {
            parse(data: response.data, error: response.error as NSError?, prefix: "⬇️ Response body:")
        } else {
            "❓❓❓ Response MIME type not whitelisted (\(response.response?.mimeType ?? "❓")). You can try adding it to whitelist using logMimeType(_ mimeType:)."
        }

        let logMessage = [
            requestInfoMessage,
            metricsMessage,
            requestBodyMessage,
            responseStatusMessage,
            errorMessage,
            responseBodyMessage
        ].compactMap { $0 }.joined(separator: "\n")

        if let messages {
            messages.send(logMessage)
        }

        switch response.result {
        case .success:
            logger?.log(level: .debug, message: logMessage)
        case .failure:
            logger?.log(level: .fault, message: logMessage)
        }
    }

}

private extension LoggingEventMonitor {

    func parseRequestInfo(request: URLRequest?) -> String? {
        guard let request = request,
              let url = request.url?.absoluteString.removingPercentEncoding,
              let method = request.httpMethod else {
            return nil
        }
        guard Self.verbose else {
            return "🚀 \(method) \(url)"
        }

        if let headers = request.allHTTPHeaderFields,
           !headers.isEmpty,
           let headersData = try? JSONSerialization.data(withJSONObject: headers, options: [.prettyPrinted]),
           let headersPrettyMessage = parse(data: headersData, error: nil, prefix: "🏷 Headers:") {

            return "🚀 \(method) \(url)\n" + headersPrettyMessage
        } else {
            let headers = if let allHTTPHeaderFields = request.allHTTPHeaderFields, !allHTTPHeaderFields.isEmpty {
                allHTTPHeaderFields.description
            } else {
                "empty headers"
            }

            return "🚀 \(method) \(url)\n🏷 Headers: \(headers)"
        }
    }

    func parse(data: Data?, error: NSError?, prefix: String) -> String? {
        guard Self.verbose else { return nil }

        if let data = data, !data.isEmpty {
            guard data.count < Self.maxVerboseLogSizeBytes else {
                return [
                    prefix,
                    "Data size is too big!",
                    "Max size is: \(Self.maxVerboseLogSizeBytes) bytes.",
                    "Data size is: \(data.count) bytes",
                    "💡Tip: Change LoggingEventMonitor.maxVerboseLogSizeBytes = \(data.count)"
                ].joined(separator: "\n")
            }
            if let string = String(data: data, encoding: .utf8) {
                if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                   let prettyPrintedData = try? JSONSerialization.data(withJSONObject: jsonData, options: Self.prettyPrinted ? [.prettyPrinted, .withoutEscapingSlashes] : [.withoutEscapingSlashes]),
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
        guard let metrics, Self.verbose else {
            return nil
        }
        return "↗️ Start: \(metrics.taskInterval.start)" + "\n" + "⌛️ Duration: \(metrics.taskInterval.duration)s"
    }


    func parseResponseStatus(response: HTTPURLResponse?) -> String? {
        guard let statusCode = response?.statusCode else {
            return nil
        }

        let logMessage = (200 ..< 300).contains(statusCode) ? "✅ \(statusCode)" : "❌ \(statusCode)"
        return logMessage
    }

}

public extension LoggingEventMonitor {
    
    private(set) static var responseTypeWhiteList: [String] = [
        "application/json",
        "application/ld+json",
        "application/xml",
        "text/plain",
        "text/csv",
        "text/html",
        "text/javascript",
        "application/rtf"
    ]
    
    static var useMimeTypeWhitelist: Bool = true
    
    static func logMimeType(_ mimeType: String) {
        responseTypeWhiteList.append(mimeType)
    }
    
    static func stopLoggingMimeType(_ mimeType: String) {
        responseTypeWhiteList.removeAll(where: {
            $0 == mimeType
        })
    }
    
}
