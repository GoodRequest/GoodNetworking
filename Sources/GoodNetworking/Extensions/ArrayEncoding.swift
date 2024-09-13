//
//  ArrayEncoding.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 18/10/2023.
//

@preconcurrency import Alamofire
import Foundation

/// Extension that allows an array be sent as a request parameters
public extension Array where Element: Sendable {

    /// Convert the receiver array to a `Parameters` object.
    func asParameters() -> Parameters {
        return [ArrayEncoding.arrayParametersKey: self]
    }
    
}

/// Convert the parameters into a json array, and it is added as the request body.
/// The array must be sent as parameters using its `asParameters` method.
public struct ArrayEncoding: ParameterEncoding {
    
    public static let arrayParametersKey = "arrayParametersKey"

    public let defaultEncoder: ParameterEncoding

    public init(defaultEncoder: ParameterEncoding) {
        self.defaultEncoder = defaultEncoder
    }

    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        guard let array = parameters?[Self.arrayParametersKey] else {
            return try defaultEncoder.encode(urlRequest, with: parameters)
        }

        return try JSONEncoding.default.encode(urlRequest, withJSONObject: array)
    }
    
}
