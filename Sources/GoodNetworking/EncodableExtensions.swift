//
//  Codable.swift
//  DepoSwiftExtensions
//
//  Created by Dominik Pethö on 11/9/18.
//

import Foundation

private var referenceKeyEncoder: UInt8 = 11
private var referenceKeyDecoder: UInt8 = 10

// MARK: - Encodable extensions

public extension Encodable {
    
    /// The `keyEncodingStrategy` property returns the default key encoding strategy of the `JSONEncoder`.
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        return JSONEncoder.KeyEncodingStrategy.useDefaultKeys
    }
    
    /// The `dateEncodingStrategy` property returns the default date encoding strategy of the `JSONEncoder`.
    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy {
        return JSONEncoder.DateEncodingStrategy.millisecondsSince1970
    }
    
    /// The `_encoder` property returns an associated `JSONEncoder` object stored with the `GREncodable` object.
    private var _encoder: JSONEncoder? {
        return (objc_getAssociatedObject(self, &referenceKeyEncoder) as? JSONEncoder)
    }
    
    /// The `encode` method returns `Data` representation of the `Encodable` object.
    /// - Throws: An error if encoding fails.
    /// - Returns: `Data` representation of the `GREncodable` object.
    func encode() throws -> Data {
        return try encoder.encode(self)
    }
    
    /// The `encoder` property returns an instance of `JSONEncoder` with the `keyEncodingStrategy` and `dateEncodingStrategy` properties set.
    var encoder: JSONEncoder {
        initEncoderIfNeeded()
        let encoder = _encoder ?? JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        encoder.dateEncodingStrategy = dateEncodingStrategy
        return encoder
    }
    
    /// Sets the associated `JSONEncoder` object if it does not already exist.
    private func initEncoderIfNeeded() {
        if _encoder == nil {
            objc_setAssociatedObject(self, &referenceKeyEncoder, JSONEncoder(), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Returns the `Encodable` object as a JSON dictionary if encoding succeeds, otherwise it returns `nil`.
    var jsonDictionary: [String: Any]? {
        guard let data = try? encoder.encode(self) else { return nil }
        
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
            .flatMap { $0 as? [String: Any] }
    }
    
    /// Converts an Encodable object to a dictionary of key-value pairs represented as Strings and Any.
    /// - Parameter encoder:  JSONEncoder object to encode the object.
    /// - Returns: A dictionary of key-value pairs represented as Strings and Any or nil if encoding or serialization fails.
    func jsonDictionary(encoder: JSONEncoder) -> [String: Any]? {
        guard let data = try? encoder.encode(self) else { return nil }
        
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
            .flatMap { $0 as? [String: Any] }
    }
    
}

// MARK: - Encodable extensions

public extension Decodable {
    
    /// Defines the `KeyDecodingStrategy` for all `Decodable` objects using this extension.
    static var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        return JSONDecoder.KeyDecodingStrategy.useDefaultKeys
    }
    
    /// A static variable that defines the `DateDecodingStrategy` for all `Decodable` objects using this extension.
    static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        return JSONDecoder.DateDecodingStrategy.millisecondsSince1970
    }
    
    /// Holds a reference to the `JSONDecoder` object associated with the `Decodable` object.
    private static var _decoder: JSONDecoder? {
        return (objc_getAssociatedObject(self, &referenceKeyDecoder) as? JSONDecoder)
    }
    
    /// Decodes the provided `Data` object into a `Decodable` object.
    /// 
    /// - Throws: `DecodingError` if the data can not be decoded.
    /// - Parameter data: The `Data` object to be decoded.
    static func decode(data: Data) throws -> Self {
        return try decoder.decode(Self.self, from: data)
    }
    
    /// A static computed property that returns the `JSONDecoder` object associated with the `Decodable` object.
    static var decoder: JSONDecoder {
        initDecoderIfNeeded()
        let decoder = _decoder ?? JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return decoder
    }
    
    /// Sets the associated `JSONDecoder` object if it does not already exist.
    private static func initDecoderIfNeeded() {
        if _decoder == nil {
            objc_setAssociatedObject(self, &referenceKeyDecoder, JSONDecoder(), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}
