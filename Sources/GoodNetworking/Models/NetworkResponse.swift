//
//  NetworkResponse.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 30/11/2025.
//

import Foundation

/// Wraps the payload returned from `URLSession` with
/// metadata describing the HTTP response.
public struct NetworkResponse {

    /// Raw body returned by the server.
    public let body: Data

    /// Original `URLResponse` instance for advanced access when needed.
    public let urlResponse: URLResponse?

    /// HTTP headers resolved and stored eagerly for concurrency safety.
    public let headers: HTTPHeaders

    /// HTTP specific response, if available.
    public var httpResponse: HTTPURLResponse? {
        urlResponse as? HTTPURLResponse
    }

    /// Final URL of the response.
    public var url: URL? {
        urlResponse?.url
    }

    /// MIME type announced by the server.
    public var mimeType: String? {
        urlResponse?.mimeType
    }

    /// Expected length of the body.
    public var expectedContentLength: Int64 {
        urlResponse?.expectedContentLength ?? -1 // NSURLResponseUnknownLength
    }

    /// Text encoding specified by the response.
    public var textEncodingName: String? {
        urlResponse?.textEncodingName
    }

    /// Suggested filename inferred by Foundation.
    public var suggestedFilename: String? {
        urlResponse?.suggestedFilename
    }

    /// HTTP status code (or `-1` when not available).
    public var statusCode: Int {
        httpResponse?.statusCode ?? -1
    }

    /// Raw header dictionary exposed without additional processing.
    public var allHeaderFields: [AnyHashable: Any]? {
        httpResponse?.allHeaderFields
    }

    internal init(data: Data, response: URLResponse?) {
        self.body = data
        self.urlResponse = response

        // decode HTTP headers if possible
        if let httpResponse = response as? HTTPURLResponse {
            var flattened: [String: String] = [:]
            httpResponse.allHeaderFields.forEach { header in
                guard let key = header.key as? String else { return }
                flattened[key] = String(describing: header.value)
            }
            self.headers = HTTPHeaders(flattened)
        } else {
            self.headers = HTTPHeaders([:])
        }
    }

}
