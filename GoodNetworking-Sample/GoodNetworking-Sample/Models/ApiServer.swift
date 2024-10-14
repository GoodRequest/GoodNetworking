//
//  ApiServer.swift
//  GoodNetworking-Sample
//
//  Created by Andrej Jasso on 23/09/2024.
//

public struct ApiServer: Codable, Hashable, Sendable {

    public let name: String
    public let url: String

    public init(name: String, url: String) {
        self.name = name
        self.url = url
    }

}
