//
//  CodableExtensions.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 11/9/18.
//

import Foundation

// MARK: - Encodable extensions

public protocol WithCustomEncoder {
    
    static var encoder: JSONEncoder { get }
    static var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy { get }
    static var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get }
    
}

public extension Encodable where Self: WithCustomEncoder {
    
    /// The `keyEncodingStrategy` property returns the default key encoding strategy of the `JSONEncoder`.
    static var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        return JSONEncoder.KeyEncodingStrategy.useDefaultKeys
    }
    
    /// The `dateEncodingStrategy` property returns the default date encoding strategy of the `JSONEncoder`.
    static var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy {
        return JSONEncoder.DateEncodingStrategy.millisecondsSince1970
    }
    
    /// The `encoder` property returns an instance of `JSONEncoder` with the `keyEncodingStrategy` and `dateEncodingStrategy` properties set.
    static var encoder: JSONEncoder {
         let encoder = JSONEncoder()
         encoder.keyEncodingStrategy = keyEncodingStrategy
         encoder.dateEncodingStrategy = dateEncodingStrategy
         return encoder
     }
    
    /// Encoder instance
    var encoder: JSONEncoder { Self.encoder }
    
    /// The `encode` method returns `Data` representation of the `Encodable` object.
    /// - Throws: An error if encoding fails.
    /// - Returns: `Data` representation of the `Encodable` object.
    func encode() throws -> Data {
        return try encoder.encode(self)
    }
    
    /// Returns the `Encodable` object as a JSON dictionary if encoding succeeds, otherwise it returns `nil`.
    var jsonDictionary: [String: (Any & Sendable)]? {
        guard let data = try? encoder.encode(self) else { return nil }

        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
            .flatMap { $0 as? [String: (Any & Sendable)] }
    }
    
}


// MARK: - Decodable extensions

public protocol WithCustomDecoder {
    
    static var decoder: JSONDecoder { get }
    static var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { get }
    static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }
    
}

public extension Decodable where Self: WithCustomDecoder {
    
    /// Defines the `KeyDecodingStrategy` for all `Decodable WithCustomDecoder` objects using this extension.
    static var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        return JSONDecoder.KeyDecodingStrategy.useDefaultKeys
    }
    
    /// A static variable that defines the `DateDecodingStrategy` for all `Decodable WithCustomDecoder` objects using this extension.
    static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        return JSONDecoder.DateDecodingStrategy.millisecondsSince1970
    }
    
    /// A static computed property that returns the `JSONDecoder` object associated with the `Decodable WithCustomDecoder` object.
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        
        return decoder
    }
    
    /// Decoder instance
    var decoder: JSONDecoder { Self.decoder }
    
    /// Decodes the provided `Data` object into a `Decodable` object.
    ///
    /// - Throws: `DecodingError` if the data can not be decoded.
    /// - Parameter data: The `Data` object to be decoded.
    static func decode(data: Data) throws -> Self {
        return try decoder.decode(Self.self, from: data)
    }
    
}
