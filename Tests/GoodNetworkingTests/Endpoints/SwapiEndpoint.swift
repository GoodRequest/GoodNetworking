//
//  SwapiEndpoint.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 05/02/2025.
//

import GoodNetworking
import Alamofire

enum SwapiEndpoint: Endpoint {

    case luke
    case vader
    case invalid

    var path: String {
        switch self {
        case .luke: "/people/1"
        case .vader: "/people/4"
        case .invalid: "/invalid/path"
        }
    }
    
}
