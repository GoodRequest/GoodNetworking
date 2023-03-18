//
//  GREndpointManagerProtocol.swift
//

import Alamofire
import Foundation

/// `GREndpointManager` protocol defines a set of requirements for an endpoint.
public protocol GREndpointManager {
    
    /// The path to be appended to the base URL.
    var path: String { get }
    
    /// HTTP method to be used for the request.
    var method: HTTPMethod { get }
    
    /// Parameters to be sent with the request.
    var parameters: EndpointParameters? { get }
    
    /// HTTP headers to be added to the request.
    var headers: HTTPHeaders? { get }
    
    /// Encoding to be used for encoding the parameters.
    var encoding: ParameterEncoding { get }
    
    /// Creates a URL by combining `baseURL` and `path`.
    /// - Parameter baseURL: Base URL for the request.
    /// - Throws: If `URL(string:)` throws an error.
    /// - Returns: URL for the request.
    func asURL(baseURL: String) throws -> URL
    
}

/// Enum that represents the type of parameters to be sent with the request.
public enum EndpointParameters {
    
    /// Case for sending `Parameters`.
    case parameters(Parameters)
    
    /// Case for sending an instance of `Encodable`.
    case model(Encodable)
    
}
