//
//  DeduplicatingExecutorTests.swift
//  GoodNetworking
//
//  Created by Assistant on 16/10/2024.
//

import XCTest
@testable import GoodNetworking
import Alamofire
import GoodLogger

final class DeduplicatingExecutorTests: XCTestCase {

    // MARK: - Tests
    
    func testConcurrentRequestsAreDeduplicated() async throws {
        // Setup
        let logger = TestingLogger()
        let executor = DeduplicatingRequestExecutor(taskId: "People", logger: logger)
        let session: Session! = Session()
        let baseURL = "https://swapi.dev/api"
        let networkSession = NetworkSession(baseUrlProvider: baseURL, session: session)
        // Given
        let endpoint = SwapiEndpoint.luke

        // When
        async let firstResult: SwapiPerson = networkSession.request(
            endpoint: endpoint,
            requestExecutor: executor
        )

        async let secondResult: SwapiPerson = networkSession.request(
            endpoint: endpoint,
            requestExecutor: executor
        )

        // Then
        let (result1, result2) = try await (firstResult, secondResult)
        XCTAssertEqual(result1.name, "Luke Skywalker")
        XCTAssertEqual(result2.name, "Luke Skywalker")
        XCTAssertTrue(logger.messages.contains(where: { $0.contains("Cached value used") } ))
    }

    func testConcurrentRequestsAreDeduplicatedDefaultTaskID() async throws {
        // Setup
        let logger = TestingLogger()
        let executor = DeduplicatingRequestExecutor(logger: logger)
        let session: Session! = Session()
        let baseURL = "https://swapi.dev/api"
        let networkSession = NetworkSession(baseUrlProvider: baseURL, session: session)
        // Given
        let endpoint = SwapiEndpoint.luke

        // When
        async let firstResult: SwapiPerson = networkSession.request(
            endpoint: endpoint,
            requestExecutor: executor
        )

        async let secondResult: SwapiPerson = networkSession.request(
            endpoint: endpoint,
            requestExecutor: executor
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
        let executor = DeduplicatingRequestExecutor(taskId: "Luke", logger: logger)
        let executor2 = DeduplicatingRequestExecutor(taskId: "Vader", logger: logger)
        let session: Session! = Session()
        let baseURL = "https://swapi.dev/api"
        let networkSession = NetworkSession(baseUrlProvider: baseURL, session: session)

        // Given
        let lukeEndpoint = SwapiEndpoint.luke
        let vaderEndpoint = SwapiEndpoint.vader

        // When
        async let lukeResult: SwapiPerson = networkSession.request(
            endpoint: lukeEndpoint,
            requestExecutor: executor
        )

        async let vaderResult: SwapiPerson = networkSession.request(
            endpoint: vaderEndpoint,
            requestExecutor: executor2
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
        let executor = DeduplicatingRequestExecutor(taskId: "People", logger: logger)
        let session: Session! = Session()
        let baseURL = "https://swapi.dev/api"
        let networkSession = NetworkSession(baseUrlProvider: baseURL, session: session)

        // Given
        let endpoint = SwapiEndpoint.luke
        
        // When
        async let firstResult: SwapiPerson = networkSession.request(
            endpoint: endpoint,
            requestExecutor: executor
        )

        async let secondResult: SwapiPerson = networkSession.request(
            endpoint: endpoint,
            requestExecutor: executor
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
        let executor = DeduplicatingRequestExecutor(taskId: "Invalid", logger: logger)
        let baseURL = "https://swapi.dev/api"
        let provider = DefaultSessionProvider(
            configuration: NetworkSessionConfiguration(
                eventMonitors: [LoggingEventMonitor(logger: logger)]
            )
        )
        let networkSession = NetworkSession(
            baseUrlProvider: baseURL,
            sessionProvider: provider
        )

        // Given
        let invalidEndpoint = SwapiEndpoint.invalid

        // When/Then
        do {
            let _: SwapiPerson = try await networkSession.request(endpoint: invalidEndpoint, requestExecutor: executor)

            XCTFail("Expected error to be thrown")
        } catch {
            print(logger.messages)
            XCTAssertTrue(logger.messages.contains(where: { $0.contains("Task finished with error") } ))
        }
    }
}
