//
//  TransientSession.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 23/10/2024.
//

/// A network session that is resolved asynchronously when required, without caching.
///
/// This is useful when you need to resolve a session asynchronously depending on
/// external circumstances, such as whether an authentication token is available.
///
/// `TransientSession` acts as a wrapper around `NetworkSession`, providing
/// a mechanism for deferring the resolution of a session.
///
/// The session is supplied asynchronously via a `TransientSessionSupplier`.
public struct TransientSession {

    /// Function that will resolve a `NetworkSession` asynchronously when required.
    public typealias TransientSessionSupplier = (@Sendable () async -> NetworkSession)

    private let supplier: TransientSessionSupplier

    /// Creates `TransientSession` with a supplier for network session resolution.
    ///
    /// - Parameter supplier: A function that will provide a `NetworkSession`.
    public init(_ supplier: @escaping TransientSessionSupplier) {
        self.supplier = supplier
    }

    /// Resolves an appropriate session by calling the supplier.
    /// - Returns: Network session resolved and returned from the supplier.
    public func resolve() async -> NetworkSession {
        return await supplier()
    }
    
    /// Sugared resolution function. See ``resolve``.
    public func callAsFunction() async -> NetworkSession {
        return await resolve()
    }

}
