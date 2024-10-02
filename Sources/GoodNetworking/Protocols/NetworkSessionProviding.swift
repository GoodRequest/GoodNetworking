//
//  NetworkSessionProviding.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 30/09/2024.
//

import Alamofire

public protocol NetworkSessionProviding: Sendable {
    func resolveSession() async -> Alamofire.Session
}
