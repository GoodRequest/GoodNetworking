//
//  NetworkSession.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 8/17/20.
//

@preconcurrency import Alamofire
import Foundation

/// A type responsible for executing network requests in a client application.
///
/// `NetworkSession` provides a high-level interface for making HTTP requests, handling downloads,
/// and managing file uploads. It uses a combination of base URL providers and session providers
/// to ensure proper configuration and session management.
///
/// Key features:
/// - Supports typed network requests with automatic decoding
/// - Handles file downloads with customizable destinations
/// - Provides multipart form data upload capabilities
/// - Manages session lifecycle and validation
/// - Supports custom base URL resolution
///
/// Example usage:
/// ```swift
/// let session = NetworkSession()
/// let result: MyResponse = try await session.request(endpoint: myEndpoint)
/// ```
public actor NetworkSession: Hashable {

    /// A type constraint requiring that network response types are both decodable and sendable.
    public typealias DataType = Decodable & Sendable

    /// Compares two NetworkSession instances for equality based on their session IDs.
    ///
    /// - Parameters:
    ///   - lhs: The first NetworkSession to compare
    ///   - rhs: The second NetworkSession to compare
    /// - Returns: `true` if both sessions have the same ID, `false` otherwise
    public static func == (lhs: NetworkSession, rhs: NetworkSession) -> Bool {
        lhs.sessionId == rhs.sessionId
    }

    /// Hashes the essential components of the NetworkSession.
    ///
    /// - Parameter hasher: The hasher to use for combining the session's components
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(sessionId)
    }

    // MARK: - ID

    /// A unique identifier for this network session instance.
    nonisolated private let sessionId: UUID = UUID()

    // MARK: - Properties

    /// The provider that manages the underlying network session.
    ///
    /// This provider is responsible for:
    /// - Creating new sessions when needed
    /// - Validating existing sessions
    /// - Resolving session configurations
    public let sessionProvider: NetworkSessionProviding

    /// A provider that resolves the base URL for network requests.
    ///
    /// The base URL provider allows for dynamic URL resolution, which is useful for:
    /// - Environment-specific URLs (staging, production)
    /// - Multi-tenant applications
    /// - A/B testing different API endpoints
    public let baseUrlProvider: BaseUrlProviding?

    // MARK: - Initialization

    /// Creates a new NetworkSession with custom providers.
    ///
    /// This initializer offers the most flexibility in configuring the session's behavior.
    ///
    /// - Parameters:
    ///   - baseUrlProvider: A provider for resolving base URLs. Pass `nil` to disable base URL resolution.
    ///   - sessionProvider: A provider for managing the network session. Defaults to a standard configuration.
    public init(
        baseUrlProvider: BaseUrlProviding? = nil,
        sessionProvider: NetworkSessionProviding = DefaultSessionProvider(configuration: .default)
    ) {
        self.baseUrlProvider = baseUrlProvider
        self.sessionProvider = sessionProvider
    }

    /// Creates a new NetworkSession with a base URL provider and configuration.
    ///
    /// This initializer is convenient when you need custom configuration but want to use the default session provider.
    ///
    /// - Parameters:
    ///   - baseUrl: A provider for resolving base URLs. Pass `nil` to disable base URL resolution.
    ///   - configuration: The configuration to use for the session. Defaults to `.default`.
    public init(
        baseUrl: BaseUrlProviding? = nil,
        configuration: NetworkSessionConfiguration = .default
    ) {
        self.baseUrlProvider = baseUrl
        self.sessionProvider = DefaultSessionProvider(configuration: configuration)
    }

    /// Creates a new NetworkSession with an existing Alamofire session.
    ///
    /// This initializer is useful when you need to integrate with existing Alamofire configurations.
    ///
    /// - Parameters:
    ///   - baseUrlProvider: A provider for resolving base URLs. Pass `nil` to disable base URL resolution.
    ///   - session: An existing Alamofire session to use.
    public init(
        baseUrlProvider: BaseUrlProviding? = nil,
        session: Alamofire.Session
    ) {
        self.baseUrlProvider = baseUrlProvider
        self.sessionProvider = DefaultSessionProvider(session: session)
    }

}

// MARK: - Request

public extension NetworkSession {

