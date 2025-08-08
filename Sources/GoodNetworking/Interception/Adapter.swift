//
//  Adapter.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 07/08/2025.
//

import Foundation

public protocol Adapter: Sendable {

    func adapt(urlRequest: inout URLRequest) async throws(NetworkError)

}
