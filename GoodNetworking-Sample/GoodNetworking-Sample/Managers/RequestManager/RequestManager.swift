//
//  RequestManager.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import GoodNetworking
import Combine
import Alamofire

enum ApiServer: String {

    case base = "https://swapi.dev/api/"

}

final class RequestManager: RequestManagerType {

    private let session: GRSession<Endpoint, ApiServer>

    init(baseServer: ApiServer) {
        session = GRSession(baseURL: baseServer, configuration: .default)
    }

    func fetchHero(heroId: Int) -> RequestPublisher<HeroResponse> {
        return session.request(endpoint: .hero(id: heroId))
            .goodify()
            .eraseToAnyPublisher()
    }

}
