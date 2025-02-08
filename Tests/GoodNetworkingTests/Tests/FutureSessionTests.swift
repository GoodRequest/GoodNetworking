//
//  FutureSessionTests.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 16/10/2024.
//

import XCTest
@testable import GoodNetworking

final class FutureSessionTests: XCTestCase {

    // MARK: - Test Initialization

    /// Test that `FutureSession` initializes correctly with a valid supplier function.
    func testInitialization() {
        // Given
        let sessionSupplier: FutureSession.FutureSessionSupplier = { NetworkSession(baseUrlProvider: DefaultBaseUrlProvider(baseUrl: "https://api.example.com")) }

        // When
        let futureSession = FutureSession(sessionSupplier)

        // Then
        XCTAssertNotNil(futureSession, "The FutureSession should be initialized successfully with a valid supplier.")
    }

    // MARK: - Test Cached Session

    /// Test that the cached session is resolved using the supplier and cached for future use.
    func testCachedSessionResolution() async {
        final class Counter: @unchecked Sendable {
            var count: Int = 0
            func increment() { count += 1 }
        }
        let counter = Counter()

        // Given
        let sessionSupplier: FutureSession.FutureSessionSupplier = {
            counter.increment()
            return NetworkSession(baseUrlProvider: DefaultBaseUrlProvider(baseUrl: "https://api.example.com"))
        }
        let futureSession = FutureSession(sessionSupplier)

        // When
        let firstSession = await futureSession.cachedSession
        let secondSession = await futureSession.cachedSession

        // Then
        XCTAssertNotNil(firstSession, "The cachedSession should not be nil after being resolved.")
        XCTAssertEqual(firstSession, secondSession, "The cachedSession should return the same instance for subsequent accesses.")
        XCTAssertEqual(counter.count, 1, "The supplier should only be called once, and the session should be cached for subsequent accesses.")
    }

    /// Test that `callAsFunction` returns the same cached session instance.
    func testCallAsFunctionReturnsCachedSession() async {
        // Given
        let sessionSupplier: FutureSession.FutureSessionSupplier = {
            NetworkSession(baseUrlProvider: DefaultBaseUrlProvider(baseUrl: "https://api.example.com"))
        }
        let futureSession = FutureSession(sessionSupplier)

        // When
        let firstSession = await futureSession()
        let secondSession = await futureSession()

        // Then
        XCTAssertNotNil(firstSession, "The callAsFunction() method should not return nil.")
        XCTAssertEqual(firstSession, secondSession, "The callAsFunction() method should return the same cached session instance for subsequent calls.")
    }

}
