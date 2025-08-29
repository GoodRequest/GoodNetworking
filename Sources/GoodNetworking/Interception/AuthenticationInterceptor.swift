//
//  AuthenticationInterceptor.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 07/08/2025.
//

import Foundation

/// Interceptor responsible for authentication of network requests.
///
/// Authentication interceptor requires an instance of ``Authenticator``, which handles
/// the logic of refreshing the credential, checking its validity or caching.
public final class AuthenticationInterceptor<AuthenticatorType: Authenticator>: Interceptor, @unchecked Sendable {

    private let authenticator: AuthenticatorType
    private let lock: AsyncLock

    public init(authenticator: AuthenticatorType) {
        self.authenticator = authenticator
        self.lock = AsyncLock()
    }

    public func adapt(urlRequest: inout URLRequest) async throws(NetworkError) {
        await lock.lock()
        defer { lock.unlock() }
        
        if let credential = await authenticator.getCredential() {
            if let refreshableCredential = credential as? RefreshableCredential, refreshableCredential.requiresRefresh {
                try await refresh(credential: credential)
            }
            try await authenticator.apply(credential: credential, to: &urlRequest)
        }
    }

    public func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult {
        // Request failed due to HTTP Error and not due to connection failure
        guard case .remote(let hTTPError) = error else {
            return .doNotRetry
        }

        // Remote failure occured due to authentication error
        guard authenticator.didRequest(&urlRequest, failDueToAuthenticationError: hTTPError) else {
            return .doNotRetry
        }
        
        // Stop further authentication with possibly invalid credential.
        // If a refresh is already in progress, stopping other requests
        // here will ensure further retries will contain the latest credentials.
        await lock.lock()
        defer { lock.unlock() }

        // A credential is available
        guard let credential = await authenticator.getCredential() else {
            return .doNotRetry
        }
        
        // Check if request is authenticated with the latest available credential
        // Retry if request was sent with invalid credential (previously expired, etc.)
        guard authenticator.isRequest(&urlRequest, authenticatedWith: credential) else {
            return .retry
        }

        // Refresh and store new token
        try await refresh(credential: credential)

        // Retry previous request by applying new authentication credential
        return .retry
    }

    private func refresh(credential: AuthenticatorType.Credential) async throws(NetworkError) {
        // Current credential must be expired at this point
        // and is safe to clear
        await authenticator.storeCredential(nil)

        // Refresh the expired credential and store new credential
        // Let user handle remote errors (eg. HTTP 403) before throwing
        // (eg. kick user from session, or automatically log out).
        do {
            let newCredential = try await authenticator.refresh(credential: credential)
            await authenticator.storeCredential(newCredential)
        } catch let error {
            if case .remote(let httpError) = error {
                await authenticator.refresh(didFailDueToError: httpError)
            }
            throw error
        }
    }

}
