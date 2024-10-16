//
//  CustomBaseUrlProvider.swift
//  GoodNetworking-Sample
//
//  Created by Andrej Jasso on 23/09/2024.
//

import Foundation
import GoodNetworking

public actor SampleSelectableBaseUrlProvider: BaseUrlProviding, ObservableObject {

    // MARK: - Constants

    private let userDefaults = UserDefaults(suiteName: "CustomBaseUrlProvider")

    // MARK: - Properties

    public var serverCollection: ApiServerCollection
    public var selectedServerName: String = ""

    // MARK: - Initializer

    public init(serverCollection: ApiServerCollection) {
        self.serverCollection = serverCollection

        if let userDefaults {
            if let selectedServerName = try? userDefaults.getObject(forKey: serverCollection.name, castTo: String.self) {
                self.selectedServerName = selectedServerName
            }
        }
    }

    public func getSelectedServer() -> ApiServer {
        if let selectedServer = serverCollection.servers.first(where: { $0.name == selectedServerName }) {
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
