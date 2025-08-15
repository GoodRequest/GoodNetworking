//
//  DefaultSessionProvider.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 14/10/2024.
//

@preconcurrency import Alamofire
import GoodLogger

/// An actor that provides a default network session using Alamofire.
///
/// `DefaultSessionProvider` conforms to `NetworkSessionProviding` and handles the creation, validation, and management
/// of default network sessions. This provider assumes that the session is always valid, and does not support session invalidation.
/// It logs session-related activities using a logger, and allows sessions to be created or resolved based on a given configuration or existing session.
///
/// - Note: This provider uses `GoodLogger` for logging session-related messages.
/// If available, it uses `OSLogLogger`, otherwise it falls back to `PrintLogger`.
public actor DefaultSessionProvider: NetworkSessionProviding {

    /// The configuration for the network session.
    ///
    /// This configuration contains details such as interceptors, server trust managers, and event monitors.
    /// It is used to create a new instance of `Alamofire.Session`.
    nonisolated public let configuration: NetworkSessionConfiguration

    /// The current session used for network requests.
    ///
    /// If a session has already been created, it is stored here. If not, the `makeSession()` function can be called to create one.
    nonisolated public let currentSession: Alamofire.Session

    /// A private property that provides the appropriate logger based on the iOS version.
    ///
    /// For iOS 14 and later, it uses `OSLogLogger`. For earlier versions, it defaults to `PrintLogger`.
    var logger: GoodLogger?

    /// Initializes the session provider with a network session configuration.
    ///
    /// - Parameter configuration: The configuration used to create network sessions.
    public init(configuration: NetworkSessionConfiguration, logger: GoodLogger? = nil) {
        self.configuration = configuration
        self.currentSession = Alamofire.Session(
            configuration: configuration.urlSessionConfiguration,
            interceptor: configuration.interceptor,
            serverTrustManager: configuration.serverTrustManager,
            eventMonitors: configuration.eventMonitors
        )

        self.logger = logger
    }

    /// Initializes the session provider with an existing `Alamofire.Session`.
    ///
    /// - Parameter session: An existing session that will be used by this provider.
    public init(session: Alamofire.Session, logger: GoodLogger? = nil) {
        self.currentSession = session
        self.configuration = NetworkSessionConfiguration(
            urlSessionConfiguration: session.sessionConfiguration,
            interceptor: session.interceptor,
            serverTrustManager: session.serverTrustManager,
            eventMonitors: [session.eventMonitor]
        )

        self.logger = logger
    }

    /// A Boolean value indicating that the session is always valid.
    ///
    /// Since the default session does not rely on any special credentials or configuration, it is always considered valid.
    /// This method logs a message indicating the session is valid.
    ///
    /// - Returns: `true`, indicating the session is valid.
    public var isSessionValid: Bool {
        logger?.log(
            message: "✅ Default session is always valid",
            level: .debug
        )
        return true
    }

    /// Logs a message indicating that the default session cannot be invalidated.
    ///
    /// Since the default session does not support invalidation, this method simply logs a message without performing any action.
    public func invalidateSession() async {
        logger?.log(
            message: "❌ Default session cannot be invalidated",
            level: .debug
        )
    }

    /// Creates and returns a new `Alamofire.Session` with the provided configuration.
    ///
    /// This method uses the stored `configuration` or falls back to a default configuration if none is provided.
    /// It logs the session creation process and returns the newly created session, storing it as the current session.
    ///
    /// - Returns: A new instance of `Alamofire.Session`.
    public func makeSession() async -> Alamofire.Session {
        logger?.log(
            message: "❌ Default Session Provider cannot be create a new Session, it's setup in the initializer",
            level: .debug
        )

        return currentSession
    }

    /// Resolves and returns the current valid session.
    ///
    /// If a session has already been created (`currentSession` is non-nil), this method returns it.
    /// Otherwise, it calls `makeSession()` to create and return a new session.
    ///
    /// - Returns: The current or newly created `Alamofire.Session`.
    public func resolveSession() async -> Alamofire.Session {
        logger?.log(
            message: "❌ Default session provider always resolves current session which is setup in the initializer",
            level: .debug
        )
        return currentSession
    }
}
