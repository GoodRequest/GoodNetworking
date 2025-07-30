//
//  GRSession.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

import Foundation

// MARK: - Authenticator

public enum RetryResult {

    case doNotRetry
    case retryAfter(TimeInterval)
    case retry

}

public protocol RefreshableCredential {

    var requiresRefresh: Bool { get }

}

public protocol Authenticator: Sendable {

    associatedtype Credential

    func getCredential() async -> Credential?
    func storeCredential(_ newCredential: Credential?) async

    func apply(credential: Credential, to request: inout URLRequest) async throws(NetworkError)
    func refresh(credential: Credential) async throws(NetworkError) -> Credential
    func didRequest(_ request: inout URLRequest, failDueToAuthenticationError: HTTPError) -> Bool
    func isRequest(_ request: inout URLRequest, authenticatedWith credential: Credential) -> Bool
    func refresh(didFailDueToError error: HTTPError) async

}

public final class AuthenticationInterceptor<AuthenticatorType: Authenticator>: Interceptor, @unchecked Sendable {

    private let authenticator: AuthenticatorType
    private let lock: AsyncLock

    public init(authenticator: AuthenticatorType) {
        self.authenticator = authenticator
        self.lock = AsyncLock()
    }

    public func adapt(urlRequest: inout URLRequest) async throws(NetworkError) {
        await lock.lock()
        if let credential = await authenticator.getCredential() {
            try await authenticator.apply(credential: credential, to: &urlRequest)
        }
        lock.unlock()
    }

    public func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult {
        // Request failed due to HTTP Error and not due to connection failure
        guard case .remote(let hTTPError) = error else {
            return .doNotRetry
        }

        // Remote failure occured due to authentication error
        guard authenticator.didRequest(&urlRequest, failDueToAuthenticationError: hTTPError) else {
            return .doNotRetry
        }
        
        // Stop further authentication with possibly invalid credential.
        // If a refresh is already in progress, stopping other requests
        // here will ensure further retries will contain the latest credentials.
        await lock.lock()
        defer { lock.unlock() }

        // A credential is available
        guard let credential = await authenticator.getCredential() else {
            return .doNotRetry
        }
        
        // Check if request is authenticated with the latest available credential
        // Retry if request was sent with invalid credential (previously expired, etc.)
        guard authenticator.isRequest(&urlRequest, authenticatedWith: credential) else {
            return .retry
        }

        // Refresh and store new token
        try await refresh(credential: credential)

        // Retry previous request by applying new authentication credential
        return .retry
    }

    private func refresh(credential: AuthenticatorType.Credential) async throws(NetworkError) {
        // Current credential must be expired at this point
        // and is safe to clear
        await authenticator.storeCredential(nil)

        // Refresh the expired credential and store new credential
        // Let user handle remote errors (eg. HTTP 403) before throwing
        // (eg. kick user from session, or automatically log out).
        do {
            let newCredential = try await authenticator.refresh(credential: credential)
            await authenticator.storeCredential(newCredential)
        } catch let error {
            if case .remote(let httpError) = error {
                await authenticator.refresh(didFailDueToError: httpError)
            }
            throw error
        }
    }

}

public final class NoAuthenticator: Authenticator {

    public typealias Credential = Void

    public init() {}
    public func getCredential() async -> Credential? { nil }
    public func storeCredential(_ newCredential: Credential?) async {}
    public func apply(credential: Credential, to request: inout URLRequest) async throws(NetworkError) {}
    public func refresh(credential: Credential) async throws(NetworkError) -> Credential {}
    public func didRequest(_ request: inout URLRequest, failDueToAuthenticationError: HTTPError) -> Bool { false }
    public func isRequest(_ request: inout URLRequest, authenticatedWith credential: Credential) -> Bool { false }
    public func refresh(didFailDueToError error: HTTPError) async {}

}

// MARK: - Interception

public protocol Adapter: Sendable {

    func adapt(urlRequest: inout URLRequest) async throws(NetworkError)

}

public protocol Retrier: Sendable {

    func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult

}

public protocol Interceptor: Adapter, Retrier {}

public final class NoInterceptor: Interceptor {

    public init() {}

    public func adapt(urlRequest: inout URLRequest) async throws(NetworkError) {}

    public func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult {
        return .doNotRetry
    }

}

public final class CompositeInterceptor: Interceptor {

    private let interceptors: [Interceptor]

    public init(interceptors: [Interceptor]) {
        self.interceptors = interceptors
    }

    public func adapt(urlRequest: inout URLRequest) async throws(NetworkError) {
        for adapter in interceptors {
            try await adapter.adapt(urlRequest: &urlRequest)
        }
    }

