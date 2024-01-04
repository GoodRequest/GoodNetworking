//
//  Query.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 10/12/2023.
//

import Alamofire
import Combine
import Foundation

#if canImport(GoodStructs)
import GoodStructs
public typealias Response<R> = GoodStructs.GRResult<R, AFError>
#else
public typealias Response<R> = Swift.Result<R, AFError>
#endif

public protocol Query: EndpointBindable, Encodable, Equatable {

    associatedtype Result: Decodable

    var result: Response<Result>? { get set }

}

extension Query {

    internal func dataTaskPublisher(using session: NetworkSession) -> AnyPublisher<Response<Result>, Never> {
        return session.request(endpoint: Self.endpoint(self))
            .goodify(type: Result.self)
            .receive(on: DispatchQueue.main)
            .map { .success($0) }
            .catch { Just(.failure($0)) }
        #if canImport(GoodStructs)
            .prepend(.loading)
        #endif
            .eraseToAnyPublisher()
    }

}

extension Query {

    public static func ==(lhs: any Query, rhs: any Query) -> Bool {
        false // every query is unique
    }

}
