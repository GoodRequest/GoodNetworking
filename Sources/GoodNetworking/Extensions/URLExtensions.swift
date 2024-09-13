//
//  URLExtensions.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/01/2024.
//

@preconcurrency import Alamofire
import Foundation

extension Optional<Foundation.URL>: Alamofire.URLConvertible {

    public func asURL() throws -> URL {
        guard let self else { throw URLError(.badURL) }
        return self
    }

}
