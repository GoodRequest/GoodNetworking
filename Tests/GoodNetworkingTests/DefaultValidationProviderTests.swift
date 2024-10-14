//
//  DefaultValidationProviderTests.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 16/10/2024.
//

import XCTest
@testable import GoodNetworking

final class DefaultValidationProviderTests: XCTestCase {

    // MARK: - Test Initialization

    /// Test that `DefaultValidationProvider` initializes correctly.
    func testInitialization() {
        // Given & When
        let validationProvider = DefaultValidationProvider()

        // Then
        XCTAssertNotNil(validationProvider, "The DefaultValidationProvider should be initialized successfully.")
    }

    // MARK: - Test Validation

    /// Test that `validate(statusCode:data:)` does not throw an error for a successful status code (200-299).
    func testValidateSuccessStatusCode() {
        // Given
        let validationProvider = DefaultValidationProvider()
        let statusCode = 200
        let data = Data() // Empty data for testing

        // When & Then
        XCTAssertNoThrow(
            try validationProvider.validate(statusCode: statusCode, data: data),
            "The validate method should not throw an error for a successful status code."
        )
    }

    /// Test that `validate(statusCode:data:)` throws a `NetworkError.remote` for a status code outside the 200-299 range.
    func testValidateFailureStatusCode() {
        // Given
        let validationProvider = DefaultValidationProvider()
        let statusCode = 404
        let data = Data() // Empty data for testing

        // When & Then
        XCTAssertThrowsError(
            try validationProvider.validate(statusCode: statusCode, data: data),
            "The validate method should throw an error for a status code outside the 200-299 range."
        ) { error in
            // Verify that the thrown error is of type `NetworkError.remote`
            guard case let NetworkError.remote(receivedStatusCode, receivedData) = error else {
                return XCTFail("Expected NetworkError.remote, but got \(error)")
            }

            XCTAssertEqual(receivedStatusCode, statusCode, "The status code in the error should match the input status code.")
            XCTAssertEqual(receivedData, data, "The data in the error should match the input data.")
        }
    }

    /// Test that `validate(statusCode:data:)` throws a `NetworkError.remote` for a status code below 200.
    func testValidateFailureStatusCodeBelow200() {
        // Given
        let validationProvider = DefaultValidationProvider()
        let statusCode = 199
        let data = Data() // Empty data for testing

        // When & Then
        XCTAssertThrowsError(
            try validationProvider.validate(statusCode: statusCode, data: data),
            "The validate method should throw an error for a status code below 200."
        ) { error in
            guard case let NetworkError.remote(receivedStatusCode, receivedData) = error else {
                return XCTFail("Expected NetworkError.remote, but got \(error)")
            }

            XCTAssertEqual(receivedStatusCode, statusCode, "The status code in the error should match the input status code.")
            XCTAssertEqual(receivedData, data, "The data in the error should match the input data.")
        }
    }

    /// Test that `validate(statusCode:data:)` throws a `NetworkError.remote` for a status code of 300 or above.
    func testValidateFailureStatusCode300OrAbove() {
        // Given
        let validationProvider = DefaultValidationProvider()
        let statusCode = 300
        let data = Data() // Empty data for testing

        // When & Then
        XCTAssertThrowsError(
            try validationProvider.validate(statusCode: statusCode, data: data),
            "The validate method should throw an error for a status code of 300 or above."
        ) { error in
            guard case let NetworkError.remote(receivedStatusCode, receivedData) = error else {
                return XCTFail("Expected NetworkError.remote, but got \(error)")
            }

            XCTAssertEqual(receivedStatusCode, statusCode, "The status code in the error should match the input status code.")
            XCTAssertEqual(receivedData, data, "The data in the error should match the input data.")
        }
    }

    // MARK: - Test Error Transformation

    /// Test that `transformError(_:)` returns the same `NetworkError` instance.
    func testTransformError() {
        // Given
        let validationProvider = DefaultValidationProvider()
        let networkError = NetworkError.remote(statusCode: 404, data: Data())

        // When
        let transformedError = validationProvider.transformError(networkError)

        // Then
        XCTAssertEqual(transformedError, networkError, "The transformError method should return the same NetworkError instance.")
    }
    
}