    /// Performs a network request that returns a decoded response.
    ///
    /// This method handles the complete lifecycle of a network request, including:
    /// - Base URL resolution
    /// - Session validation
    /// - Request execution
    /// - Response validation
    /// - Error transformation
    /// - Response decoding
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request, containing URL, method, parameters, and headers
    ///   - baseUrlProvider: Optional override for the base URL provider
    ///   - validationProvider: Provider for custom response validation logic
    ///   - resultProvider: Optional provider for resolving results without network calls
    ///   - requestExecutor: The component responsible for executing the network request
    /// - Returns: A decoded instance of the specified Result type
    /// - Throws: A Failure error if any step in the request process fails
    func request<Failure: Error>(
        endpoint: Endpoint,
        baseUrlProvider: BaseUrlProviding? = nil,
        requestExecutor: RequestExecuting = DefaultRequestExecutor(),
        validationProvider: any ValidationProviding<Failure> = DefaultValidationProvider()
    ) async throws(Failure) {
        try await catchingFailureEmpty(validationProvider: validationProvider) {
            let resolvedBaseUrl = try await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
            let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

            // If not call request executor to use the API
            let response = await requestExecutor.executeRequest(
                endpoint: endpoint,
                session: resolvedSession,
                baseURL: resolvedBaseUrl
            )

            guard let statusCode = response.response?.statusCode else {
                throw response.error ?? NetworkError.sessionError
            }

            // Validate API result from executor
            try validationProvider.validate(statusCode: statusCode, data: response.data)
        }
    }

    /// Performs a network request that returns a decoded response.
    ///
    /// This method handles the complete lifecycle of a network request, including:
    /// - Base URL resolution
    /// - Session validation
    /// - Request execution
    /// - Response validation
    /// - Error transformation
    /// - Response decoding
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request, containing URL, method, parameters, and headers
    ///   - baseUrlProvider: Optional override for the base URL provider
    ///   - validationProvider: Provider for custom response validation logic
    ///   - resultProvider: Optional provider for resolving results without network calls
    ///   - requestExecutor: The component responsible for executing the network request
    /// - Returns: A decoded instance of the specified Result type
    /// - Throws: A Failure error if any step in the request process fails
    func request<Result: DataType, Failure: Error>(
        endpoint: Endpoint,
        baseUrlProvider: BaseUrlProviding? = nil,
        resultProvider: ResultProviding? = nil,
        requestExecutor: RequestExecuting = DefaultRequestExecutor(),
        validationProvider: any ValidationProviding<Failure> = DefaultValidationProvider()
    ) async throws(Failure) -> Result {
        return try await catchingFailure(validationProvider: validationProvider) {
            let resolvedBaseUrl = try await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
            let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

            // Try resolve provided data
            if let result: Result = await resultProvider?.resolveResult(endpoint: endpoint) {
                // If available directly return them
                return result
            } else {
                // If not call request executor to use the API
                let response = await requestExecutor.executeRequest(
                    endpoint: endpoint,
                    session: resolvedSession,
                    baseURL: resolvedBaseUrl
                )

                guard let statusCode = response.response?.statusCode else {
                    throw response.error ?? NetworkError.sessionError
                }

                // Validate API result from executor
                try validationProvider.validate(statusCode: statusCode, data: response.data)

                // Decode
                return try decodeResponse(response)
            }
        }
    }

    /// Performs a network request that returns raw response data.
    ///
    /// This method is useful when you need access to the raw response data without any decoding,
    /// such as when handling binary data or implementing custom decoding logic.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request, containing URL, method, parameters, and headers
    ///   - baseUrlProvider: Optional override for the base URL provider
    ///   - validationProvider: Provider for custom response validation logic
    /// - Returns: The raw response data
    /// - Throws: A Failure error if the request or validation fails
    func requestRaw<Failure: Error>(
        endpoint: Endpoint,
        baseUrlProvider: BaseUrlProviding? = nil,
        resultProvider: ResultProviding? = nil,
        requestExecutor: RequestExecuting = DefaultRequestExecutor(),
        validationProvider: any ValidationProviding<Failure> = DefaultValidationProvider()
    ) async throws(Failure) -> Data {
        return try await catchingFailure(validationProvider: validationProvider) {
            let resolvedBaseUrl = try await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
            let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

            if let result: Data = await resultProvider?.resolveResult(endpoint: endpoint) {
                return result
            } else {
                let response = await requestExecutor.executeRequest(
                    endpoint: endpoint,
                    session: resolvedSession,
                    baseURL: resolvedBaseUrl
                )

                guard let statusCode = response.response?.statusCode else {
                    throw response.error ?? NetworkError.sessionError
                }

                try validationProvider.validate(statusCode: statusCode, data: response.data)

                return response.data ?? Data()
            }
        }
    }

