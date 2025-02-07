//
//  DefaultRequestExecutorTests.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 07/02/2025.
//

import XCTest
@testable import GoodNetworking
import Alamofire
import GoodLogger

final class DefaultRequestExecutorTests: XCTestCase {

    // MARK: - Tests

    func testConcurrentRequests() async throws {
        // Setup
        let logger = TestingLogger()
        let executor = DefaultRequestExecutor()
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
    }

    func testErrorHandling() async throws {
        // Setup
        let logger = TestingLogger()
        let executor = DefaultRequestExecutor()
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
            XCTAssertTrue(error != nil)
        }
    }
}

final class DefaultRequestExecutorTestsGenerated: XCTestCase {

    // MARK: - Properties

    private var executor: DefaultRequestExecutor!
    private var session: Session!
    private var networkSession: NetworkSession!

    /// A private property that provides the appropriate logger based on the iOS version.
    ///
    /// For iOS 14 and later, it uses `OSLogLogger`. For earlier versions, it defaults to `PrintLogger`.
    private var logger: GoodLogger {
        if #available(iOS 14, *) {
            return OSLogLogger(logMetaData: true)
        } else {
            return PrintLogger(logMetaData: true)
        }
    }

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        executor = DefaultRequestExecutor()
        session = Session()
        let baseURL = "https://httpstat.us"
        networkSession = NetworkSession(baseUrlProvider: baseURL)
    }

    override func tearDown() {
        executor = nil
        session = nil
        networkSession = nil
        super.tearDown()
    }

    // MARK: - Success Responses (2xx)

    func testSuccess200OK() async throws {
        let response: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(200), requestExecutor: executor)
        XCTAssertEqual(response.code, 200)
    }

    func testCreated201() async throws {
        let response: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(201), requestExecutor: executor)
        XCTAssertEqual(response.code, 201)
    }

    func testAccepted202() async throws {
        let response: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(202), requestExecutor: executor)
        XCTAssertEqual(response.code, 202)
    }

    func testNoContent204() async throws {
        let response: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(204), requestExecutor: executor)
        XCTAssertEqual(response.code, 204)

//        do {
//            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(204), requestExecutor: executor)
//            XCTFail("Expected no content error")
//        } catch {
//            print(error.localizedDescription)
//            XCTAssertTrue(error.statusCode == 204)
//        }
    }

    // MARK: - Redirection Responses (3xx)

    func testPermanentRedirectToHTMLExpectingJSON301() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(301), requestExecutor: executor)
            XCTFail("Expected 301 error")
        } catch {
            XCTAssert(error == NetworkError.missingRemoteData)
        }
    }

    func testTemporaryRedirect301() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(301), requestExecutor: executor)
            XCTFail("Expected 301 error")
        } catch {
            XCTAssert(error == NetworkError.missingRemoteData)
        }
    }

    func testTemporaryRedirect307() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(307), requestExecutor: executor)
            XCTFail("Expected 307 error")
        } catch {
            XCTAssertTrue(error.statusCode == 200)
        }
    }

    func testNotModified304() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(304), requestExecutor: executor)
            XCTFail("Expected 304 error")
        } catch {
            XCTAssertTrue(error.statusCode == 200)
        }
    }

    // MARK: - Client Errors (4xx)

    func testBadRequest400() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(400), requestExecutor: executor)
            XCTFail("Expected 400 error")
        } catch {
            XCTAssertTrue(error.statusCode == 400)
        }
    }

    func testUnauthorized401() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(401), requestExecutor: executor)
            XCTFail("Expected 401 error")
        } catch {
            XCTAssertTrue(error.statusCode == 401)
        }
    }

    func testForbidden403() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(403), requestExecutor: executor)
            XCTFail("Expected 403 error")
        } catch {
            XCTAssertTrue(error.statusCode == 403)
        }
    }

    func testNotFound404() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(404), requestExecutor: executor)
            XCTFail("Expected 404 error")
        } catch {
            XCTAssertTrue(error.statusCode == 404)
        }
    }

    func testTooManyRequests429() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(429), requestExecutor: executor)
            XCTFail("Expected 429 error")
        } catch {
            XCTAssertTrue(error.statusCode == 429)
        }
    }

    // MARK: - Server Errors (5xx)

    func testInternalServerError500() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(500), requestExecutor: executor)
            XCTFail("Expected 500 error")
        } catch {
            XCTAssertTrue(error.statusCode == 500)
        }
    }

    func testBadGateway502() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(502), requestExecutor: executor)
            XCTFail("Expected 502 error")
        } catch {
            XCTAssertTrue(error.statusCode == 502)
        }
    }

    func testServiceUnavailable503() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(503), requestExecutor: executor)
            XCTFail("Expected 503 error")
        } catch {
            XCTAssertTrue(error.statusCode == 503)
        }
    }

    func testGatewayTimeout504() async throws {
        do {
            let _: MockResponse = try await networkSession.request(endpoint: StatusAPI.status(504), requestExecutor: executor)
            XCTFail("Expected 504 error")
        } catch {
            XCTAssertTrue(error.statusCode == 504)
        }
    }

}
