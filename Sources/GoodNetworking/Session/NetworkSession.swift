//
//  NetworkSession.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 8/17/20.
//

@preconcurrency import Alamofire
import Foundation

/// Network session that is resolved asynchronously when required and cached for subsequent usages
public actor FutureSession {

    public typealias FutureSessionSupplier = (@Sendable () async -> NetworkSession)

    private var supplier: FutureSessionSupplier
    private var sessionCache: NetworkSession?

    public var cachedSession: NetworkSession {
        get async {
            let session = sessionCache
            if let session {
                return session
            } else {
                sessionCache = await supplier()
                return sessionCache!
            }
        }
    }

    public init(_ supplier: @escaping FutureSessionSupplier) {
        self.supplier = supplier
    }

    public func callAsFunction() async -> NetworkSession {
        return await cachedSession
    }

}

internal extension FutureSession {

    static let placeholder: FutureSession = FutureSession {
        preconditionFailure("No session supplied. Use Resource.session(:) to provide a valid network session.")
    }

}

/// Executes network requests for the client app.
public actor NetworkSession {

    // MARK: - Variables

    public let configuration: NetworkSessionProviding
    public let baseUrl: BaseUrlProviding?

    // MARK: - Initialization

    /// A public initializer that sets the baseURL and configuration properties, and initializes the underlying `Session` object.
    public init(
        baseUrl: BaseUrlProviding? = nil,
        configuration: NetworkSessionProviding = DefaultSessionProvider(configuration: .default)
    ) {
        self.baseUrl = baseUrl
        self.configuration = configuration
    }

}

// MARK: - Request

public extension NetworkSession {

