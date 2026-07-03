//
//  BugfixRoundTests.swift
//  GoodNetworking
//
//  Tests covering fixes from PR #59 (bugfixing round).
//

@testable import GoodNetworking
import Testing
import Foundation

// MARK: - JSON NSNumber boolean handling

@Test func jsonDistinguishesBoolsFromNumbers() throws {
    #expect(JSON(true) == JSON.bool(true))
    #expect(JSON(NSNumber(value: true)) == JSON.bool(true))
    #expect(JSON(NSNumber(value: 1)) == JSON.number(1))
    #expect(JSON(1) == JSON.number(1))
    #expect(JSON(1.5) == JSON.number(1.5))
}

// MARK: - JSON Codable conformance

@Test func jsonCodableRoundTrip() throws {
    let original: JSON = [
        "name": "Alice",
        "age": 30,
        "isAdmin": true,
        "score": 12.5,
        "tags": ["a", "b"],
        "nested": ["key": "value"]
    ]

    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSON.self, from: encoded)

    #expect(decoded.name.string == "Alice")
    #expect(decoded.age.int == 30)
    #expect(decoded.isAdmin.bool == true)
    #expect(decoded.score.double == 12.5)
    #expect(decoded.tags.array?.count == 2)
    #expect(decoded.nested.key.string == "value")
}

// MARK: - WithCustomEncoder support in EndpointParameters

private struct SnakeCaseModel: Encodable, WithCustomEncoder {

    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    let firstName: String

}

@Test func endpointParametersUseCustomEncoder() throws {
    let parameters = EndpointParameters.model(SnakeCaseModel(firstName: "Alice"))
    let data = try #require(try parameters.data())
    let jsonString = try #require(String(data: data, encoding: .utf8))

    #expect(jsonString.contains("first_name"))
}

// MARK: - Data/Encodable metatype casting (WithCustomDecoder)

private struct SnakeCaseResponse: Decodable, WithCustomDecoder {

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    let firstName: String

}

@Test func customDecoderMetatypeCastResolves() throws {
    // Before the fix, `case let t as WithCustomDecoder` never matched a metatype,
    // silently falling back to the default decoder.
    let match = SnakeCaseResponse.self as? WithCustomDecoder.Type
    let decoder = try #require(match).decoder

    let data = Data(#"{"first_name": "Alice"}"#.utf8)
    let decoded = try decoder.decode(SnakeCaseResponse.self, from: data)
    #expect(decoded.firstName == "Alice")
}

// MARK: - Query parameter encoding (live)

@Test func queryParametersEncodeCorrectly() async throws {
    let response: JSON = try await session.request(
        endpoint: at("/products/search")
            .method(.get)
            .query([URLQueryItem(name: "q", value: "apple watch")])
    )

    let total = try #require(response.total.int)
    #expect(total > 0)
}
