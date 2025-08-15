//
//  NetworkError.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 14/10/2024.
//

import Foundation

// MARK: - Network error

/// Top level error, which can occur in all networking operations in this library.
///
/// The error is organized as follows:
/// - Local errors (`URLError`): errors which affect only the local state. May contain
/// failed networking operations, no connection errors, invalid URL errors etc.
/// - Remote errors (``HTTPError``): errors which occured as a result of invalid operation
/// over remote state. This contains all HTTP errors, invalid API calls etc., but also means that
/// the request itself on network level has succeeded.
/// - Decoding errors (`DecodingError`): errors which occured during decoding. The request
/// has succeeded, returned a valid, success, response, but could not be decoded to a valid
/// data type in the client.
public enum NetworkError: LocalizedError {

    case local(URLError)
    case remote(HTTPError)
    case decoding(DecodingError)

    public var errorDescription: String? {
        switch self {
        case .local(let urlError):
            return urlError.localizedDescription

        case .remote(let httpError):
            return httpError.localizedDescription

        case .decoding(let decodingError):
            return decodingError.localizedDescription
        }
    }
    
    /// HTTP status code, if the error is a `remote` ``HTTPError``, or `nil` otherwise.
    ///
    /// Simplifies using ``NetworkError`` in `switch-case-where` statements or
    /// comparing with a well known status code.
    public var httpStatusCode: Int? {
        if case .remote(let httpError) = self {
            return httpError.statusCode
        } else {
            return nil
        }
    }

}

// MARK: - Local error extensions

public extension URLError {
    
    /// Transforms the error as a `local` ``NetworkError``.
    /// - Returns: Local NetworkError instance
    func asNetworkError() -> NetworkError {
        return NetworkError.local(self)
    }

}

public extension DecodingError {
    
    /// Transforms the error as a `decoding` ``NetworkError``.
    /// - Returns: Decoding NetworkError instance
    func asNetworkError() -> NetworkError {
        return NetworkError.decoding(self)
    }

}

extension URLError.Code {
    
    /// Indicates that the encoding of raw data failed and the data
    /// could not be processed.
    public static var cannotEncodeRawData: URLError.Code {
        URLError.Code(rawValue: 7777)
    }

}

// MARK: - Remote error

/// Contains errors which occured as a result of invalid operation over remote state.
public struct HTTPError: LocalizedError, Hashable {

    /// HTTP status code of the error
    public let statusCode: Int

    /// Server response
    ///
    /// This contains the body of the erronous HTTP request, which is ready
    /// to be decoded and processed further to determine the handling of the error.
    public let errorResponse: Data

    public var errorDescription: String? {
        return "HTTP \(statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
    }

    public init(statusCode: Int, errorResponse: Data) {
        self.statusCode = statusCode
        self.errorResponse = errorResponse
    }
    
    /// Helper function to try to decode the remote error as a `Decodable` error type.
    /// - Parameter errorType: Decodable error type to decode
    /// - Returns: Decoded error or nil, if decoding fails
    public func remoteError<E: Error & Decodable>(as errorType: E.Type) -> E? {
        return try? JSONDecoder().decode(errorType, from: errorResponse)
    }

}

// MARK: - Automatic pager

/// Errors for automatic pager ``Pager`` for SwiftUI.
public enum PagingError: LocalizedError {

    case noMorePages
    case nonPageableList

    public var errorDescription: String? {
        switch self {
        case .noMorePages:
            return "No more pages available"

        case .nonPageableList:
            return "List is not pageable or paging is not declared"
        }
    }

}
