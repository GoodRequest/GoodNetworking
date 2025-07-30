//
//  Endpoint.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 10/12/2023.
//

import Foundation

// MARK: - Endpoint builder

public final class Endpoint2: Endpoint {
    
    public var path: URLConvertible
    public var method: HTTPMethod = .get
    
    public var headers: HTTPHeaders? = []
    public var parameters: EndpointParameters?
    
    @available(*, deprecated)
    public var encoding: ParameterEncoding? {
        AutomaticEncoding.default
    }
    
    init(path: URLConvertible) {
        self.path = path
    }

}

extension Endpoint2 {
    
    func method(_ method: HTTPMethod) -> Self {
        self.method = method
        return self
    }
    
    func header(_ header: HTTPHeader) -> Self {
        self.headers?.add(header: header)
        return self
    }
    
    func headers(_ headers: HTTPHeaders) -> Self {
        self.headers?.headers.append(contentsOf: headers.headers)
        return self
    }
    
    func body(data: Data?) -> Self {
        assertBothQueryAndBodyUsage()
        if let data {
            self.parameters = .data(data)
        } else {
            self.parameters = nil
        }
        return self
    }
    
    func body<T: Encodable>(model: T) -> Self {
        assertBothQueryAndBodyUsage()
        self.parameters = .model(model)
        return self
    }
    
    func body(json: JSON) -> Self {
        assertBothQueryAndBodyUsage()
        self.parameters = .json(json)
        return self
    }
    
    func query(_ items: [URLQueryItem]) -> Self {
        assertBothQueryAndBodyUsage()
        self.parameters = .query(items)
        return self
    }
    
    func query<T: Encodable>(_ model: T) -> Self {
        assertBothQueryAndBodyUsage()
        self.parameters = .model(model)
        return self
    }
    
    private func assertBothQueryAndBodyUsage() {
        assert(self.parameters == nil, "Support for query and body parameters at the same time is currently not available.")
    }
    
}

public func at(_ path: URLConvertible) -> Endpoint2 {
    Endpoint2(path: path)
}

// MARK: - Endpoint

/// `GREndpoint` protocol defines a set of requirements for an endpoint.
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

    /// Creates a URL by combining `path` with `baseUrl`.
    /// This function is a customization point for modifying the URL by current runtime,
    /// for example for API versioning or platform separation.
    /// - Parameter baseUrl: Base URL for the request to combine with.
    /// - Throws: If creating a concrete URL fails.
    /// - Returns: URL for the request.
    func url(on baseUrl: String) async throws -> URL

}

@available(*, deprecated, message: "Default values for deprecated properties")
public extension Endpoint {

    var encoding: ParameterEncoding { AutomaticEncoding.default }

    func url(on baseUrl: String) async throws -> URL {
        let baseUrl = try baseUrl.asURL()
        return await baseUrl.appendingPathComponent(path.resolveUrl()!.absoluteString)
    }
    
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
