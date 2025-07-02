//
//  HTTPMethod.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

@frozen public enum HTTPMethod: String {

    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"

    var isSafe: Bool {
        switch self {
        case .get, .head, .options, .trace:
            return true

        case .put, .delete, .post, .patch, .connect:
            return false
        }
    }

    var isIdempotent: Bool {
        switch self {
        case .get, .head, .options, .trace, .put, .delete:
            return true

        case .post, .patch, .connect:
            return false
        }
    }

    var isCacheable: Bool {
        switch self {
        case .get, .head:
            return true

        case .options, .trace, .put, .delete, .post, .patch, .connect:
            return false
        }
    }

    var hasRequestBody: Bool {
        switch self {
        case .post, .put, .patch:
            return true

        case .get, .head, .options, .trace, .delete, .connect:
            return false
        }
    }

}
