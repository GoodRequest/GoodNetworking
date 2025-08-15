//
//  DataTaskLogging.swift
//  GoodNetworking
//
//  Created by Matus Klasovity on 30/01/2024.
//

import Combine
import Foundation

// MARK: - Logging

internal extension DataTaskProxy {

    @NetworkActor private static var maxLogSizeBytes: Int { 32_768 } // 32 kB

    @NetworkActor func prepareRequestInfo() -> String {
        """
        🚀 \(task.currentRequest?.method.rawValue ?? "-") \(task.currentRequest?.url?.absoluteString ?? "<unknown>")
        \(prepareResponseStatus(response: task.response, error: receivedError))

        🏷 Headers:
        \(prepareHeaders(request: task.originalRequest))
        
        📤 Request body:
        \(prettyPrintMessage(data: task.originalRequest?.httpBody))
        
        📦 Received data:
        \(prettyPrintMessage(data: receivedData))
        """
    }

    @NetworkActor private func prepareResponseStatus(response: URLResponse?, error: (any Error)?) -> String {
        guard let response = response as? HTTPURLResponse else { return "" }
        let statusCode = response.statusCode

        var logMessage = (200 ..< 300).contains(statusCode) ? "✅ \(statusCode): " : "❌ \(statusCode): "
        logMessage.append(HTTPURLResponse.localizedString(forStatusCode: statusCode))

        if error != nil {
            logMessage.append("\n🚨 Error: \(error?.localizedDescription ?? "<nil>")")
        }

        return logMessage
    }

    @NetworkActor private func prepareHeaders(request: URLRequest?) -> String {
        guard let request, let headerFields = request.allHTTPHeaderFields else { return " <no headers>" }

        return headerFields.map { key, value in
            " - \(key): \(value)"
        }
        .joined(separator: "\n")
    }

    @NetworkActor private func prettyPrintMessage(data: Data?) -> String {
        guard let data else { return "" }

        guard data.count < Self.maxLogSizeBytes else {
            return "💡 Data size is too big (\(data.count) bytes), console limit is \(Self.maxLogSizeBytes) bytes"
        }

        let serializationOptions: JSONSerialization.WritingOptions = if #available(macOS 10.15, *) {
            [.prettyPrinted, .withoutEscapingSlashes]
        } else {
            [.prettyPrinted]
        }
        
        if let string = String(data: data, encoding: .utf8) {
            if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
               let prettyPrintedData = try? JSONSerialization.data(withJSONObject: jsonData, options: serializationOptions),
               let prettyPrintedString = String(data: prettyPrintedData, encoding: .utf8) {
                return prettyPrintedString
            } else {
                return string
            }
        }

        return "🔍 Couldn't decode data as UTF-8"
    }

}
