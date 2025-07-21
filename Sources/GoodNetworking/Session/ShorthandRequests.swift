//
//  ShorthandRequests.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 30/07/2025.
//

import Foundation

// MARK: - Shorthand requests - GET

extension NetworkSession {
    
    public func get<T: Decodable>(_ path: URLConvertible) async throws(NetworkError) -> T {
        return try await request(endpoint: at(path).method(.get))
    }
    
    public func get(_ path: URLConvertible) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.get))
    }
    
    public func get(_ path: URLConvertible) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.get))
    }

}

// MARK: - Shorthand requests - POST

extension NetworkSession {
    
    // Codable
    
    public func post<T: Encodable, R: Decodable>(_ path: URLConvertible, _ model: T) async throws(NetworkError) -> R {
        return try await request(endpoint: at(path).method(.post).body(model: model))
    }
    
    public func post<R: Decodable>(_ path: URLConvertible, _ body: JSON) async throws(NetworkError) -> R {
        return try await request(endpoint: at(path).method(.post).body(json: body))
    }
    
    public func post<R: Decodable>(_ path: URLConvertible, data: Data? = nil) async throws(NetworkError) -> R {
        return try await request(endpoint: at(path).method(.post).body(data: data))
    }
    
    // JSON
    
    @discardableResult
    public func post<T: Encodable>(_ path: URLConvertible, _ model: T) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.post).body(model: model))
    }
    
    @discardableResult
    public func post(_ path: URLConvertible, _ body: JSON) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.post).body(json: body))
    }
    
    @discardableResult
    public func post(_ path: URLConvertible, data: Data? = nil) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.post).body(data: data))
    }
    
    // Raw
    
    public func post<T: Encodable>(_ path: URLConvertible, _ model: T) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.post).body(model: model))
    }
    
    public func post(_ path: URLConvertible, _ body: JSON) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.post).body(json: body))
    }
    
    public func post(_ path: URLConvertible, data: Data?) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.post).body(data: data))
    }
    
}

// MARK: - Shorthand requests - PUT

extension NetworkSession {
    
    // Codable
    
    public func put<T: Encodable, R: Decodable>(_ path: URLConvertible, _ model: T) async throws(NetworkError) -> R {
        return try await request(endpoint: at(path).method(.put).body(model: model))
    }
    
    public func put<R: Decodable>(_ path: URLConvertible, _ body: JSON) async throws(NetworkError) -> R {
        return try await request(endpoint: at(path).method(.put).body(json: body))
    }
    
    public func put<R: Decodable>(_ path: URLConvertible, data: Data? = nil) async throws(NetworkError) -> R {
        return try await request(endpoint: at(path).method(.put).body(data: data))
    }
    
    // JSON
    
    @discardableResult
    public func put<T: Encodable>(_ path: URLConvertible, _ model: T) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.put).body(model: model))
    }
    
    @discardableResult
    public func put(_ path: URLConvertible, _ body: JSON) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.put).body(json: body))
    }
    
    @discardableResult
    public func put(_ path: URLConvertible, data: Data? = nil) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.put).body(data: data))
    }
    
    // Raw
    
    public func put<T: Encodable>(_ path: URLConvertible, _ model: T) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.put).body(model: model))
    }
    
    public func put(_ path: URLConvertible, _ body: JSON) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.put).body(json: body))
    }
    
    public func put(_ path: URLConvertible, data: Data?) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.put).body(data: data))
    }
    
}

// MARK: - Shorthand requests - DELETE

extension NetworkSession {
    
    // Codable
    
    public func delete<T: Encodable, R: Decodable>(_ path: URLConvertible, _ model: T) async throws(NetworkError) -> R {
        return try await request(endpoint: at(path).method(.delete).body(model: model))
    }
    
    public func delete<R: Decodable>(_ path: URLConvertible, _ body: JSON) async throws(NetworkError) -> R {
        return try await request(endpoint: at(path).method(.delete).body(json: body))
    }
    
    public func delete<R: Decodable>(_ path: URLConvertible, data: Data? = nil) async throws(NetworkError) -> R {
        return try await request(endpoint: at(path).method(.delete).body(data: data))
    }
    
    // JSON
    
    @discardableResult
    public func delete<T: Encodable>(_ path: URLConvertible, _ model: T) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.delete).body(model: model))
    }
    
    @discardableResult
    public func delete(_ path: URLConvertible, _ body: JSON) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.delete).body(json: body))
    }
    
    @discardableResult
    public func delete(_ path: URLConvertible, data: Data? = nil) async throws(NetworkError) -> JSON {
        return try await request(endpoint: at(path).method(.delete).body(data: data))
    }
    
    // Raw
    
    public func delete<T: Encodable>(_ path: URLConvertible, _ model: T) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.delete).body(model: model))
    }
    
    public func delete(_ path: URLConvertible, _ body: JSON) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.delete).body(json: body))
    }
    
    public func delete(_ path: URLConvertible, data: Data?) async throws(NetworkError) -> Data {
        return try await request(endpoint: at(path).method(.delete).body(data: data))
    }
    
}
