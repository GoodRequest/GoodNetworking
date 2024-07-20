////
////  Query.swift
////  GoodNetworking
////
////  Created by Filip Šašala on 10/12/2023.
////
//
//import Alamofire
//import Combine
//import Foundation
//
//#if canImport(GoodStructs)
//import GoodStructs
//public typealias Response<R> = GoodStructs.GRResult<R, AFError>
//#else
//public typealias Response<R> = Swift.Result<R, AFError>
//#endif
//
//public protocol Query: EndpointBindable, Encodable, Equatable, Sendable {
//
//    associatedtype Result: Decodable, Sendable
//
//    @MainActor var result: Response<Result>? { get set }
//
//}
//
//extension Query {
//
//    @NetworkActor internal mutating func start(using session: NetworkSession) async {
//        #if canImport(GoodStructs)
//        await updateResult(to: .loading)
//        #endif
//
//        let swiftResult = await session.request(query: self).result
//
//        #if canImport(GoodStructs)
//        await updateResult(to: swiftResult.toGRResult())
//        #else
//        await updateResult(to: swiftResult)
//        #endif
//    }
//
//    @MainActor internal mutating func updateResult(to newResult: Response<Result>) {
//        self.result = newResult
//    }
//
//}
//
//extension Query {
//
//    public static func ==(lhs: any Query, rhs: any Query) -> Bool {
//        false // every query is unique
//    }
//
//}
