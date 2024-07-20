//
//  NetworkSessions.swift
//  GoodNetworking-Sample
//
//  Created by Filip Šašala on 17/07/2024.
//

import GoodNetworking

extension NetworkSession {

    static var sampleSession: NetworkSession!

    static func makeSampleSession() {
        NetworkSession.sampleSession = NetworkSession(
            baseUrl: "https://reqres.in/api"
        )
    }

}
