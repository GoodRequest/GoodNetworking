//
//  Endpoint.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import Foundation
import GoodNetworking
import Alamofire

enum Endpoint: GoodNetworking.Endpoint {

case hero(id: Int)

    var path: String {
        switch self {
        case .hero(let id):
            return "people/\(id)"
        }
    }

    var method: HTTPMethod { .get }

    var parameters: EndpointParameters? {
        return nil
    }

    var headers: HTTPHeaders? {
        .default
    }

    var encoding: ParameterEncoding { JSONEncoding.default }

    func url(on baseURL: String) throws -> URL {
        var url = try baseURL.asURL()
        url.appendPathComponent(path)
        return url
    }

}