    public func retry(urlRequest: inout URLRequest, for session: NetworkSession, dueTo error: NetworkError) async throws(NetworkError) -> RetryResult {
        for retrier in interceptors {
            let retryResult = try await retrier.retry(urlRequest: &urlRequest, for: session, dueTo: error)
            switch retryResult {
            case .doNotRetry:
                continue
            case .retry, .retryAfter:
                return retryResult
            }
        }
        return .doNotRetry
    }

}

// MARK: - Initialization

@NetworkActor public final class NetworkSession: NSObject, Sendable {

    private let baseUrl: any URLConvertible
    private let sessionHeaders: HTTPHeaders
    private let interceptor: any Interceptor
    private let logger: any NetworkLogger

    private let configuration: URLSessionConfiguration
    private let delegateQueue: OperationQueue
    private lazy var session: URLSession = {
        URLSession(
            configuration: configuration,
            delegate: NetworkSessionDelegate(for: self),
            delegateQueue: delegateQueue
        )
    }()

    /// Holds references to `DataTaskProxy` objects based on
    /// DataTask `taskIdentifier`-s.
    private var taskProxyMap: [Int: DataTaskProxy] = [:]

    nonisolated public init(
        baseUrl: any URLConvertible,
        baseHeaders: HTTPHeaders = [],
        interceptor: any Interceptor = NoInterceptor(),
        logger: any NetworkLogger = PrintNetworkLogger()
    ) {
        self.baseUrl = baseUrl
        self.sessionHeaders = baseHeaders
        self.interceptor = interceptor
        self.logger = logger

        let operationQueue = OperationQueue()
        operationQueue.name = "NetworkActorSerialExecutorOperationQueue"
        operationQueue.underlyingQueue = NetworkActor.queue

        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = baseHeaders.map { $0.resolveHeader() }.reduce(into: [:], { $0[$1.name] = $1.value })

        self.configuration = configuration
        self.delegateQueue = operationQueue

        // create URLSession lazily, isolated on @NetworkActor, when requested first time

        super.init()
    }

}

internal extension NetworkSession {

    func proxyForTask(_ task: URLSessionTask) -> DataTaskProxy {
        if let existingProxy = self.taskProxyMap[task.taskIdentifier] {
            return existingProxy
        } else {
            let newProxy = DataTaskProxy(task: task, logger: logger)
            self.taskProxyMap[task.taskIdentifier] = newProxy
            return newProxy
        }
    }

}

// MARK: - Network session delegate

final class NetworkSessionDelegate: NSObject {

    private unowned let networkSession: NetworkSession

    internal init(for networkSession: NetworkSession) {
        self.networkSession = networkSession
    }

}

extension NetworkSessionDelegate: URLSessionDelegate {

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
#warning("TODO: Implement SSL pinning/certificate validation")
        completionHandler(.performDefaultHandling, nil)
    }

}

extension NetworkSessionDelegate: URLSessionTaskDelegate {

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        NetworkActor.assumeIsolated {
            networkSession
                .proxyForTask(task)
                .dataTaskDidComplete(withError: error)
        }
    }

}

extension NetworkSessionDelegate: URLSessionDataDelegate {

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        return .allow
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        NetworkActor.assumeIsolated {
            networkSession
                .proxyForTask(dataTask)
                .dataTaskDidReceive(data: data)
        }
    }

}

// MARK: - Request

extension NetworkSession {
    
    // MARK: Result
    
    public func requestResult<T: Decodable, F: Error>(
        endpoint: Endpoint,
        validationProvider: any ValidationProviding<F> = DefaultValidationProvider()
    ) async -> Result<T, F> {
        do {
            let response: T = try await request(endpoint: endpoint, validationProvider: validationProvider)
            return .success(response)
        } catch let error {
            return .failure(error)
        }
    }
    
    // MARK: Codable

    public func request<T: Decodable, F: Error>(
        endpoint: Endpoint,
        validationProvider: any ValidationProviding<F> = DefaultValidationProvider()
    ) async throws(F) -> T {
        do {
            return try await request(endpoint: endpoint)
        } catch let error {
            throw validationProvider.transformError(error)
        }
    }

    public func request<T: Decodable>(endpoint: Endpoint) async throws(NetworkError) -> T {
        let data = try await request(endpoint: endpoint) as Data

        // handle decoding corner cases
        var decoder = JSONDecoder()
        switch T.self {
        case is Data.Type:
            return data as! T
            
        case let t as WithCustomDecoder:
            decoder = type(of: t).decoder
            
        default:
            break
        }

        // decode
        do {
            let model = try decoder.decode(T.self, from: data)
            return model
        } catch let error as DecodingError {
            throw error.asNetworkError()
        } catch {
            throw URLError(.cannotDecodeRawData).asNetworkError()
        }
    }
    
