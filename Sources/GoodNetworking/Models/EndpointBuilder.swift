//
//  EndpointBuilder.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 06/08/2025.
//

import Foundation

/// Modified implementation of factory pattern to build
/// endpoint as a series of function calls instead of conforming
/// to a protocol.
public final class EndpointBuilder: Endpoint {
    
    public var path: URLConvertible
    public var method: HTTPMethod = .get
    
    public var headers: HTTPHeaders? = []
    public var parameters: EndpointParameters?
    
    @available(*, deprecated)
    public var encoding: ParameterEncoding? {
        AutomaticEncoding.default
    }
    
    init(at path: URLConvertible) {
        self.path = path
    }

}

public extension EndpointBuilder {
    
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

    func header(_ headerConvertible: any HeaderConvertible) -> Self {
        if let header = headerConvertible.resolveHeader() {
            self.headers?.add(header: header)
        }
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
    
    func query(_ items: URLQueryItem...) -> Self {
        assertBothQueryAndBodyUsage()
        self.parameters = .query(items)
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
    
}

private extension EndpointBuilder {
    
    func assertBothQueryAndBodyUsage() {
        assert(self.parameters == nil, "Support for query and body parameters at the same time is currently not available.")
    }
    
}

public func at(_ path: URLConvertible) -> EndpointBuilder {
    EndpointBuilder(at: path)
}

@available(*, deprecated, renamed: "EndpointBuilder")
public typealias EndpointFactory = EndpointBuilder
