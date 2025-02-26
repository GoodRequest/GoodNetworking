//
//  MockResponse.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 07/02/2025.
//

import GoodNetworking

struct MockResponse: Codable, EmptyResponseCreatable {

    let code: Int
    let description: String

    static var emptyInstance: MockResponse {
        return MockResponse(code: 204, description: "No Content")
    }

}
