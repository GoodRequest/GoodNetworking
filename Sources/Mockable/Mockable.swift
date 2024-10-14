//
//  Mockable.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 4/30/19.
//

import Foundation
import GoodNetworking

public protocol Mockable {

    static func mockURL(fileName: String, bundle: Bundle) -> URL?
    static func data(fileName: String, bundle: Bundle) -> Data?
    static func decodeFromFile<T: Decodable>(fileName: String, bundle: Bundle, decoder: JSONDecoder) throws -> T

}

/// The JSONTestableError is an enumeration that lists the different error cases that can occur when reading, parsing, and decoding a JSON file.
///
/// - urlNotValid: The URL to the file is not valid. This can occur if the file does not exist in the given bundle.
/// - emptyJsonData: The contents of the file could not be loaded into data.
public enum  JSONTestableError: Error {

    case urlNotValid
    case emptyJsonData

}

public class MockManager: Mockable {

    /// Returns the URL to the file with the given file name if it exists in the given bundle.
    ///
    /// - Parameters:
    ///   - fileName: The name of the file.
    ///   - bundle:   The bundle that the file is located in.
    /// - Returns:    The URL to the file if it exists, or nil if it does not.
    public static func mockURL(fileName: String, bundle: Bundle) -> URL? {
        return bundle.url(forResource: fileName, withExtension: "json")
    }

    /// Returns the data from the file with the given file name if it exists in the given bundle.
    ///
    /// - Parameters:
    ///   - fileName:  The name of the file.
    ///   - bundle:    The bundle that the file is located in.
    /// - Returns:     The data from the file if it exists, or nil if it does not.
    public static func data(fileName: String, bundle: Bundle) -> Data? {
        guard let testURL = MockManager.mockURL(fileName: fileName, bundle: bundle) else { return nil }
        return try? Data(contentsOf: testURL)
    }

    /// Returns the decoded representation of the JSON data from the file with the given file name if it exists in the given bundle.
    ///
    /// - Parameters:
    ///   - fileName:    The name of the file.
    ///   - bundle:      The bundle that the file is located in.
    ///   - decoder:     `JSONDecoder` instance used to decode  `Data`. For `Decodable` `JSONDecoder()` by default.
    ///                  For `Decodable & WithCustomDecoder` custom `decoder` used by default.
    /// - Returns:       The decoded representation of the JSON data if the file exists and can be decoded, throws an error otherwise.
    /// - Throws:
    ///   - JSONTestableError.urlNotValid if the file does not exist.
    ///   - JSONTestableError.emptyJsonData if the contents of the file cannot be loaded into data.
    public static func decodeFromFile<T: Decodable>(
        fileName: String,
        bundle: Bundle,
        decoder: JSONDecoder = (T.self as? WithCustomDecoder.Type)?.decoder ?? JSONDecoder()
    ) throws -> T {
        guard let testURL = MockManager.mockURL(fileName: fileName, bundle: bundle) else {
            throw JSONTestableError.urlNotValid

        }
        guard let jsonData = try? Data(contentsOf: testURL) else {
            throw JSONTestableError.emptyJsonData
        }

        return try decoder.decode(T.self, from: jsonData)
    }

}
