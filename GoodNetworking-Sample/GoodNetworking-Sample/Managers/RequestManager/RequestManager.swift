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

    private let session: NetworkSession

    init(baseServer: ApiServer) {
        session = NetworkSession(baseUrl: baseServer.rawValue, configuration: .default)
    }

    func fetchHero(heroId: Int) -> RequestPublisher<HeroResponse> {
        return session.request(endpoint: Endpoint.hero(id: heroId))
            .goodify()
            .eraseToAnyPublisher()
    }

}
