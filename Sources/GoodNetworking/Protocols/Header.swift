//
//  Header.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

// MARK: - HeaderConvertible

public protocol HeaderConvertible: Sendable {

    func resolveHeader() -> HTTPHeader

}

// MARK: - HTTPHeader

public struct HTTPHeader: Equatable, Hashable, HeaderConvertible {

    public let name: String
    public let value: String

    public init(_ string: String) {
        assert(!string.isEmpty)

        let split = string.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)

        assert(split.count == 2, "Cannot parse header, missing colon: \(string)")
        assert(split[0].isEmpty == false, "Invalid header name")
        assert(split[1].isEmpty == false, "Invalid header value")

        self.name = String(split[0])
        self.value = String(split[1])
    }

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    public func resolveHeader() -> HTTPHeader {
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

public struct HTTPHeaders: Equatable, Hashable, Sendable {

    public let headers: [HTTPHeader]

    public init(_ headers: [String: String]) {
        self.headers = headers.map(HTTPHeader.init).reduce(into: [], { $0.append($1) })
    }

    public subscript(_ name: String) -> String? {
        value(for: name)
    }

    public func value(for name: String) -> String? {
        guard let index = headers.firstIndex(where: { $0.name == name }) else { return nil }
        return headers[index].value
    }

}

extension HTTPHeaders: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, String)...) {
        self.headers = elements.map(HTTPHeader.init)
    }

}

extension HTTPHeaders: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: HeaderConvertible...) {
        self.headers = elements.map { $0.resolveHeader() }
    }

}

extension HTTPHeaders: Sequence {

    public func makeIterator() -> IndexingIterator<[HTTPHeader]> {
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

    public subscript(position: Int) -> HTTPHeader {
        headers[position]
    }

    public func index(after i: Int) -> Int {
        headers.index(after: i)
    }

}

extension HTTPHeaders: CustomStringConvertible {

    public var description: String {
        headers.map(\.description).joined(separator: "\n")
    }

}
