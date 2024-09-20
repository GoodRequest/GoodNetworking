//
//  DefaultSessionProvider.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 14/10/2024.
//

@preconcurrency import Alamofire

public actor DefaultSessionProvider: NetworkSessionProviding {

    public var configuration: NetworkSessionConfiguration
    public var currentSession: Alamofire.Session?

    public init(configuration: NetworkSessionConfiguration) {
        self.configuration = configuration
    }

    public func shouldResolveNew() async -> Bool { false }

    public func cachedSession() async -> Alamofire.Session {
        if let currentSession {
            return currentSession
        } else {
            print("🛜 No cached session found")
            return await resolveSession()
        }
    }

    public func resolveSession() async -> Alamofire.Session {
        print("🛜 Resolved new URLSession with configuration: \(String(describing: configuration.urlSessionConfiguration.connectionProxyDictionary))")

        let newSession = Alamofire.Session(
            configuration: configuration.urlSessionConfiguration,
            interceptor: configuration.interceptor,
            serverTrustManager: configuration.serverTrustManager,
            eventMonitors: configuration.eventMonitors
        )

        self.currentSession = newSession

        return newSession
    }

}

public actor ConfigurableSessionProvider: NetworkSessionProviding {

    public let defaultConfiguration: NetworkSessionConfiguration
    public var currentConfiguration: NetworkSessionConfiguration
    public var shouldResolveNew = true
    public var currentSession: Alamofire.Session?

    public init(defaultConfiguration: NetworkSessionConfiguration) {
        self.defaultConfiguration = defaultConfiguration
        self.currentConfiguration = defaultConfiguration
    }

    public func updateConfiguration(with configuration: NetworkSessionConfiguration) async {
        self.currentConfiguration = configuration
        self.shouldResolveNew = true
        print("⚙️ Updated ConfigurableSessionProvider to \(configuration)")
    }

    public func shouldResolveNew() async -> Bool { shouldResolveNew }

    public func cachedSession() async -> Alamofire.Session {
        if let currentSession {
            print("🛜 Resolved old URLSession with configuration:  \(String(describing: currentConfiguration.urlSessionConfiguration.connectionProxyDictionary))")
            return currentSession
        } else {
            print("🛜 No cached session found")
            return await resolveSession()
        }
    }

    public func resolveSession() async -> Alamofire.Session {
        print("🛜 Resolved new URLSession with configuration: \(String(describing: currentConfiguration.urlSessionConfiguration.connectionProxyDictionary))")
        self.shouldResolveNew = false

        let newSession = Alamofire.Session(
            configuration: currentConfiguration.urlSessionConfiguration,
            interceptor: currentConfiguration.interceptor,
            serverTrustManager: currentConfiguration.serverTrustManager,
            eventMonitors: currentConfiguration.eventMonitors
        )
        self.currentSession = newSession
        return newSession
    }

}
