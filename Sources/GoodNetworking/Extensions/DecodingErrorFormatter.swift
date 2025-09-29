//
//  DecodingErrorFormatter.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 29/09/2025.
//

import Foundation

internal extension DecodingError {

    var prettyPrinted: String {
        switch self {
        case .typeMismatch(_, let context),
             .valueNotFound(_, let context),
             .keyNotFound(_, let context),
             .dataCorrupted(let context):
            """
            ⛔️ Decoding failed - \(context.debugDescription)
               Coding path: \(context.codingPath.prettyPrinted)
            """

        @unknown default:
            "⛔️ Decoding failed - unknown error"
        }
    }

}

private extension Array where Element == CodingKey {

    var prettyPrinted: String {
        map { $0.prettyPrinted }.joined(separator: " → ")
    }

}

private extension CodingKey {

    var prettyPrinted: String {
        if let intValue = intValue {
            return "[\(intValue)]"
        }
        return stringValue
    }

}
