//
//  GREndpoint.swift
//

import Alamofire
import Foundation

// MARK: - Endpoint

/// `GREndpoint` protocol defines a set of requirements for an endpoint.
public protocol Endpoint {

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

    /// Creates a URL by combining `path` with `baseUrl`.
    /// This function is a customization point for modifying the URL by current runtime,
    /// for example for API versioning or platform separation.
    /// - Parameter baseUrl: Base URL for the request to combine with.
    /// - Throws: If creating a concrete URL fails.
    /// - Returns: URL for the request.
    func url(on baseUrl: String) throws -> URL

}

// MARK: - Parameters

/// Enum that represents the type of parameters to be sent with the request.
public enum EndpointParameters {

    typealias CustomEncodable = (Encodable & WithCustomEncoder)

    /// Case for sending `Parameters`.
    case parameters(Parameters)
    
    /// Case for sending an instance of `Encodable`.
    case model(Encodable)

    var dictionary: Parameters? {
        switch self {
        case .parameters(let parameters):
            return parameters

        case .model(let customEncodable as CustomEncodable):
            return customEncodable.jsonDictionary

        case .model(let anyEncodable):
            let encoder = JSONEncoder()

            do {
                let data = try encoder.encode(anyEncodable)
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)

                return jsonObject as? Parameters
            } catch {
                return nil
            }
        }
    }

}

// MARK: - Compatibility

@available(*, deprecated, renamed: "Endpoint", message: "Renamed to Endpoint.")
public typealias GREndpointManager = Endpoint
