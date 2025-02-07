//
//  DefaultSessionProviderTests.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 16/10/2024.
//

import XCTest
@testable import GoodNetworking
import Alamofire

extension Alamofire.Session: @retroactive Equatable {}
extension Alamofire.Session: @retroactive Hashable {

    var id: Int { hashValue }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sessionConfiguration)
    }

    public static func == (lhs: Alamofire.Session, rhs: Alamofire.Session) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

}

final class DefaultSessionProviderTests: XCTestCase {

    // MARK: - Test Initialization

    /// Test that `DefaultSessionProvider` initializes correctly with a given configuration.
    func testInitializationWithConfiguration() async {
        // Given
        let configuration = NetworkSessionConfiguration.default

        // When
        let provider = DefaultSessionProvider(configuration: configuration)
        let providerConfiguration = provider.configuration

        // Then
        XCTAssertNotNil( providerConfiguration, "The configuration property should be initialized with the provided configuration.")
        XCTAssertNotNil(provider.currentSession, "The currentSession property should NOT be nil upon initialization with a configuration.")
    }

    /// Test that `DefaultSessionProvider` initializes correctly with an existing Alamofire session.
    func testInitializationWithExistingSession() async {
        // Given
        let existingSession = Alamofire.Session.default

        // When
        let provider = DefaultSessionProvider(session: existingSession)

        // Then
        XCTAssertNotNil(provider.currentSession, "The currentSession property should be initialized with the provided session.")
        XCTAssertEqual(provider.currentSession.id, existingSession.id, "The currentSession should be equal to the provided session.")
        XCTAssertNotNil(provider.configuration, "The configuration property should be nil when initialized with an existing session.")
    }

    // MARK: - Test isSessionValid

    /// Test that `isSessionValid` always returns true and logs a message.
    func testIsSessionValid() async {
        // Given
        let provider = DefaultSessionProvider(configuration: .default)

        // When
        let isValid = await provider.isSessionValid

        // Then
        XCTAssertTrue(isValid, "The isSessionValid property should always return true for DefaultSessionProvider.")
    }

    // MARK: - Test invalidateSession()

    /// Test that `invalidateSession()` logs a message but does not affect session validity.
    func testInvalidateSession() async {
        // Given
        let provider = DefaultSessionProvider(configuration: .default)

        // When
        await provider.invalidateSession()
        let isSessionValid = await provider.isSessionValid

        // Then
        XCTAssertTrue(isSessionValid, "The isSessionValid property should still be true after calling invalidateSession().")
    }

    // MARK: - Test makeSession()

    /// Test that `makeSession()` creates a new Alamofire session with the correct configuration.
    func testMakeSession() async {
        // Given
        let configuration = NetworkSessionConfiguration.default
        let provider = DefaultSessionProvider(configuration: configuration)

        // When
        let newSession = await provider.makeSession()

        // Then
        XCTAssertNotNil(provider.currentSession, "The currentSession property should not be nil after calling makeSession().")
        XCTAssertEqual(provider.currentSession.id, newSession.id, "The currentSession should be equal to the newly created session.")
    }

    // MARK: - Test resolveSession()

    /// Test that `resolveSession()` returns an existing session if it exists.
    func testResolveSessionWithExistingSession() async {
        // Given
        let existingSession = Alamofire.Session.default
        let provider = DefaultSessionProvider(session: existingSession)

        // When
        let resolvedSession = await provider.resolveSession()

        // Then
        XCTAssertEqual(resolvedSession.id, existingSession.id, "The resolveSession() should return the existing session if it already exists.")
    }

    /// Test that `resolveSession()` uses the correct configuration to create a new session.
    func testResolveSessionWithCorrectConfiguration() async {
        // Given
        let customConfiguration = NetworkSessionConfiguration(
            urlSessionConfiguration: URLSessionConfiguration.default,
            interceptor: nil,
            serverTrustManager: nil,
            eventMonitors: []
        )
        let provider = DefaultSessionProvider(configuration: customConfiguration)

        // When
        let resolvedSession = await provider.resolveSession()

        // Then
        XCTAssertEqual(resolvedSession.sessionConfiguration, customConfiguration.urlSessionConfiguration, "The resolved session should use the provided custom configuration.")
    }

}
