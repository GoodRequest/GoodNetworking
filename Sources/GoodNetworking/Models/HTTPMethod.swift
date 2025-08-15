//
//  HTTPMethod.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

import Foundation

// MARK: - Method

/// Enumeration of all HTTP methods as stated in
/// [RFC9110 specification](https://httpwg.org/specs/rfc9110.html#rfc.section.9.3)
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
    
    /// Request methods are considered "safe" if their defined semantics are essentially read-only.
    ///
    /// The client does not request, and does not expect, any state change on the origin server
    /// as a result of applying a safe method to a target resource. Likewise, reasonable use of
    /// a safe method is not expected to cause any harm, loss of property, or unusual burden
    /// on the origin server.
    var isSafe: Bool {
        switch self {
        case .get, .head, .options, .trace:
            return true

        case .put, .delete, .post, .patch, .connect:
            return false
        }
    }

    /// A request method is considered "idempotent" if the intended effect on the server of multiple
    /// identical requests with that method is the same as the effect for a single such request.
    ///
    /// Idempotent methods are distinguished because the request can be repeated automatically
    /// if a communication failure occurs before the client is able to read the server's response.
    /// For example, if a client sends a PUT request and the underlying connection is closed
    /// before any response is received, then the client can establish a new connection and retry
    /// the idempotent request. It knows that repeating the request will have the same intended
    /// effect, even if the original request succeeded, though the response might differ.
    ///
    /// - important: User agent can repeat a POST request automatically if it knows
    /// (through design or configuration) that the request is safe for that resource.
    var isIdempotent: Bool {
        if isSafe {
            return true
        } else if self == .put {
            return true
        } else if self == .delete {
            return true
        } else {
            return false
        }
    }

    /// Request methods can be defined as "cacheable" to indicate that
    /// responses to them are allowed to be stored for future reuse; for
    /// specific requirements see [RFC7234].  In general, safe methods that
    /// do not depend on a current or authoritative response are defined as
    /// cacheable.
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

// MARK: - URLRequest extension

public extension URLRequest {

    var method: HTTPMethod {
        HTTPMethod(rawValue: self.httpMethod ?? "GET") ?? .get
    }

}
