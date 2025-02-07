//
//  NetworkError.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 14/10/2024.
//

import Foundation

public enum NetworkError: LocalizedError, Hashable {

    case endpoint(EndpointError)
    case remote(statusCode: Int, data: Data?)
    case paging(PagingError)
    case missingLocalData
    case missingRemoteData
    case sessionError
    case invalidBaseURL
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .endpoint(let endpointError):
            return endpointError.errorDescription

        case .remote(let statusCode, _):
            return "HTTP \(statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"

        case .paging(let pagingError):
            return pagingError.errorDescription

        case .missingLocalData:
            return "Missing data - Failed to map local resource to remote type"

        case .missingRemoteData:
            return "Missing data - Failed to map remote resource to local type"

        case .sessionError:
            return "Internal session error"

        case .invalidBaseURL:
            return "Resolved server base URL is invalid"

        case .cancelled:
            return "Operation cancelled"
        }
    }

    var statusCode: Int? {
        if case let .remote(statusCode, _) = self {
            return statusCode
        } else {
            return nil
        }
    }

    func remoteError<E: Error & Decodable>(as errorType: E.Type) -> E? {
        if case let .remote(_, data) = self {
            return try? JSONDecoder().decode(errorType, from: data ?? Data())
        } else {
            return nil
        }
    }

}

public enum EndpointError: LocalizedError {

    case noSuchEndpoint
    case operationNotSupported

    public var errorDescription: String? {
        switch self {
        case .noSuchEndpoint:
            return "No such endpoint"

        case .operationNotSupported:
            return "Operation not supported"
        }
    }

}

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
