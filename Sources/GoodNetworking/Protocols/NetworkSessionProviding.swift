//
//  NetworkSessionProviding.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 30/09/2024.
//

import Alamofire

/// A protocol for managing network sessions used in network requests.
///
/// `NetworkSessionProviding` defines the methods and properties required to handle session creation, validation, and invalidation
/// when interacting with network resources. Conformers to this protocol provide logic for managing `Alamofire.Session` instances.
public protocol NetworkSessionProviding: Sendable {

    /// A Boolean property indicating whether the current session is valid.
    ///
    /// This property is checked asynchronously and returns `true` if the session is valid, or `false` if the session
    /// needs to be re-established or has been invalidated.
    var isSessionValid: Bool { get async }

    /// Invalidates the current network session.
    ///
    /// This method is responsible for terminating the current session, clearing session data, or performing any necessary cleanup.
    /// The session will need to be re-established afterward using `makeSession()`.
    func invalidateSession() async

    /// Creates and returns a new network session.
    ///
    /// This method is responsible for creating a fresh instance of `Alamofire.Session` to be used for future network requests.
    ///
    /// - Returns: A new instance of `Alamofire.Session`.
    func makeSession() async -> Alamofire.Session

    /// Resolves and returns the current valid network session.
    ///
    /// If the session is valid, this method returns the existing session. If the session is invalid, it triggers the creation
    /// of a new session by calling `makeSession()`.
    ///
    /// - Returns: The current or newly created `Alamofire.Session` instance.
    func resolveSession() async -> Alamofire.Session
    
}
