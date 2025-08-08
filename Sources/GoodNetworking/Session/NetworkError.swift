//
//  NetworkError.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 14/10/2024.
//

import Foundation

// MARK: - Network error

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

    func asNetworkError() -> NetworkError {
        return NetworkError.local(self)
    }

}

public extension DecodingError {

    func asNetworkError() -> NetworkError {
        return NetworkError.decoding(self)
    }

}

extension URLError.Code {

    public static var cannotEncodeRawData: URLError.Code {
        URLError.Code(rawValue: 7777)
    }

}

// MARK: - Remote error

public struct HTTPError: LocalizedError, Hashable {

    public let statusCode: Int
    public let errorResponse: Data

    public var errorDescription: String? {
        return "HTTP \(statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
    }

    public init(statusCode: Int, errorResponse: Data) {
        self.statusCode = statusCode
        self.errorResponse = errorResponse
    }

    public func remoteError<E: Error & Decodable>(as errorType: E.Type) -> E? {
        return try? JSONDecoder().decode(errorType, from: errorResponse)
    }

}

// MARK: - Automatic pager

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
