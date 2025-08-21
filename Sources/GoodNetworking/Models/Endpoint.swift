//
//  Endpoint.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 10/12/2023.
//

import Foundation

// MARK: - Endpoint

/// `Endpoint` protocol defines a set of requirements for an endpoint.
public protocol Endpoint {

    /// The path to be appended to the base URL.
    var path: URLConvertible { get }
    
    /// HTTP method to be used for the request.
    var method: HTTPMethod { get }

    /// Parameters to be sent with the request.
    var parameters: EndpointParameters? { get }
    
    /// HTTP headers to be added to the request.
    var headers: HTTPHeaders? { get }

    /// Encoding to be used for encoding the parameters.
    @available(*, deprecated, message: "Encoding will be automatically determined by the kind of `parameters` in the future.")
    var encoding: ParameterEncoding { get }

    /// Creates a URL by resolving `path` over `baseUrl`.
    ///
    /// This function is a customization point for modifying the URL by current runtime,
    /// for example for API versioning or platform separation.
    ///
    /// Note that this function will be only called if the ``path`` resolved
    /// is a relative URL. If ``path`` specifies an absolute URL, it will be
    /// used instead, without any modifications.
    ///
    /// - Parameter baseUrl: Base URL for the request to combine with.
    /// - Returns: URL for the request or `nil` if such URL cannot be constructed.
    @NetworkActor func url(on baseUrl: URLConvertible) async -> URL?

}

public extension Endpoint {
    
    @NetworkActor func url(on baseUrl: URLConvertible) async -> URL? {
        let baseUrl = await baseUrl.resolveUrl()
        let path = await path.resolveUrl()
        
        guard let baseUrl, let path else { return nil }
        return baseUrl.appendingPathComponent(path.absoluteString)
    }
    
}

@available(*, deprecated, message: "Default values for deprecated properties")
public extension Endpoint {

    var encoding: ParameterEncoding { AutomaticEncoding.default }
    
}

// MARK: - Parameters

/// Enum that represents the data to be sent with the request,
/// either as a body or as query parameters.
public enum EndpointParameters {

    /// Case for sending `Parameters`.
    @available(*, deprecated, renamed: "json", message: "Use JSON instead of raw dictionaries")
    case parameters([String: Any])

    case query([URLQueryItem])
    
    case model(Encodable)
    
    case data(Data)
    
    case json(JSON)

    public var dictionary: JSON? {
        switch self {
        case .parameters(let dictionary):
            return JSON(dictionary)
            
        case .query(let queryItems):
            assertionFailure("Handling URLQueryItems as JSON is not optimal.")
            return JSON(queryItems
                .map { ($0.name, JSON($0.value as Any)) }
                .reduce(into: [:], { $0[$1.0] = $1.1 }))
        
        case .model(let anyEncodable):
            if let customEncodable = anyEncodable as? WithCustomEncoder {
                let customEncoder = type(of: customEncodable).encoder
                return JSON(encodable: anyEncodable, encoder: customEncoder)
            } else {
                return JSON(anyEncodable)
            }
            
        case .data(let data):
            return try? JSON(data: data)
            
        case .json(let json):
            return json
        }
    }

    internal func data() throws(NetworkError) -> Data? {
        switch self {
        case .parameters, .query:
            return self.dictionary?.data()
                        
        case .model(let codableModel):
            do {
                let encoder = JSONEncoder()
                return try encoder.encode(codableModel)
            } catch {
                throw URLError(.cannotEncodeRawData).asNetworkError()
            }
            
        case .data(let data):
            return data
            
        case .json(let json):
            return json.data()
        }
    }

    internal func queryItems() -> [URLQueryItem] {
        if case .query(let queryItems) = self {
            return queryItems
        } else { // Handle `Encodable` query and legacy support
            guard let json = self.dictionary else { return [] }
            return json.dictionary?.map { key, value in URLQueryItem(name: key, value: "\(value)") } ?? []
        }
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

@available(*, deprecated)
public enum AutomaticEncoding: ParameterEncoding {
    case `default`
}

@available(*, deprecated, message: "Use URLConvertible instead.")
public extension String {

    @available(*, deprecated, message: "Use URLConvertible instead.")
    func asURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw URLError(.badURL).asNetworkError()
        }
        return url
    }

}