    // MARK: JSON
    
    @_disfavoredOverload
    public func request(endpoint: Endpoint) async throws(NetworkError) -> JSON {
        let responseData = try await request(endpoint: endpoint) as Data
        guard let json = try? JSON(data: responseData) else {
            throw URLError(.cannotDecodeRawData).asNetworkError()
        }
        return json
    }
    
    // MARK: Raw
    
    @discardableResult
    public func request(endpoint: Endpoint) async throws(NetworkError) -> Data {
        guard let basePath = await baseUrl.resolveUrl()?.absoluteString,
              let url = await endpoint.url(on: basePath)
        else {
            throw URLError(.badURL).asNetworkError()
        }

        // url + method
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // headers
        endpoint.headers?.forEach { header in
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        
        // encoding
        switch endpoint.parameters {
        case .parameters(let parameters):
            if endpoint.encoding is URLEncoding {
                applyQueryParameters(to: &request, endpoint, url)
            } else if endpoint.encoding is JSONEncoding {
                logger.logNetworkEvent(
                    message: "Attempt to encode dictionary as body, use JSON or Encodable instead",
                    level: .error,
                    file: #file,
                    line: #line
                )
                request.httpBody = try endpoint.parameters?.data()
            } else if endpoint.encoding is AutomaticEncoding {
                request.httpBody = try endpoint.parameters?.data()
            }
            
        case .query(let queryItems):
            if endpoint.encoding is URLEncoding {
                applyQueryParameters(to: &request, endpoint, url)
            } else if endpoint.encoding is JSONEncoding {
                preconditionFailure("Attempt to encode query parameters as JSON body")
            } else if endpoint.encoding is AutomaticEncoding {
                applyQueryParameters(to: &request, endpoint, url)
            }
            
        case .model(let encodableModel):
            if endpoint.encoding is URLEncoding {
                applyQueryParameters(to: &request, endpoint, url)
            } else if endpoint.encoding is JSONEncoding {
                request.httpBody = try endpoint.parameters?.data()
            } else if endpoint.encoding is AutomaticEncoding {
                request.httpBody = try endpoint.parameters?.data()
            }
            
        case .data(let data):
            if endpoint.encoding is URLEncoding {
                preconditionFailure("Encoding raw data into query is not supported")
            } else if endpoint.encoding is JSONEncoding {
                request.httpBody = try endpoint.parameters?.data()
            } else if endpoint.encoding is AutomaticEncoding {
                request.httpBody = try endpoint.parameters?.data()
            }
            
        case .json(let json):
            if endpoint.encoding is URLEncoding {
                applyQueryParameters(to: &request, endpoint, url)
            } else if endpoint.encoding is JSONEncoding {
                request.httpBody = try endpoint.parameters?.data()
            } else if endpoint.encoding is AutomaticEncoding {
                request.httpBody = try endpoint.parameters?.data()
            }
            
        case .none:
            request.httpBody = nil
        }

        return try await executeRequest(request: &request)
    }

}

// MARK: - Private

private extension NetworkSession {

    func executeRequest(request: inout URLRequest) async throws(NetworkError) -> Data {
        // Content type
        let httpMethodSupportsBody = request.method.hasRequestBody
        let httpMethodHasBody = (request.httpBody != nil)

        if httpMethodSupportsBody && httpMethodHasBody { // assume we are always encoding data as JSON
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else if httpMethodSupportsBody && !httpMethodHasBody { // supports body, but has parameters in query
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        } else if !httpMethodSupportsBody {
            // do not set Content-Type
        } else {
            logger.logNetworkEvent(
                message: "Cannot resolve Content-Type automatically",
                level: .warning,
                file: #file,
                line: #line
            )
        }

        // Session headers
        sessionHeaders.forEach { header in
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }

        // Interceptors
        try await interceptor.adapt(urlRequest: &request)

        // Data task
        let dataTask = session.dataTask(with: request)
        let dataTaskProxy = proxyForTask(dataTask)
        dataTask.resume()

        // Request data + validation + retry (?)
        do {
            let data = try await dataTaskProxy.data()
            let validator = DefaultValidationProvider()
            let statusCode = (dataTask.response as? HTTPURLResponse)?.statusCode ?? -1
            try validator.validate(statusCode: statusCode, data: data)
            return data
        } catch let networkError {
            return try await retryRequest(request: &request, error: networkError)
        }
    }

    func retryRequest(request: inout URLRequest, error networkError: NetworkError) async throws(NetworkError) -> Data {
        let retryResult = try await interceptor.retry(urlRequest: &request, for: self, dueTo: networkError)

        switch retryResult {
        case .doNotRetry:
            throw networkError

        case .retryAfter(let timeInterval):
            do {
                try await Task.sleep(nanoseconds: UInt64(timeInterval * 10e9))
            } catch {
                throw URLError(.cancelled).asNetworkError()
            }
            fallthrough

        case .retry:
            return try await self.executeRequest(request: &request)
        }
    }
    
    @available(*, deprecated, message: "Unify parameter handling")
    private func applyQueryParameters(to request: inout URLRequest, _ endpoint: any Endpoint, _ url: URL) {
        if #available(iOS 16, *) {
            request.url?.append(queryItems: endpoint.parameters?.queryItems() ?? [])
        } else {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems?.append(contentsOf: endpoint.parameters?.queryItems() ?? [])
            request.url = urlComponents?.url
        }
    }

}

// MARK: - Custom URLErrors

extension URLError.Code {

