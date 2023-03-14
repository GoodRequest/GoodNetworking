//
//  CodableExtensions.swift
//  
//
//  Created by Dominik Pethö on 11/9/18.
//

import Foundation

// MARK: - Encodable extensions

public protocol WithCustomEncoder {
    
    var encoder: JSONEncoder { get }
    
}

public extension Encodable where Self: WithCustomEncoder {
    
    /// The `encode` method returns `Data` representation of the `Encodable` object.
    /// - Throws: An error if encoding fails.
    /// - Returns: `Data` representation of the `Encodable` object.
    func encode() throws -> Data {
        return try encoder.encode(self)
    }
    
    /// Returns the `Encodable` object as a JSON dictionary if encoding succeeds, otherwise it returns `nil`.
    var jsonDictionary: [String: Any]? {
        guard let data = try? encoder.encode(self) else { return nil }

        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
            .flatMap { $0 as? [String: Any] }
    }
    
}


// MARK: - Decodable extensions

public protocol WithCustomDecoder {
    
    static var decoder: JSONDecoder { get }
    
}

public extension Decodable where Self: WithCustomDecoder {
    
    var decoder: JSONDecoder { Self.decoder }
    
    /// Decodes the provided `Data` object into a `Decodable` object.
    ///
    /// - Throws: `DecodingError` if the data can not be decoded.
    /// - Parameter data: The `Data` object to be decoded.
    static func decode(data: Data) throws -> Self {
        return try decoder.decode(Self.self, from: data)
    }
    
}
