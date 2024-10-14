//
//  BaseUrlProviderTests.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 16/10/2024.
//

import XCTest
@testable import GoodNetworking

final class DefaultBaseUrlProviderTests: XCTestCase {

    // MARK: - Test Initialization

    /// Test that `DefaultBaseUrlProvider` initializes correctly with the given base URL.
    func testInitialization() {
        // Given
        let expectedBaseUrl = "https://api.example.com"

        // When
        let provider = DefaultBaseUrlProvider(baseUrl: expectedBaseUrl)

        // Then
        XCTAssertEqual(provider.baseUrl, expectedBaseUrl, "The baseUrl property should be initialized with the provided URL.")
    }

    // MARK: - Test resolveBaseUrl()

    /// Test that `resolveBaseUrl` returns the expected base URL asynchronously.
    func testResolveBaseUrl() async {
        // Given
        let expectedBaseUrl = "https://api.example.com"
        let provider = DefaultBaseUrlProvider(baseUrl: expectedBaseUrl)

        // When
        let resolvedUrl = await provider.resolveBaseUrl()

        // Then
        XCTAssertEqual(resolvedUrl, expectedBaseUrl, "The resolveBaseUrl() method should return the expected base URL.")
    }

    /// Test that `resolveBaseUrl` returns nil when initialized with an empty base URL.
    func testResolveBaseUrlReturnsNilForEmptyBaseUrl() async {
        // Given
        let provider = DefaultBaseUrlProvider(baseUrl: "")

        // When
        let resolvedUrl = await provider.resolveBaseUrl()

        // Then
        XCTAssertEqual(resolvedUrl, "", "The resolveBaseUrl() should return an empty string if the baseUrl is empty.")
    }

    /// Test that `resolveBaseUrl` returns the correct base URL when initialized with a URL containing special characters.
    func testResolveBaseUrlWithSpecialCharacters() async {
        // Given
        let specialCharacterUrl = "https://api.example.com/special!@#$%^&*()"
        let provider = DefaultBaseUrlProvider(baseUrl: specialCharacterUrl)

        // When
        let resolvedUrl = await provider.resolveBaseUrl()

        // Then
        XCTAssertEqual(resolvedUrl, specialCharacterUrl, "The resolveBaseUrl() method should return the base URL containing special characters.")
    }
}
