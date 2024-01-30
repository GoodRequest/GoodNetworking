//
//  LoggingEventMonitor.swift
//  
//
//  Created by Matus Klasovity on 30/01/2024.
//

import Foundation
import Alamofire

public class LoggingEventMonitor: EventMonitor {

    public let queue = DispatchQueue(label: C.queueLabel, qos: .background)

    private enum C {

        static let queueLabel = "com.goodrequest.networklogger"

    }

    private var verbose: Bool
    private var logger: any SessionLogger

    init(logger: any SessionLogger, verbose: Bool = true) {
        self.logger = logger
        self.verbose = verbose
    }

    public func request<T>(_ request: DataRequest, didParseResponse response: DataResponse<T, AFError>) {
        let requestInfoMessage = parseRequestInfo(request: response.request)
        let metricsMessage = parse(metrics: response.metrics)
        let requestBodyMessage = parse(data: request.request?.httpBody, error: response.error as NSError?, prefix: "⬆️ Request body:")
        let responseStatusMessage = parseResponseStatus(response: response.response)
        let responseBodyMessage = parse(data: response.data, error: response.error as NSError?, prefix: "⬇️ Response body:")

        let logMessaage = [
            requestInfoMessage,
            metricsMessage,
            requestBodyMessage,
            responseStatusMessage,
            responseBodyMessage
        ].compactMap { $0 }.joined(separator: "\n")

        switch response.result {
        case .success:
            logger.log(level: .debug, message: logMessaage)
        case .failure:
            logger.log(level: .fault, message: logMessaage)
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
        guard verbose else {
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
        guard verbose else { return nil }

        if let data = data, !data.isEmpty {
            guard data.count < 100_000 else {
                return ""
            }
            if let string = String(data: data, encoding: .utf8) {
                if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                   let prettyPrintedData = try? JSONSerialization.data(withJSONObject: jsonData, options: [.prettyPrinted, .withoutEscapingSlashes]),
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
        guard let metrics, verbose else {
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
