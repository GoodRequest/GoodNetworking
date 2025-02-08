//
//  NetworkSessionConfiguration.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 15/11/2022.
//

@preconcurrency import Alamofire
import Foundation
import GoodLogger

/// NetworkSessionConfiguration represents the configuration used to create a NetworkSession object.
public struct NetworkSessionConfiguration: Sendable {

    // MARK: - Constants

    /// The `URLSessionConfiguration` used to configure the `Session` object.
    public let urlSessionConfiguration: URLSessionConfiguration

    /// The `RequestInterceptor` used to intercept requests and modify them.
    public let interceptor: RequestInterceptor?

    /// The `ServerTrustManager` used to validate the trust of a server.
    public let serverTrustManager: ServerTrustManager?

    /// An array of `EventMonitor` objects used to monitor network events.
    public let eventMonitors: [EventMonitor]

    // MARK: - Initialization

    /// Initializes a `NetworkSessionConfiguration` object with the provided parameters.
    ///
    /// - Parameters:
    ///   - urlSessionConfiguration: The `URLSessionConfiguration` used to configure the `Session` object.
    ///   - interceptor: The `RequestInterceptor` used to intercept requests and modify them.
    ///   - serverTrustManager: The `ServerTrustManager` used to validate the trust of a server.
    ///   - eventMonitors: An array of `EventMonitor` objects used to monitor network events.
    public init(
        urlSessionConfiguration: URLSessionConfiguration = .default,
        interceptor: RequestInterceptor? = nil,
        serverTrustManager: ServerTrustManager? = nil,
        eventMonitors: [EventMonitor] = []
    ) {
        self.urlSessionConfiguration = urlSessionConfiguration
        self.interceptor = interceptor
        self.serverTrustManager = serverTrustManager
        self.eventMonitors = eventMonitors
    }

    // MARK: - Static

    /// The default configuration for a `GRSession` object.
    public static var `default`: NetworkSessionConfiguration {
        var eventMonitors: [EventMonitor] = []

        if #available(iOS 14, *) {
            eventMonitors.append(LoggingEventMonitor(logger: OSLogLogger(logMetaData: false)))
        } else {
            eventMonitors.append(LoggingEventMonitor(logger: PrintLogger(logMetaData: false)))
        }

        return NetworkSessionConfiguration(
            urlSessionConfiguration: .default,
            interceptor: nil,
            serverTrustManager: nil,
            eventMonitors: eventMonitors
        )
    }

}
