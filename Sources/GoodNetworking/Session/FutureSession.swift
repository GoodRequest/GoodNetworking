//
//  FutureSession.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 14/10/2024.
//

/// A network session that is resolved asynchronously when required and cached for subsequent usages.
///
/// `FutureSession` acts as a wrapper around `NetworkSession`, providing a mechanism for lazily loading and caching the session.
/// The session is supplied asynchronously via a `FutureSessionSupplier` and is cached upon first use, allowing subsequent
/// requests to reuse the same session instance without needing to recreate it.
public actor FutureSession {

    /// The type alias for a supplier function that provides a `NetworkSession` asynchronously.
    public typealias FutureSessionSupplier = (@Sendable () async -> NetworkSession)

    private var supplier: FutureSessionSupplier
    private var sessionCache: NetworkSession?

    /// Provides access to the cached network session.
    ///
    /// If the session has already been cached, it returns the existing instance. If not, it uses the `supplier`
    /// function to create a new session, caches it, and then returns the newly created session.
    public var cachedSession: NetworkSession {
        get async {
            let session = sessionCache
            if let session {
                return session
            } else {
                // Resolve and cache the session for future use
                sessionCache = await supplier()
                return sessionCache!
            }
        }
    }

    /// Initializes the `FutureSession` with a supplier function for the network session.
    ///
    /// - Parameter supplier: A function that provides a `NetworkSession` asynchronously.
    public init(_ supplier: @escaping FutureSessionSupplier) {
        self.supplier = supplier
    }

    /// Allows the `FutureSession` to be called as a function to retrieve the cached network session.
    ///
    /// - Returns: The cached or newly resolved `NetworkSession`.
    public func callAsFunction() async -> NetworkSession {
        return await cachedSession
    }

}

internal extension FutureSession {

    /// A placeholder `FutureSession` used as a fallback.
    ///
    /// This placeholder is intended for internal use only and serves as a default instance when no valid session is provided.
    /// It will trigger a runtime error if accessed, indicating that a valid network session should be supplied using `Resource.session(:)`.
    static let placeholder: FutureSession = FutureSession {
        preconditionFailure("No session supplied. Use Resource.session(:) to provide a valid network session.")
    }

}
