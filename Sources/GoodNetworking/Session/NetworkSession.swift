//
//  NetworkSession.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 8/17/20.
//

@preconcurrency import Alamofire
import Foundation

/// Executes network requests for the client app.
///
/// `NetworkSession` is responsible for sending, downloading, and uploading data through a network session.
/// It uses a base URL provider and a session provider to manage the configuration and ensure the session's validity.
public actor NetworkSession: Hashable {

    public static func == (lhs: NetworkSession, rhs: NetworkSession) -> Bool {
        lhs.sessionId == rhs.sessionId
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(sessionId)
    }

    // MARK: - ID

    nonisolated private let sessionId: UUID = UUID()

    // MARK: - Properties

    /// The provider responsible for managing the network session, ensuring it is created, resolved, and validated.
    public let sessionProvider: NetworkSessionProviding

    /// The optional provider for resolving the base URL to be used in network requests.
    public let baseUrlProvider: BaseUrlProviding?

    // MARK: - Initialization

    /// Initializes the `NetworkSession` with an optional base URL provider and a session provider.
    ///
    /// - Parameters:
    ///   - baseUrlProvider: An optional provider for the base URL. Defaults to `nil`.
    ///   - sessionProvider: The session provider to be used. Defaults to `DefaultSessionProvider` with a default configuration.
    public init(
        baseUrlProvider: BaseUrlProviding? = nil,
        sessionProvider: NetworkSessionProviding = DefaultSessionProvider(configuration: .default())
    ) {
        self.baseUrlProvider = baseUrlProvider
        self.sessionProvider = sessionProvider
    }

    /// Initializes the `NetworkSession` with an optional base URL provider and a network session configuration.
    ///
    /// - Parameters:
    ///   - baseUrl: An optional provider for the base URL. Defaults to `nil`.
    ///   - configuration: The configuration to be used for creating the session. Defaults to `.default`.
    public init(
        baseUrl: BaseUrlProviding? = nil,
        configuration: NetworkSessionConfiguration = .default(),
        logger: NetworkLogger? = nil
    ) {
        self.baseUrlProvider = baseUrl
        self.sessionProvider = DefaultSessionProvider(configuration: configuration, logger: logger)
    }

    /// Initializes the `NetworkSession` with an optional base URL provider and an existing session.
    ///
    /// - Parameters:
    ///   - baseUrlProvider: An optional provider for the base URL. Defaults to `nil`.
    ///   - session: An existing session to be used by this provider.
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

    /// Sends a network request to an endpoint using the resolved base URL and session.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint instance representing the URL, method, parameters, and headers.
    ///   - baseUrlProvider: An optional base URL provider. If `nil`, the default `baseUrlProvider` is used.
    ///   - validationProvider: The validation provider used to validate the response. Defaults to `DefaultValidationProvider`.
    /// - Returns: The decoded result of type `Result`.
    /// - Throws: A `Failure` error if validation or the request fails.
    func request<Result: Decodable & Sendable, Failure: Error>(
        endpoint: Endpoint,
        baseUrlProvider: BaseUrlProviding? = nil,
        validationProvider: any ValidationProviding<Failure> = DefaultValidationProvider()
    ) async throws(Failure) -> Result {
        return try await catchingFailure(validationProvider: validationProvider) {
            let resolvedBaseUrl = try await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
            let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

            return try await resolvedSession.request(
                try? endpoint.url(on: resolvedBaseUrl),
                method: endpoint.method,
                parameters: endpoint.parameters?.dictionary,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .goodify(type: Result.self, validator: validationProvider)
            .value
        }
    }

    /// Sends a raw network request and returns the response data.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint instance representing the URL, method, parameters, and headers.
    ///   - baseUrlProvider: An optional base URL provider. If `nil`, the default `baseUrlProvider` is used.
    ///   - validationProvider: The validation provider used to validate the response. Defaults to `DefaultValidationProvider`.
    /// - Returns: The raw response data.
    /// - Throws: A `Failure` error if validation or the request fails.
    func requestRaw<Failure: Error>(
        endpoint: Endpoint,
        baseUrlProvider: BaseUrlProviding? = nil,
        validationProvider: any ValidationProviding<Failure> = DefaultValidationProvider()
    ) async throws(Failure) -> Data {
        return try await catchingFailure(validationProvider: validationProvider) {
            let resolvedBaseUrl = try await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
            let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

            return try await resolvedSession.request(
                try? endpoint.url(on: resolvedBaseUrl),
                method: endpoint.method,
                parameters: endpoint.parameters?.dictionary,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .serializingData()
            .value
        }
    }

    /// Sends a request and returns an unprocessed `DataRequest` object.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint instance representing the URL, method, parameters, and headers.
    ///   - baseUrlProvider: An optional base URL provider. If `nil`, the default `baseUrlProvider` is used.
    /// - Returns: A `DataRequest` object representing the raw request.
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

    /// Creates a download request for the given `endpoint` and saves the result to the specified file.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint instance representing the URL, method, parameters, and headers.
    ///   - baseUrlProvider: An optional base URL provider. Defaults to `nil`.
    ///   - customFileName: The name of the file to which the downloaded content will be saved.
    /// - Returns: A `DownloadRequest` for the file download.
    /// - Throws: A `NetworkError` if the request fails.
    func download(endpoint: Endpoint, baseUrlProvider: BaseUrlProviding? = nil, customFileName: String) async throws(NetworkError) -> DownloadRequest {
        let resolvedBaseUrl = try await resolveBaseUrl(baseUrlProvider: baseUrlProvider)
        let resolvedSession = await resolveSession(sessionProvider: sessionProvider)

        let destination: DownloadRequest.Destination = { temporaryURL, _ in
            let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let url = directoryURLs.first?.appendingPathComponent(customFileName) ?? temporaryURL

            return (url, [.removePreviousFile, .createIntermediateDirectories])
        }

        return resolvedSession.download(
            try? endpoint.url(on: resolvedBaseUrl),
            method: endpoint.method,
            parameters: endpoint.parameters?.dictionary,
            encoding: endpoint.encoding,
            headers: endpoint.headers,
            to: destination
        )
    }

}

// MARK: - Upload

public extension NetworkSession {

    /// Uploads data to the specified `endpoint` using multipart form data.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint instance representing the URL, method, parameters, and headers.
    ///   - data: The data to be uploaded.
    ///   - fileHeader: The header to use for the uploaded file in the form data. Defaults to "file".
    ///   - filename: The name of the file to be uploaded.
    ///   - mimeType: The MIME type of the file.
    ///   - baseUrlProvider: An optional base URL provider. Defaults to `nil`.
    /// - Returns: An `UploadRequest` representing the upload.
    /// - Throws: A `NetworkError` if the upload fails.
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

    /// Uploads multipart form data to the specified `endpoint`.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint instance representing the URL, method, parameters, and headers.
    ///   - multipartFormData: The multipart form data to upload.
    ///   - baseUrlProvider: An optional base URL provider. Defaults to `nil`.
    /// - Returns: An `UploadRequest` representing the upload.
    /// - Throws: A `NetworkError` if the upload fails.
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

    /// Resolves the network session, creating a new one if necessary.
    ///
    /// - Parameter sessionProvider: The provider managing the session.
    /// - Returns: The resolved or newly created `Alamofire.Session`.
    func resolveSession(sessionProvider: NetworkSessionProviding) async -> Alamofire.Session {
        if await !sessionProvider.isSessionValid {
            await sessionProvider.makeSession()
        } else {
            await sessionProvider.resolveSession()
        }
    }

    /// Resolves the base URL using the provided or default base URL provider.
    ///
    /// - Parameter baseUrlProvider: An optional base URL provider. If `nil`, the default `baseUrlProvider` is used.
    /// - Returns: The resolved base URL as a `String`.
    /// - Throws: A `NetworkError.invalidBaseURL` if the base URL cannot be resolved.
    func resolveBaseUrl(baseUrlProvider: BaseUrlProviding?) async throws(NetworkError) -> String {
        let baseUrlProvider = baseUrlProvider ?? self.baseUrlProvider
        guard let resolvedBaseUrl = await baseUrlProvider?.resolveBaseUrl() else {
            throw .invalidBaseURL
        }
        return resolvedBaseUrl
    }

    /// Executes a closure while catching and transforming failures.
    ///
    /// - Parameters:
    ///   - validationProvider: The provider used to transform any errors.
    ///   - body: The closure to execute.
    /// - Returns: The result of type `Result`.
    /// - Throws: A transformed error if the closure fails.
    func catchingFailure<Result: Decodable & Sendable, Failure: Error>(
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

}
