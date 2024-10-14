//
//  ApiServerCollection.swift
//  GoodNetworking-Sample
//
//  Created by Andrej Jasso on 23/09/2024.
//

public struct ApiServerCollection: Codable, Hashable, Sendable {

    public let name: String
    public let servers: [ApiServer]
    public let defaultServer: ApiServer

    public init(name: String, servers: [ApiServer], defaultServer: ApiServer) {
        self.name = name
        self.servers = servers
        self.defaultServer = defaultServer
    }

}