    public static var cannotEncodeRawData: URLError.Code {
        URLError.Code(rawValue: 7777)
    }

}

// MARK: - DataTaskProxy

@NetworkActor internal final class DataTaskProxy {

    private(set) var task: URLSessionTask
    private let logger: any NetworkLogger

    internal var receivedData: Data = Data()
    internal var receivedError: (URLError)? = nil

    private var isFinished = false
    private var continuation: CheckedContinuation<Void, Never>? = nil

    internal func data() async throws(NetworkError) -> Data {
        if !isFinished { await waitForCompletion() }
        if let receivedError { throw receivedError.asNetworkError() }
        return receivedData
    }

    internal func result() async -> Result<Data, NetworkError> {
        if !isFinished { await waitForCompletion() }
        if let receivedError {
            return .failure(receivedError.asNetworkError())
        } else {
            return .success(receivedData)
        }
    }

    internal init(task: URLSessionTask, logger: any NetworkLogger) {
        self.task = task
        self.logger = logger
    }

    internal func dataTaskDidReceive(data: Data) {
        assert(isFinished == false, "ILLEGAL ATTEMPT TO APPEND DATA TO FINISHED PROXY INSTANCE")
        receivedData.append(data)
    }

    internal func dataTaskDidComplete(withError error: (any Error)?) {
        assert(isFinished == false, "ILLEGAL ATTEMPT TO RESUME FINISHED CONTINUATION")
        self.isFinished = true

        if let error = error as? URLError {
            self.receivedError = error
        } else if error != nil {
            assertionFailure("URLSessionTaskDelegate did not throw expected type URLError")
            self.receivedError = URLError(.unknown)
        }

        Task { @NetworkActor in
            logger.logNetworkEvent(
                message: prepareRequestInfo(),
                level: receivedError == nil ? .debug : .warning,
                file: #file,
                line: #line
            )
        }

        continuation?.resume()
        continuation = nil
    }

    internal func waitForCompletion() async {
        assert(self.continuation == nil, "CALLING RESULT/DATA CONCURRENTLY WILL LEAK RESOURCES")
        assert(isFinished == false, "FINISHED PROXY CANNOT RESUME CONTINUATION")
        await withCheckedContinuation { self.continuation = $0 }
    }

}

// MARK: - Extensions

public extension URLRequest {

    var method: HTTPMethod {
        HTTPMethod(rawValue: self.httpMethod ?? "GET") ?? .get
    }

}

// MARK: - Sample

#warning("vyhodit sample pred releasom")
func x() async {
    let session = NetworkSession(
        baseUrl: "https://api.sampleapis.com/",
        baseHeaders: [HTTPHeader("User-Agent: iOS app")],
        interceptor: CompositeInterceptor(interceptors: [
            AuthenticationInterceptor(authenticator: NoAuthenticator())
        ])
    )

    do {



        let coffeeListA: String = try await session.request(endpoint: CoffeeEndpoint.hot)
        let coffeeListB: Data = try await session.get("/cards/list")
        
        
        let answers = Data()
        let data: Data = try await session.post("/coffee/survey/new")
        
        try await session.delete("/coffee/3")
        
        
//        try await session.request(
//            endpoint: at("/coffee/4")
//                .method(.get)
//                .header("Content-Type: application/xml")
//        )
    


    } catch let error {
        assert(error is NetworkError)
    }

}

enum CoffeeEndpoint: Endpoint {

    case hot

    var method: HTTPMethod { .get }
    var path: URLConvertible { "/coffee/hot" }
    var headers: HTTPHeaders? { nil }
    var parameters: EndpointParameters? { nil }

}


enum Endpoints {
    static let hotCoffee = "/coffee/hot"
}
