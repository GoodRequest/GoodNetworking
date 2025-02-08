//
//  NetworkSessionTests.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 16/10/2024.
//

import XCTest
import Alamofire
@testable import GoodNetworking

final class NetworkSessionTests: XCTestCase {

    // MARK: - Mock Providers

    final class MockBaseUrlProvider: BaseUrlProviding {
        private let url: String

        init(url: String) {
            self.url = url
        }

        func resolveBaseUrl() async -> String? {
            return url
        }
    }

    actor MockSessionProvider: NetworkSessionProviding {

        var isSessionValid = true
        var session: Alamofire.Session?

        func invalidateSession() async {
            isSessionValid = false
        }

        func makeSession() async -> Alamofire.Session {
            session = Alamofire.Session.default
            return session!
        }

        func resolveSession() async -> Alamofire.Session {
            if let session {
                return session
            } else {
                return await makeSession()
            }
        }

        func update(session: Alamofire.Session) async {
            self.session = session
        }

        func update(isValidState: Bool) async {
            self.isSessionValid = isValidState
        }

    }

    // MARK: - Test Initialization

    /// Test that `NetworkSession` initializes correctly with a base URL provider and session provider.
    func testInitializationWithProviders() async {
        // Given
        let baseUrlProvider = MockBaseUrlProvider(url: "https://api.example.com")
        let sessionProvider = MockSessionProvider()

        // When
        let networkSession = NetworkSession(baseUrlProvider: baseUrlProvider, sessionProvider: sessionProvider)
        let extractedBaseUrlProvider = await networkSession.baseUrlProvider
        let extractedSessionProvider = await networkSession.sessionProvider

        // Then
        XCTAssertNotNil(extractedBaseUrlProvider, "The baseUrlProvider should be initialized.")
        XCTAssertNotNil(extractedSessionProvider, "The sessionProvider should be initialized.")
    }

    /// Test that `NetworkSession` initializes correctly with a configuration.
    func testInitializationWithConfiguration() async {
        // Given
        let configuration = NetworkSessionConfiguration.default

        // When
        let networkSession = NetworkSession(configuration: configuration)
        let extractedBaseUrlProvider = await networkSession.baseUrlProvider
        let extractedSessionProvider = await networkSession.sessionProvider

        // Then
        XCTAssertNotNil(extractedSessionProvider, "The sessionProvider should be initialized with a configuration.")
        XCTAssertNil(extractedBaseUrlProvider, "The baseUrlProvider should be nil when initialized with a configuration.")
    }

    // MARK: - Test Session Resolution

    /// Test that `resolveSession()` resolves a valid session.
    func testResolveSession() async {
        // Given
        let sessionProvider = MockSessionProvider()
        let networkSession = NetworkSession(sessionProvider: sessionProvider)

        // When
        let resolvedSession = await networkSession.resolveSession(sessionProvider: sessionProvider)

        // Then
        let session = await sessionProvider.session
        XCTAssertNotNil(resolvedSession, "The resolved session should not be nil.")
        XCTAssertEqual(resolvedSession, session, "The resolved session should match the provider's session.")
    }

    /// Test that a new session is created if the current session is invalid.
    func testResolveSessionCreatesNewSessionIfInvalid() async {
        // Given
        let sessionProvider = MockSessionProvider()
        await sessionProvider.update(isValidState: false)
        let networkSession = NetworkSession(sessionProvider: sessionProvider)

        // When
        let resolvedSession = await networkSession.resolveSession(sessionProvider: sessionProvider)
        let session = await sessionProvider.session
        // Then
        XCTAssertNotNil(resolvedSession, "A new session should be created if the current session is invalid.")
        XCTAssertEqual(resolvedSession, session, "The newly created session should match the provider's session.")
    }

}