    /// Creates and returns an unprocessed Alamofire DataRequest.
    ///
    /// This method provides low-level access to the underlying Alamofire request object,
    /// allowing for custom request handling and response processing.
    ///
    /// - Warning: This is a disfavored overload. Consider using the typed request methods instead.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to request, containing URL, method, parameters, and headers
    ///   - baseUrlProvider: Optional override for the base URL provider
    /// - Returns: An Alamofire DataRequest instance
    @_disfavoredOverload func request(endpoint: Endpoint, baseUrlProvider: BaseUrlProviding? = nil) async -> DataRequest {
        let resolvedBaseUrl = try? await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
        let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

        return resolvedSession.request(
            try? endpoint.url(on: resolvedBaseUrl ?? ""),
            method: endpoint.method,
            parameters: endpoint.parameters?.dictionary,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
    }

}

// MARK: - Download

public extension NetworkSession {

    /// Creates a download request that saves the response to a file and provides progress updates.
    ///
    /// This method handles downloading files from a network endpoint and saving them
    /// to the app's documents directory. It supports:
    /// - Custom file naming
    /// - Automatic directory creation
    /// - Previous file removal
    /// - Progress tracking via AsyncStream
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to download from
    ///   - baseUrlProvider: Optional override for the base URL provider
    ///   - customFileName: The name to use for the saved file
    /// - Returns: An AsyncStream that emits download progress and final URL
    /// - Throws: A NetworkError if the download setup fails
    func download<Failure: Error>(
        endpoint: Endpoint,
        baseUrlProvider: BaseUrlProviding? = nil,
        customFileName: String,
        validationProvider: any ValidationProviding<Failure> = DefaultValidationProvider()
    ) -> AsyncThrowingStream<(progress: Double, url: URL?), Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Resolve the base URL and session before starting the stream
                    let resolvedBaseUrl = try await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
                    let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

                    // Ensure we can create a valid URL
                    guard let downloadURL = try? endpoint.url(on: resolvedBaseUrl) else {
                        continuation.finish(throwing: validationProvider.transformError(NetworkError.invalidBaseURL))
                        return
                    }

                    // Set up file destination
                    let destination: DownloadRequest.Destination = { temporaryURL, _ in
                        let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                        let url = directoryURLs.first?.appendingPathComponent(customFileName) ?? temporaryURL
                        return (url, [.removePreviousFile, .createIntermediateDirectories])
                    }

                    // Start the download
                    let request = resolvedSession.download(
                        downloadURL,
                        method: endpoint.method,
                        parameters: endpoint.parameters?.dictionary,
                        encoding: endpoint.encoding,
                        headers: endpoint.headers,
                        to: destination
                    )

                    // Monitor progress
                    request.downloadProgress { progress in
                        continuation.yield((progress: progress.fractionCompleted, url: nil))
                    }

                    // Handle response
                    request.response { response in
                        switch response.result {
                        case .success:
                            if let destinationURL = response.fileURL {
                                continuation.yield((progress: 1.0, url: destinationURL))
                            } else {
                                continuation.finish(throwing: validationProvider.transformError(.missingRemoteData))
                            }
                        case .failure(let error):
                            continuation.finish(throwing: error)
                        }

                        continuation.finish()
                    }

                } catch {
                    continuation.finish(throwing: validationProvider.transformError(.sessionError))
                }
            }
        }
    }

}

// MARK: - Upload

public extension NetworkSession {

    /// Uploads data as multipart form data with a single file.
    ///
    /// This method simplifies uploading a single file as part of a multipart form request.
    /// It automatically handles the multipart form data construction.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to upload to
    ///   - data: The file data to upload
    ///   - fileHeader: The form field name for the file. Defaults to "file"
    ///   - filename: The name of the file being uploaded
    ///   - mimeType: The MIME type of the file
    ///   - baseUrlProvider: Optional override for the base URL provider
    /// - Returns: An Alamofire UploadRequest instance
    /// - Throws: A NetworkError if the upload setup fails
    func uploadWithMultipart(
        endpoint: Endpoint,
        data: Data,
        fileHeader: String = "file",
        filename: String,
        mimeType: String,
        baseUrlProvider: BaseUrlProviding? = nil
    ) async throws(NetworkError) -> UploadRequest {
        let resolvedBaseUrl = try await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
        let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

        return resolvedSession.upload(
            multipartFormData: { formData in
                formData.append(data, withName: fileHeader, fileName: filename, mimeType: mimeType)
            },
            to: try? endpoint.url(on: resolvedBaseUrl),
            method: endpoint.method,
            headers: endpoint.headers
        )
    }