    /// Send request to an endpoint on a given base URL.
    /// - Parameters:
    ///   - endpoint: Endpoint instance representing the endpoint
    ///   - base: Base address to use when building the endpoint URL. Optional, if not provided, the default `baseUrl`
    ///   property will be used.
    func request<Result: Decodable & Sendable>(endpoint: Endpoint, baseUrl: BaseUrlProviding? = nil) async throws(NetworkError) -> Result {
        let resolvedBaseUrl = try await resolveBaseUrl(baseUrl: baseUrl)
        let resolvedSession = await resolveSession(sessionProvider: configuration)
        
        do {
            return try await resolvedSession.request(
                try? endpoint.url(on: resolvedBaseUrl),
                method: endpoint.method,
                parameters: endpoint.parameters?.dictionary,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .goodify(type: Result.self)
            .value
        } catch let error as AFError {
            throw .alamofire(error)
        } catch {
            throw .session
        }
    }

    func requestRaw(endpoint: Endpoint, baseUrl: String? = nil) async throws(NetworkError) -> Data {
        let resolvedBaseUrl = try await resolveBaseUrl(baseUrl: baseUrl)
        let resolvedSession = await resolveSession(sessionProvider: configuration)

        do {
            return try await resolvedSession.request(
                try? endpoint.url(on: resolvedBaseUrl),
                method: endpoint.method,
                parameters: endpoint.parameters?.dictionary,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .serializingData()
            .value
        } catch let error as AFError {
            throw .alamofire(error)
        } catch {
            throw .session
        }
    }

    @_disfavoredOverload func request(endpoint: Endpoint, base: String? = nil) async throws(NetworkError) -> DataRequest {
        let resolvedBaseUrl = try await resolveBaseUrl(baseUrl: baseUrl)
        let resolvedSession = await resolveSession(sessionProvider: configuration)

        return resolvedSession.request(
            try? endpoint.url(on: resolvedBaseUrl),
            method: endpoint.method,
            parameters: endpoint.parameters?.dictionary,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
    }

    private func resolveSession(sessionProvider: NetworkSessionProviding) async -> Alamofire.Session {
        if await sessionProvider.shouldResolveNew() {
            await sessionProvider.resolveSession()
        } else {
            await sessionProvider.cachedSession()
        }
    }

    private func resolveBaseUrl(baseUrl: BaseUrlProviding?) async throws(NetworkError) -> String {
        let baseUrlProvider = baseUrl ?? self.baseUrl
        guard let resolvedBaseUrl = await baseUrlProvider?.resolveBaseUrl() else {
            throw .session
        }
        return resolvedBaseUrl
    }

}

// MARK: - Download

public extension NetworkSession {

    /// Creates a download request for the given `endpoint`.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to make the request to.
    ///   - base: The base URL to use for the request. Defaults to nil.
    ///   - customFileName: The custom file name for the downloaded file.
    /// - Returns: A download request for the given endpoint.
    func download(endpoint: Endpoint, base: String? = nil, customFileName: String) async throws(NetworkError) -> DownloadRequest {
        let resolvedBaseUrl = try await resolveBaseUrl(baseUrl: baseUrl)
        let resolvedSession = await resolveSession(sessionProvider: configuration)

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

    /// Uploads data to endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint manager object to specify the endpoint URL and other related information.
    ///   - data: The data to be uploaded.
    ///   - fileHeader: The header to be used for the uploaded data in the form data. Defaults to "file".
    ///   - filename: The name of the file to be uploaded.
    ///   - mimeType: The MIME type of the data to be uploaded.
    /// - Returns: The upload request object.
    func uploadWithMultipart(
        endpoint: Endpoint,
        data: Data,
        fileHeader: String = "file",
        filename: String,
        mimeType: String,
        base: String? = nil
    ) async throws(NetworkError) -> UploadRequest {
        let resolvedBaseUrl = try await resolveBaseUrl(baseUrl: baseUrl)
        let resolvedSession = await resolveSession(sessionProvider: configuration)

        return resolvedSession.upload(
            multipartFormData: { formData in
                formData.append(data, withName: fileHeader, fileName: filename, mimeType: mimeType)
            },
            to: try? endpoint.url(on: resolvedBaseUrl),
            method: endpoint.method,
            headers: endpoint.headers
        )
    }

    /// Uploads multipart form data to endpoint.
    ///
    /// - Parameters:
    ///  - endpoint: The endpoint manager object to specify the endpoint URL and other related information.
    ///  - multipartFormData: The multipart form data to be uploaded.
    ///  - base: The base URL to use for the request. Defaults to nil.
    /// - Returns: The upload request object.
    /// ## Example
    /// ```swift
    /// let fileURL = URL(filePath: "path/to/file")
    /// let multipartFormData = MultipartFormData()
    /// multipartFormData.append(fileURL, withName: "file")
    ///
    /// let image = UIImage(named: "image")
    /// let imageData = image?.jpegData(compressionQuality: 0.5)
    /// multipartFormData.append(imageData!, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
    ///
    /// let request = session.uploadWithMultipart(endpoint: endpoint, multipartFormData: multipartFormData)
    /// ```
    func uploadWithMultipart(
        endpoint: Endpoint,
        multipartFormData: MultipartFormData,
        base: String? = nil
    ) async throws(NetworkError) -> UploadRequest {
        let baseUrlProvider = baseUrl ?? self.baseUrl
        guard let resolvedBaseUrl = await baseUrlProvider?.resolveBaseUrl() else {
            throw .session
        }
        let resolvedSession = await resolveSession(sessionProvider: configuration)

        return resolvedSession.upload(
            multipartFormData: multipartFormData,
            to: try? endpoint.url(on: resolvedBaseUrl),
            method: endpoint.method,
            headers: endpoint.headers
        )
    }

}

// MARK: - Error

public enum NetworkError: Error, Hashable {

    case endpoint(EndpointError)
    case alamofire(AFError)
    case paging(PagingError)
    case missingLocalData
    case missingRemoteData
    case session

    var localizedDescription: String {
        switch self {
        case .endpoint(let endpointError):
            return endpointError.localizedDescription

        case .alamofire(let aFError):
            return aFError.localizedDescription

        case .paging(let pagingError):
            return pagingError.localizedDescription

        case .missingLocalData:
            return "Missing data - Failed to map local resource to remote type"

        case .missingRemoteData:
            return "Missing data - Failed to map remote resource to local type"

        case .session:
            return "Internal session error"
        }
    }

}

public enum EndpointError: Error {

    case noSuchEndpoint
    case operationNotSupported

    var localizedDescription: String {
        switch self {
        case .noSuchEndpoint:
            return "No such endpoint"

        case .operationNotSupported:
            return "Operation not supported"
        }
    }

}

public enum PagingError: Error {

    case noMorePages
    case nonPageableList

    var localizedDescription: String {
        switch self {
        case .noMorePages:
            return "No more pages available"

        case .nonPageableList:
            return "List is not pageable or paging is not declared"
        }
    }

}
