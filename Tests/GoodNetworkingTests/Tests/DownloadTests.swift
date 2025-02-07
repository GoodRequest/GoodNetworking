//
//  DownloadTests.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 07/02/2025.
//

import XCTest
@testable import GoodNetworking
import Alamofire
import GoodLogger

final class DownloadTests: XCTestCase {

    // MARK: - Properties

    private var networkSession: NetworkSession!
    private var baseURL = "https://pdfobject.com/pdf/sample.pdf"
    private var baseURL2 = "https://cartographicperspectives.org/index.php/journal/article/download/cp13-full/pdf/4742"
    private var baseURL3 = "https://invalid.com/pdf/invalid.pdf"

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        networkSession = NetworkSession(baseUrlProvider: baseURL)
    }

    override func tearDown() {
        networkSession = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testDownloadWithFast() async throws {
        // Given
        let downloadEndpoint = DownloadEndpoint()
        var progressValues: [Double] = []
        var url: URL!

        // When
        for try await completion in try await networkSession.download(
            endpoint: downloadEndpoint,
            baseUrlProvider: baseURL,
            customFileName: "SamplePDFTest"
        ) {
            print((completion.progress * 100).rounded(), "/100%")
            progressValues.append(completion.progress)
            url = completion.url
        }

        // Then
        XCTAssertFalse(progressValues.isEmpty)
        XCTAssertEqual(progressValues.last!, 1.0, accuracy: 0.01)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }

    func testDownloadWithProgressLong() async throws {
        // Given
        let downloadEndpoint = DownloadEndpoint()
        var progressValues: [Double] = []
        var url: URL!

        // When
        for try await completion in try await networkSession.download(
            endpoint: downloadEndpoint,
            baseUrlProvider: baseURL2,
            customFileName: "SamplePDFTest"
        ) {
            print((completion.progress * 100).rounded(), "/100%")
            progressValues.append(completion.progress)
            url = completion.url
        }

        // Then
        XCTAssertFalse(progressValues.isEmpty)
        XCTAssertEqual(progressValues.last!, 1.0, accuracy: 0.01)
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }

    func testDownloadWithInvalidURL() async throws {
        // Given
        let downloadEndpoint = DownloadEndpoint()
        var progressValues: [Double] = []
        var url: URL!

        // When/Then
        do {
            for try await completion in try await networkSession.download(
                endpoint: downloadEndpoint,
                baseUrlProvider: baseURL3,
                customFileName: "SamplePDFTest"
            ) {
                print((completion.progress * 100).rounded(), "/100%")
                progressValues.append(completion.progress)
                url = completion.url
            }
            XCTFail("Expected download to fail for invalid URL")
        } catch {
            // Then
            XCTAssertTrue(
                error is URLError || error is AFError || error is NetworkError,
                "Expected URLError or AFError, got \(type(of: error))"
            )
        }
    }

}

private struct DownloadEndpoint: Endpoint {
    var path: String = ""
    var method: HTTPMethod = .get
    var parameters: Parameters? = nil
    var headers: HTTPHeaders? = nil
    var encoding: ParameterEncoding = URLEncoding.default
}