    /// Uploads custom multipart form data.
    ///
    /// This method provides full control over the multipart form data construction,
    /// allowing for complex form data with multiple files and fields.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to upload to
    ///   - multipartFormData: The pre-constructed multipart form data
    ///   - baseUrlProvider: Optional override for the base URL provider
    /// - Returns: An Alamofire UploadRequest instance
    /// - Throws: A NetworkError if the upload setup fails
    func uploadWithMultipart(
        endpoint: Endpoint,
        multipartFormData: MultipartFormData,
        baseUrlProvider: BaseUrlProviding? = nil
    ) async throws(NetworkError) -> UploadRequest {
        let resolvedBaseUrl = try await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
        let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

        return resolvedSession.upload(
            multipartFormData: multipartFormData,
            to: try? endpoint.url(on: resolvedBaseUrl),
            method: endpoint.method,
            headers: endpoint.headers
        )
    }

}

// MARK: - Internal

extension NetworkSession {

    /// Ensures a valid session is available for use.
    ///
    /// This method manages the session lifecycle by:
    /// - Checking the current session's validity
    /// - Creating a new session if needed
    /// - Resolving the current session state
    ///
    /// - Parameter sessionProvider: The provider managing the session
    /// - Returns: A valid Alamofire Session instance
    func resolveSession(sessionProvider: NetworkSessionProviding) async -> Alamofire.Session {
        if await !sessionProvider.isSessionValid {
            await sessionProvider.makeSession()
        } else {
            await sessionProvider.resolveSession()
        }
    }

    /// Resolves the base URL for a request.
    ///
    /// This method handles the base URL resolution process by:
    /// - Using the provided override if available
    /// - Falling back to the session's base URL provider
    /// - Validating the resolved URL
    ///
    /// - Parameter baseUrlProvider: Optional override provider for the base URL
    /// - Returns: The resolved base URL as a string
    /// - Throws: NetworkError.invalidBaseURL if URL resolution fails
    func resolveBaseUrl(baseUrlProvider: BaseUrlProviding?) async throws(NetworkError) -> String {
        let baseUrlProvider = baseUrlProvider ?? self.baseUrlProvider
        guard let resolvedBaseUrl = await baseUrlProvider?.resolveBaseUrl() else {
            throw .invalidBaseURL
        }
        return resolvedBaseUrl
    }

    /// Executes code with standardized error handling.
    ///
    /// This method provides consistent error handling by:
    /// - Catching and transforming network errors
    /// - Handling Alamofire-specific errors
    /// - Converting errors to the expected failure type
    ///
    /// - Parameters:
    ///   - validationProvider: Provider for error transformation
    ///   - body: The code to execute
    /// - Returns: The result of type Result
    /// - Throws: A transformed error matching the Failure type
    func catchingFailure<Result: DataType, Failure: Error>(
        validationProvider: any ValidationProviding<Failure>,
        body: () async throws -> Result
    ) async throws(Failure) -> Result {
        do {
            return try await body()
        } catch let networkError as NetworkError {
            throw validationProvider.transformError(networkError)
        } catch let error as AFError {
            if let underlyingError = error.underlyingError as? Failure {
                throw underlyingError
            } else if let underlyingError = error.underlyingError as? NetworkError {
                throw validationProvider.transformError(underlyingError)
            } else {
                throw validationProvider.transformError(NetworkError.sessionError)
            }
        } catch {
            throw validationProvider.transformError(NetworkError.sessionError)
        }
    }

    /// Executes code with standardized error handling.
    ///
    /// This method provides consistent error handling by:
    /// - Catching and transforming network errors
    /// - Handling Alamofire-specific errors
    /// - Converting errors to the expected failure type
    ///
    /// - Parameters:
    ///   - validationProvider: Provider for error transformation
    ///   - body: The code to execute
    /// - Returns: The result of type Result
    /// - Throws: A transformed error matching the Failure type
    func catchingFailureEmpty<Failure: Error>(
        validationProvider: any ValidationProviding<Failure>,
        body: () async throws -> Void
    ) async throws(Failure) {
        do {
            return try await body()
        } catch let networkError as NetworkError {
            throw validationProvider.transformError(networkError)
        } catch let error as AFError {
            if let underlyingError = error.underlyingError as? Failure {
                throw underlyingError
            } else if let underlyingError = error.underlyingError as? NetworkError {
                throw validationProvider.transformError(underlyingError)
            } else {
                throw validationProvider.transformError(NetworkError.sessionError)
            }
        } catch {
            throw validationProvider.transformError(NetworkError.sessionError)
        }
    }

    func decodeResponse<Result: Decodable>(
        _ response: DataResponse<Data?, AFError>,
        defaultDecoder: JSONDecoder = JSONDecoder()
    ) throws -> Result {
        let decoder = (Result.self as? WithCustomDecoder.Type)?.decoder ?? defaultDecoder
        return try decoder.decode(Result.self, from: response.data ?? Data())
    }

}
