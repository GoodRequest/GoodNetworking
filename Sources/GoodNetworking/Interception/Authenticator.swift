//
//  Authenticator.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 07/08/2025.
//

import Foundation

// MARK: - Authenticator

public protocol Authenticator: Sendable {

    associatedtype Credential

    func getCredential() async -> Credential?
    func storeCredential(_ newCredential: Credential?) async

    func apply(credential: Credential, to request: inout URLRequest) async throws(NetworkError)
    func refresh(credential: Credential) async throws(NetworkError) -> Credential
    func didRequest(_ request: inout URLRequest, failDueToAuthenticationError: HTTPError) -> Bool
    func isRequest(_ request: inout URLRequest, authenticatedWith credential: Credential) -> Bool
    func refresh(didFailDueToError error: HTTPError) async

}

// MARK: - No authenticator

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

public protocol RefreshableCredential {

    var requiresRefresh: Bool { get }

}
