//
//  CustomBaseUrlProvider.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 23/09/2024.
//

import Foundation
import GoodNetworking

public actor SampleSelectableBaseUrlProvider: BaseUrlProviding, ObservableObject {

    // MARK: - Properties

    private let userDefaults = UserDefaults(suiteName: "CustomBaseUrlProvider")
    public var serverCollection: ApiServerCollection
    public var customServers: [ApiServer] = []
    public var selectedServerName: String = ""

    // MARK: - Initializer

    public init(serverCollection: ApiServerCollection) {
        self.serverCollection = serverCollection

        if let userDefaults {
            if let customServers = try? userDefaults.getObject(forKey: "CustomServers", castTo: [ApiServer].self) {
                self.customServers = customServers
            }

            if let selectedServerName = try? userDefaults.getObject(forKey: serverCollection.name, castTo: String.self) {
                self.selectedServerName = selectedServerName
            }
        }
    }

    // MARK: - Methods

    #warning("new Swift predicate")
    public func addCustomServer(customServerUrlString: String, customName: String, collectionName: String) {
        let urlPredicate = NSPredicate(format: "SELF MATCHES %@", "^https://[A-Za-z0-9.-]{2,}\\.[A-Za-z]{2,}(?:/[^\\s]*)?$")
        if urlPredicate.evaluate(with: customServerUrlString) {
            let customServer = ApiServer(name: customName, url: customServerUrlString)
            customServers.append(customServer)
            saveToUserDefaults(customServers, key: "CustomServers")
        }
    }

    public func getSelectedServer() -> ApiServer {
        if let selectedServer = serverCollection.servers.first(where: { $0.name == selectedServerName }) {
            return selectedServer
        } else if let selectedServer = customServers.first(where: { $0.name == selectedServerName }){
            return selectedServer
        }

        return serverCollection.defaultServer
    }


    public func setSelectedServer(_ server: ApiServer) {
        self.selectedServerName = server.name
        saveToUserDefaults(server.name, key: serverCollection.name)
    }

    private func saveToUserDefaults(_ object: Encodable, key: String) {
        do {
            try userDefaults?.setObject(object, forKey: key)
        } catch {
            print(error)
        }
    }

    public func resolveBaseUrl() async -> String? {
        return getSelectedServer().url
    }

}
