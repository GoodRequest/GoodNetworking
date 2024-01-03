//
//  GRSessionConfiguration.swift
//
//
//  Created by Andrej Jasso on 15/11/2022.
//

import Foundation
import Alamofire

/// The GRSessionConfiguration class represents the configuration used to create a GRSession object. This class has the following properties:
public final class NetworkSessionConfiguration {

    // MARK: - Enums

    /// The log level of the session, determines what kind of information will be logged by the `GRSessionLogger` class.
    ///
    /// error - prints only when error occurs
    /// info - prints request url with response status and error when occurs
    /// verbose - prints everything including request body and response object
    public enum LogLevel {

        case error
        case info
        case verbose
        case none

    }

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

    /// Initializes a `GRSessionConfiguration` object with the provided parameters.
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

    /// The log level of the session, determines what kind of information will be logged by the `GRSessionLogger` class.
    public static var logLevel: LogLevel = .verbose

    /// The default configuration for a `GRSession` object.
    public static let `default` = NetworkSessionConfiguration(
        urlSessionConfiguration: .default,
        interceptor: nil,
        serverTrustManager: nil,
        eventMonitors: [GRSessionLogger()]
    )

}

// MARK: - Compatibility

@available(*, deprecated, renamed: "NetworkSessionConfiguration", message: "Renamed to NetworkSessionConfiguration.")
public typealias GRSessionConfiguration = NetworkSessionConfiguration

extension NetworkSessionConfiguration {

    @available(*, deprecated, renamed: "LogLevel", message: "Renamed to LogLevel.")
    public typealias GRSessionLogLevel = LogLevel

}
