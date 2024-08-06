//
//  DeduplicatingExecutorTests.swift
//  GoodNetworking
//
//  Created by Assistant on 16/10/2024.
//

import XCTest
@testable import GoodNetworking
import Alamofire

final class DeduplicatingExecutorTests: XCTestCase {

    // MARK: - Tests
    
    func testConcurrentRequestsAreDeduplicated() async throws {
        // Setup
        let logger = TestingLogger()
        let executor = DeduplicatingRequestExecutor(taskID: "People", logger: logger)
        let session: Session! = Session()
        let baseURL = "https://swapi.dev/api"

        // Given
        let endpoint = SwapiEndpoint.luke

        // When
        async let firstResult: SwapiPerson = executor.executeRequest(
            endpoint: endpoint,
            session: session,
            baseURL: baseURL
        )
        async let secondResult: SwapiPerson = executor.executeRequest(
            endpoint: endpoint,
            session: session,
            baseURL: baseURL
        )

        // Then
        let (result1, result2) = try await (firstResult, secondResult)
        XCTAssertEqual(result1.name, "Luke Skywalker")
        XCTAssertEqual(result2.name, "Luke Skywalker")
        XCTAssertTrue(logger.messages.contains(where: { $0.contains("Cached value used") } ))
    }
    
    func testDifferentRequestsAreNotDeduplicated() async throws {
        // Setup
        let logger = TestingLogger()
        let executor = DeduplicatingRequestExecutor(taskID: "Luke", logger: logger)
        let executor2 = DeduplicatingRequestExecutor(taskID: "Vader", logger: logger)
        let session: Session! = Session()
        let baseURL = "https://swapi.dev/api"

        // Given
        let lukeEndpoint = SwapiEndpoint.luke
        let vaderEndpoint = SwapiEndpoint.vader

        // When
        async let lukeResult: SwapiPerson = executor.executeRequest(
            endpoint: lukeEndpoint,
            session: session,
            baseURL: baseURL
        )
        async let vaderResult: SwapiPerson = executor2.executeRequest(
            endpoint: vaderEndpoint,
            session: session,
            baseURL: baseURL
        )

        // Then
        let (luke, vader) = try await (lukeResult, vaderResult)
        XCTAssertEqual(luke.name, "Luke Skywalker")
        XCTAssertEqual(vader.name, "Darth Vader")
        XCTAssertFalse(logger.messages.contains(where: { $0.contains("Cached value used") } ))
    }
    
    func testSequentialRequestsAreNotDeduplicated() async throws {
        // Setup
        let logger = TestingLogger()
        let executor = DeduplicatingRequestExecutor(taskID: "People", logger: logger)
        let session: Session! = Session()
        let baseURL = "https://swapi.dev/api"

        // Given
        let endpoint = SwapiEndpoint.luke
        
        // When
        async let firstResult: SwapiPerson = executor.executeRequest(
            endpoint: endpoint,
            session: session,
            baseURL: baseURL
        )
        async let secondResult: SwapiPerson = executor.executeRequest(
            endpoint: endpoint,
            session: session,
            baseURL: baseURL
        )

        let luke = try await firstResult
        let luke2 = try await secondResult

        // Then
        XCTAssertEqual(luke.name, "Luke Skywalker")
        XCTAssertEqual(luke2.name, "Luke Skywalker")
        XCTAssertTrue(logger.messages.contains(where: { $0.contains("Cached value used") } ))
    }
    
    func testErrorHandling() async throws {
        // Setup
        let logger = TestingLogger()
        let executor = DeduplicatingRequestExecutor(taskID: "People", logger: logger)
        let session: Session! = Session()
        let baseURL = "https://swapi.dev/api"

        // Given
        let invalidEndpoint = SwapiEndpoint.invalid

        // When/Then
        do {
            let result: SwapiPerson = try await executor
                .executeRequest(endpoint: invalidEndpoint, session: session, baseURL: baseURL)

            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(logger.messages.contains(where: { $0.contains("Task finished with error") } ))
        }
    }
}
