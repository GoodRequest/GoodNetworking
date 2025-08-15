//
//  Authenticator.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 07/08/2025.
//

import Foundation

// MARK: - Authenticator

/// Authenticators provide the concrete implementation of authentication,
/// credential management and refreshing of expired credentials for
/// `AuthenticationInterceptor`.
public protocol Authenticator: Sendable {

    /// Persistent credential used to authorize requests.
    ///
    /// This is often a combination of access and refresh tokens,
    /// an API key, an authentication string, passphrase, etc..
    ///
    /// Credentials conforming to ``RefreshableCredential`` can indicate
    /// their validity and thus request a credential refresh early, resulting in better
    /// networking performance.
    associatedtype Credential
    
    /// Return the latest available credential from storage (eg. cache).
    /// - Returns: ``Credential`` if available or `nil`
    func getCredential() async -> Credential?
    
    /// Stores the new credential to storage (eg. cache).
    ///
    /// If the new credential is `nil`, this function MUST remove the
    /// cached credential from storage. Subsequent calls to ``getCredential()``
    /// must then return `nil`.
    ///
    /// - Parameter newCredential: New credential to store or `nil` if
    /// credential should be deleted.
    func storeCredential(_ newCredential: Credential?) async
    
    /// Applies the credential to a URL request.
    ///
    /// When using HTTP with Bearer authorization, this function is responsible for
    /// adding the `Authorization` header to the request.
    ///
    /// - Parameters:
    ///   - credential: Credential to be added to the request
    ///   - request: Request to modify
    func apply(credential: Credential, to request: inout URLRequest) async throws(NetworkError)
    
    /// Refreshes the expired or invalid credential.
    ///
    /// This function is responsible for refreshing the credential - the way this is done
    /// is up to the implementation. Most often it will involve making a network call
    /// to a backend authorization service.
    ///
    /// - note: Parameter `credential` may contain a valid credential, if the expiration
    /// date is known and the credential is able to request a refresh. See ``RefreshableCredential``.
    ///
    /// - important: This session will block other requests while refresh is pending.
    /// As a result, all potential refresh requests must be handled by another network session.
    ///
    /// - Parameter credential: Credential that needs to be refreshed.
    /// - Returns: Refreshed and valid credential
    /// - Throws: This function can throw a ``NetworkError``, if refreshing the credential fails, or
    /// the credential cannot be refreshed.
    func refresh(credential: Credential) async throws(NetworkError) -> Credential
    
    /// Checks whether invalid response from the backend is an authentication error.
    ///
    /// The simplest implementation would be a check if the status code is `401 Unauthorized`.
    /// This implementation, however, has a flaw. For example - in case the system gates access
    /// to resources which require a certain level of authorization, it is possible that a resource is unavailable,
    /// but the client can authenticate with a higher level of permissions to access it.
    ///
    /// - important: It is **highly recommended** to inspect the backend response and decide
    /// whether the credential is invalid/expired, or the resource is not accessible to the current user
    /// and the credential itself is correct.
    ///
    /// - Parameters:
    ///   - request: Failed URL request
    ///   - failDueToAuthenticationError: Remote error containing the backend response and status code
    /// - Returns: `true` if it can be safely determined, that the failure occured due to invalid credential
    func didRequest(_ request: inout URLRequest, failDueToAuthenticationError error: HTTPError) -> Bool
    
    /// Verifies if a request is authenticated with a given credential.
    ///
    /// The simplest implementation in a system using HTTP with Bearer authorization
    /// would be checking if access token from ``Credential`` matches the token
    /// in `Authorization` header.
    ///
    /// - Parameters:
    ///   - request: URL request to verify
    ///   - credential: Credential which is expected to authenticate the request
    /// - Returns: `true` if request is authenticated using the `credential`, or `false` otherwise
    /// (if the request is unauthenticated or the credentials do not match).
    func isRequest(_ request: inout URLRequest, authenticatedWith credential: Credential) -> Bool
    
    /// Notifies the user that credential could not be refreshed and failed due to an error.
    ///
    /// This function is often responsible for changing the app state to show an alert,
    /// open the verification/login dialog, or cleaning up now invalid resources
    /// (eg. authorized image cache).
    ///
    /// - Parameter error: Remote error containing the backend response and status code
    /// when trying to refresh invalid credential, which could not be refreshed.
    func refresh(didFailDueToError error: HTTPError) async

}

// MARK: - No authenticator

/// Empty implementation of authenticator for unauthorized network sessions.
public final class NoAuthenticator: Authenticator {

    public typealias Credential = Void

    public init() {}
    public func getCredential() async -> Credential? { nil }
    public func storeCredential(_ newCredential: Credential?) async {}
    public func apply(credential: Credential, to request: inout URLRequest) async throws(NetworkError) {}
    public func refresh(credential: Credential) async throws(NetworkError) -> Credential {}
    public func didRequest(_ request: inout URLRequest, failDueToAuthenticationError: HTTPError) -> Bool { false }
    public func isRequest(_ request: inout URLRequest, authenticatedWith credential: Credential) -> Bool { false }
    public func refresh(didFailDueToError error: HTTPError) async {}

}

// MARK: - Refreshable credential

/// Denotes that a credential is refreshable and is capable of telling whether a refresh
/// is required before making an invalid network call.
///
/// Conforming a `Credential` to this protocol is not required, however, it will
/// improve the networking performance by refreshing the token early, before a failed
/// API call.
public protocol RefreshableCredential {
    
    /// This property should return `true` if the credential knows that a refresh
    /// is required.
    ///
    /// In the simplest case it can contain logic comparing expiration date
    /// with the current date minus a time delta (eg. 5 minutes before expiration).
    ///
    var requiresRefresh: Bool { get }

}
