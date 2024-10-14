//
//  SampleNetworkSessions
//  GoodNetworking-Sample
//
//  Created by Filip Šašala on 17/07/2024.
//

import GoodNetworking
import Foundation

extension NetworkSession {

    static var sampleSession: NetworkSession!

    static func makeSampleSession() {
        NetworkSession.sampleSession = NetworkSession(baseUrl: "https://reqres.in/api")
    }

    static var baseURLProvider: SampleSelectableBaseUrlProvider?

    static func makeSampleAsyncSession() {
        let prodServer = ApiServer(name: "Prod", url: "https://reqres.in/api")

        #if DEBUG
        let devServer = ApiServer(name: "Dev", url: "https://reqres.in/api/dev")
        let testServer = ApiServer(name: "Test", url: "https://reqres.in/api/test")
        let debugServerCollection = ApiServerCollection(
            name: "Debug Server Collection",
            servers: [devServer, testServer, prodServer],
            defaultServer: prodServer
        )
        let urlProvider = SampleSelectableBaseUrlProvider(serverCollection: debugServerCollection)
        #else
        let prodServerCollection = ApiServerCollection(servers: [prodServer], defaultServer: prodServer, name: "Production Collection")
        let urlProvider = CustomBaseUrlProvider(serverCollection: prodServerCollection)
        #endif
        baseURLProvider = urlProvider
        NetworkSession.sampleSession = NetworkSession(baseUrl: urlProvider)
    }

}
