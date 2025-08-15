//
//  HTTPHeader.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

import Foundation

// MARK: - HTTPHeader

/// HTTP headers are colon separated name-value pairs used for specifying request
/// details, authentication and more.
public struct HTTPHeader: Equatable, Hashable, Sendable, HeaderConvertible {

    public let name: String
    public let value: String
    
    /// Try to initialize ``HTTPHeader`` from string value. If string is `nil`
    /// or cannot be parsed as a valid header, initializer will fail.
    ///
    /// - Parameter string: String to parse as a HTTP header
    public init?(from string: String?) {
        guard let string, !string.isEmpty else { return nil }
        
        let split = string.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)

        guard split.count == 2 else { return nil }
        guard split[0].isEmpty == false else { return nil }
        guard split[1].isEmpty == false else { return nil }

        self.name = String(split[0])
        self.value = String(split[1])
    }

    /// Initialize ``HTTPHeader`` from string value. String must be a valid header,
    /// otherwise the initialization will trip an assertion.
    ///
    /// - Parameter string: String representation of a HTTP header
    public init(_ string: String) {
        assert(!string.isEmpty)

        let split = string.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)

        assert(split.count == 2, "Cannot parse header, missing colon: \(string)")
        assert(split[0].isEmpty == false, "Invalid header name")
        assert(split[1].isEmpty == false, "Invalid header value")

        self.name = String(split[0])
        self.value = String(split[1])
    }
    
    /// Initialize ``HTTPHeader`` as a name-value pair.
    ///
    /// - Parameters:
    ///   - name: Name of the header (part before colon)
    ///   - value: Value of the header (part after colon)
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    public func resolveHeader() -> HTTPHeader? {
        self
    }

}

extension HTTPHeader: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {

    public init(stringLiteral value: String) {
        self.init(value)
    }

}

extension HTTPHeader: CustomStringConvertible {

    public var description: String {
        "\(name): \(value)"
    }

}

// MARK: - HTTPHeaders

/// A collection of multiple headers. Can contain any entities convertible to
/// ``HTTPHeader`` (``HeaderConvertible``). Final header names
/// and values are resolved at the time the request is sent.
public struct HTTPHeaders: Sendable {
    
    /// List of contained headers
    public var headers: [any HeaderConvertible]
    
    /// Create collection of ``HTTPHeader``-s from key-value dictionary mapped as
    /// name-value header pairs.
    ///
    /// - Parameter headers: Dictionary, where keys are header names
    public init(_ headers: [String: String]) {
        self.headers = headers.map(HTTPHeader.init).reduce(into: [], { $0.append($1) })
    }
    
    /// Creates HTTPHeaders struct from array(s) of ``HeaderConvertible``.
    ///
    /// Individual elements will not be resolved to ``HTTPHeader`` instances
    /// during initialization.
    ///
    /// - Parameter elements: Single or multiple arrays of elements to be treated as headers
    public init(_ elements: [any HeaderConvertible]...) {
        self.headers = []
        elements.forEach { headers.append(contentsOf: $0) }
    }

    /// Get the value of a header with name `name`
    public subscript(_ name: String) -> String? {
        value(for: name)
    }
    
    /// Resolves all headers to their final values and returns the value for header
    /// with a given name.
    ///
    /// - important: This operation resolves all header values and can be expensive
    ///
    /// - Parameter name: Name of the header
    /// - Returns: Value of the specified header
    public func value(for name: String) -> String? {
        let resolved = resolve()
        guard let index = resolved.firstIndex(where: { $0.name == name }) else { return nil }
        return resolved[index].value
    }
    
    /// Appends a new entity to the header collection. Does not resolve
    /// the header name or value.
    ///
    /// - Parameter header: New header
    public mutating func add(header: any HeaderConvertible) {
        headers.append(header)
    }
    
    /// Resolve all headers to their final values.
    ///
    /// - Returns: Array of resolved headers as ``HTTPHeader``-s
    public func resolve() -> [HTTPHeader] {
        headers.compactMap { $0.resolveHeader() }
    }

}

extension HTTPHeaders: Equatable, Hashable {
    
    nonisolated public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.resolve() == rhs.resolve()
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        for header in self.resolve() {
            hasher.combine(header)
        }
    }
    
}

extension HTTPHeaders: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, String)...) {
        self.headers = elements.map(HTTPHeader.init)
    }

}

extension HTTPHeaders: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: HeaderConvertible...) {
        self.headers = elements
    }

}

extension HTTPHeaders: Sequence {

    public func makeIterator() -> IndexingIterator<[any HeaderConvertible]> {
        headers.makeIterator()
    }

}

extension HTTPHeaders: Collection {

    public var startIndex: Int {
        headers.startIndex
    }

    public var endIndex: Int {
        headers.endIndex
    }

    public subscript(position: Int) -> any HeaderConvertible {
        headers[position]
    }

    public func index(after i: Int) -> Int {
        headers.index(after: i)
    }

}

extension HTTPHeaders: CustomStringConvertible {

    public var description: String {
        self.resolve().map(\.description).joined(separator: "\n")
    }

}

// MARK: - HeaderConvertible

/// Allows conforming entities to be converted to ``HTTPHeader``
/// for use in HTTP requests.
public protocol HeaderConvertible: Sendable {
    
    /// Resolves the final name and value of the header.
    ///
    /// This function will be called every time for each header
    /// before a network request is sent.
    ///
    /// If header cannot be resolved, this function can return `nil`.
    ///
    /// - Returns: Valid HTTP header (name-value pair) or nil
    func resolveHeader() -> HTTPHeader?

}

extension String: HeaderConvertible {
    
    public func resolveHeader() -> HTTPHeader? {
        HTTPHeader(self)
    }
    
}
