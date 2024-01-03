//
//  GRSessionLogger.swift
//
//
//  Created by Andrej Jasso on 24/05/2022.
//

import Foundation
import Alamofire

/// This class is a type of EventMonitor and provides logging functionality for data requests and their responses.
/// It logs information such as request URL, headers, HTTP method, response status code, response body, and error information if it exists.
open class GRSessionLogger: EventMonitor {

    /// Initializes a new instance of `GRSessionLogger`
    public init() {}

    /// This function logs information related to the data request and its response, including request URL, headers, HTTP method, response status code, response body, and error information if it exists.
    ///
    /// - Parameter request: the data request made
    /// - Parameter response: the data response received from the request
    public func request<T>(_ request: DataRequest, didParseResponse response: DataResponse<T, AFError>) {
        // Logs the request URL and HTTP method
        if let url = response.request?.url?.absoluteString.removingPercentEncoding,
           let method = response.request?.httpMethod {
            let headers = response.request?.headers.description ?? "🏷 empty headers"

            if response.error == nil {
                logInfo("🚀 \(method) \(url)")
                logVerbose("🏷 \(headers)")
            } else {
                logError("🚀 \(method) \(url)")
                logVerbose("🏷 \(headers)")
            }
        }

        // Logs the response status code
        if let response = response.response {
            switch response.statusCode {
            case 200 ..< 300:
                logInfo("✅ \(response.statusCode)")

            default:
                logInfo("❌ \(response.statusCode)")
            }
        }

        // Logs the response body
        if let data = response.data,
           let string = String(data: data, encoding: String.Encoding.utf8), !string.isEmpty {
            logVerbose("📦 \(string)")

            if case let .failure(error) = response.result {
                logError("‼️ \(error), \(error.localizedDescription)")
            }
        }

        // Logs error information
        if let error = response.error as NSError? {
            logError("‼️ [\(error.domain) \(error.code)] \(error.localizedDescription)")
        } else if let error = response.error {
            logError("‼️ \(error)")
        }
    }
    
    public func request(_ request: Request, didResumeTask task: URLSessionTask) {
     
        // Logs the request body
        if let body = task.currentRequest?.httpBody,
           let string = String(data: body, encoding: String.Encoding.utf8), !string.isEmpty {
            logVerbose("📦 \(string)")
        }
    }

}

/// Extension for `GRSessionLogger` to provide logging functionality.
private extension GRSessionLogger {

    /// Logs an error message, if the `GRSessionConfiguration.logLevel` is not set to `.none`.
    /// - Parameter text: The text to log.
    func logError(_ text: String) {
        guard NetworkSessionConfiguration.logLevel != .none else { return }

        print(text)
    }

    /// Logs an informational message, if the `GRSessionConfiguration.logLevel` is set to `.info` or `.verbose`.
    /// - Parameter text: The text to log.
    func logInfo(_ text: String) {
        guard NetworkSessionConfiguration.logLevel != .none else { return }

        if NetworkSessionConfiguration.logLevel != .error {
            print(text)
        }
    }

    /// Logs a verbose message, if the `GRSessionConfiguration.logLevel` is set to `.verbose`.
    /// - Parameter text: The text to log.
    func logVerbose(_ text: String) {
        guard NetworkSessionConfiguration.logLevel != .none else { return }

        if NetworkSessionConfiguration.logLevel == .verbose {
            print(text)
        }
    }

}
