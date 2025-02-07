//
//  EmptyResponse.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 07/02/2025.
//

public struct EmptyResponse: Decodable {

    public init(from decoder: any Decoder) throws {}

    public init() {}

}

public protocol EmptyResponseCreatable {
    static var emptyInstance: Self { get }
}
