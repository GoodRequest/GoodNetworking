//
//  Endpoint.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 10/12/2023.
//

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

public extension Endpoint {

    var method: HTTPMethod { .get }
    var parameters: EndpointParameters? { nil }
    var headers: HTTPHeaders? { nil }
    var encoding: ParameterEncoding { URLEncoding.default }

    func url(on baseUrl: String) throws -> URL {
       let baseUrl = try baseUrl.asURL()
       return baseUrl.appendingPathComponent(path)
    }
    
}

// MARK: - Parameters

/// Enum that represents the type of parameters to be sent with the request.
@available(*, deprecated)
public enum EndpointParameters {

    public typealias Parameters = [String: Any]

    /// Case for sending `Parameters`.
    case parameters(Parameters)

    /// Case for sending an instance of `Encodable`.
    case model(Encodable)

    public var dictionary: Parameters? {
        switch self {
        case .parameters(let parameters):
            return parameters

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

    internal func data() -> Data? {
        switch self {
        case .model(let codableModel):
            let encoder = JSONEncoder()
            let data = try? encoder.encode(codableModel)
            return data

        case .parameters(let parameters):
            return try? JSONSerialization.data(withJSONObject: parameters)
        }
    }

    internal func queryItems() -> [URLQueryItem] {
        guard let dictionary = self.dictionary else { return [] }
        return dictionary.map { key, value in URLQueryItem(name: key, value: "\(value)") }
    }

}

// MARK: - Compatibility

@available(*, deprecated)
public protocol ParameterEncoding {}

@available(*, deprecated)
public enum URLEncoding: ParameterEncoding {
    case `default`
}

@available(*, deprecated)
public enum JSONEncoding: ParameterEncoding {
    case `default`
}

@available(*, deprecated, message: "Use URLConvertible instead.")
public extension String {

    @available(*, deprecated, message: "Use URLConvertible instead.")
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw URLError(.badURL).asNetworkError()
        }
        return url
    }

}
