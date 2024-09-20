//
//  NetworkSessionProviding.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 30/09/2024.
//

import Alamofire

public protocol NetworkSessionProviding: Sendable {

    func shouldResolveNew() async -> Bool
    func resolveSession() async -> Alamofire.Session
    func cachedSession() async -> Alamofire.Session

}

extension NetworkSessionProviding {

    public func shouldResolveNew() async -> Bool { true }
    
}
