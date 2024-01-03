//
//  Query.swift
//  requestWrapper
//
//  Created by Filip Šašala on 10/12/2023.
//

import Alamofire
import Foundation

#if canImport(GoodStructs)
import GoodStructs
public typealias Response<R> = GoodStructs.GRResult<R, AFError>
#else
public typealias Response<R> = Swift.Result<R, AFError>
#endif

public protocol Query: Encodable, Equatable {

    associatedtype Result: Decodable

    var result: Response<Result>? { get set }

    static func endpoint(_ data: Self) -> Endpoint

}

extension Query {

    public static func ==(lhs: any Query, rhs: any Query) -> Bool {
        false // every query is unique
    }

}

