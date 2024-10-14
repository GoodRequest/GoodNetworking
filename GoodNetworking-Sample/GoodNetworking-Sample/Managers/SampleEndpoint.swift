//
//  SampleEndpoint.swift
//  GoodNetworking-Sample
//
//  Created by Filip Šašala on 17/07/2024.
//

import Alamofire
import Foundation
import GoodNetworking

enum SampleEndpoint: Endpoint {

    case listUsers(page: Int)
    case singleUser(id: Int)
    case createUser(JobUser)
    case updateUser(JobUser)
    case deleteUser(id: String)

    var path: String {
        switch self {
        case .listUsers:
            "users"

        case .singleUser(let id):
            "users/\(id)"

        case .createUser:
            "users"

        case .updateUser(let user):
            "users/\(user.id ?? "-")"

        case .deleteUser(let id):
            "users/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .listUsers, .singleUser:
            return .get

        case .createUser:
            return .post

        case .updateUser:
            return .put

        case .deleteUser:
            return .delete
        }
    }

    var parameters: EndpointParameters? {
        switch self {
        case .singleUser:
            return nil

        case .listUsers(let page):
            return .parameters([
                "page": page
            ])

        case .createUser(let user):
            return .model(user)

        case .updateUser(let user):
            return .model(user)

        case .deleteUser:
            return nil
        }
    }

    var headers: HTTPHeaders? {
        switch self {
        default:
            nil
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .updateUser:
            JSONEncoding.default

        default:
            URLEncoding.default
        }
    }

    func url(on baseUrl: String) throws -> URL {
        let baseUrl = try baseUrl.asURL()
        return baseUrl.appendingPathComponent(path)
    }

}
