//
//  StatusAPI.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 07/02/2025.
//

import GoodNetworking
import Alamofire

enum StatusAPI: Endpoint {

    case status(Int)

    var path: String {
        switch self {
        case .status(let code): return "\(code)"
        }
    }

    var headers: HTTPHeaders? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

}
