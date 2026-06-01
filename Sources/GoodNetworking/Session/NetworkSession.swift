//
//  GRSession.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

import Foundation

// MARK: - Initialization

/// Main network session
///
/// Session description
///
/// - Base URL: resolved once per request
/// - Session headers: resolved once per session
/// - Request headers: resolved once per request
/// - Interceptor: intercepts every request (adapts, decides if/when to retry)
/// - Are retried requests intercepted again?
/// - Describe in more detail how interceptors work
/// - BaseURL provider pattern
/// - Name is used for identification only, not used by the network session itself
@NetworkActor public final class NetworkSession: NSObject {
    
    nonisolated public let name: String

    private let baseUrl: any URLConvertible
    private let sessionHeaders: HTTPHeaders
    private let interceptor: any Interceptor
    private let logger: any NetworkLogger
    private let certificate: any Certificate

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
    private var activeTasks: [Int: DataTaskProxy] = [:]

    nonisolated public init(
        baseUrl: any URLConvertible,
        baseHeaders: HTTPHeaders = [],
        interceptor: any Interceptor = DefaultInterceptor(),
        logger: any NetworkLogger = PrintNetworkLogger(),
        certificate: any Certificate = NoPinnedCertificate(),
        name: String? = nil
    ) {
        self.name = name ?? "NetworkSession"
        
        self.baseUrl = baseUrl
        self.sessionHeaders = baseHeaders
        self.interceptor = interceptor
        self.logger = logger
        self.certificate = certificate

        let operationQueue = OperationQueue()
        operationQueue.name = "NetworkActorSerialExecutorOperationQueue"
        operationQueue.underlyingQueue = NetworkActor.queue

        let configuration = URLSessionConfiguration.ephemeral
        
        self.configuration = configuration
        self.delegateQueue = operationQueue

        // create URLSession lazily, isolated to @NetworkActor, when requested first time

        super.init()
    }

}

internal extension NetworkSession {

    func proxyForTask(_ task: URLSessionTask) -> DataTaskProxy {
        if let existingProxy = self.activeTasks[task.taskIdentifier] {
            return existingProxy
        } else {
            let newProxy = DataTaskProxy(task: task, logger: logger)
            self.activeTasks[task.taskIdentifier] = newProxy
            return newProxy
        }
    }
    
    func closeProxyForTask(_ task: URLSessionTask) {
        self.activeTasks.removeValue(forKey: task.taskIdentifier)
    }

    func getPinnedCertificate() -> any Certificate {
        self.certificate
    }

    func getLogger() -> any NetworkLogger {
        self.logger
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

    /// SSL Pinning: Compare server certificate with local (pinned) certificate
    /// https://developer.apple.com/documentation/foundation/performing-manual-server-trust-authentication
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        /// Mark completionHandler as isolated to ``NetworkActor``.
        ///
        /// This delegate function is always called on NetworkActor's operation queue, but is marked as `nonisolated`. Completion handler
        /// would usually be called on the same thread.
        ///
        /// NetworkSessionDelegate cannot conform to `URLSessionDelegate` on `@NetworkActor` because of erroneous
        /// `Sendable Self` requirement preventing marking the conformance .
        typealias YesActor = @NetworkActor (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        typealias NoActor = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        let completionHandler = unsafeBitCast(completionHandler as NoActor, to: YesActor.self)

        Task { @NetworkActor in
            // Evaluate only SSL/TLS certificates
            guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            // Load and validate local certificate
            let error: (any Error)?
            let certificateDisposition: CertificateDisposition?
            do {
                certificateDisposition = try await networkSession.getPinnedCertificate()
                    .certificateDisposition(using: serverTrust)
                error = nil
            } catch let certificateError {
                certificateDisposition = nil
                error = certificateError
            }

            switch certificateDisposition {
            case .evaluate(let certificates):
                // Set local certificate as serverTrust anchor
                SecTrustSetAnchorCertificates(serverTrust, certificates as CFArray)
                SecTrustSetAnchorCertificatesOnly(serverTrust, true)

                // Evaluate certificate chain manually
                var error: CFError?
                let trusted = SecTrustEvaluateWithError(serverTrust, &error)
                if trusted {
                    let credential = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, credential)
                } else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                }

            case .useSystemTrustEvaluation:
                completionHandler(.performDefaultHandling, nil)

            case .deny(let reason):
                networkSession.getLogger().logNetworkEvent(
                    message: reason ?? "Denied for unspecified reasons",
                    level: .error,
                    file: #file,
                    line: #line
                )

                completionHandler(.cancelAuthenticationChallenge, nil)

            // call throws
            case .none:
                networkSession.getLogger().logNetworkEvent(
                    message: error?.localizedDescription ?? "nil",
                    level: .error,
                    file: #file,
                    line: #line
                )

                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
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
        let response: NetworkResponse = try await request(endpoint: endpoint)
        let data = response.body

        // handle decoding corner cases
        var decoder = JSONDecoder()
        switch T.self {
        case is Data.Type, is Optional<Data>.Type:
            return data as! T
            
        case let t as WithCustomDecoder.Type:
            decoder = t.decoder
            
        default:
            break
        }

        // decode
        do {
            let model = try decoder.decode(T.self, from: data)
            return model
        } catch let error as DecodingError {
            logger.logNetworkEvent(
                message: error.prettyPrinted,
                level: .error,
                file: #file,
                line: #line
            )
            throw error.asNetworkError()
        } catch {
            throw URLError(.cannotDecodeRawData).asNetworkError()
        }
    }
    
    // MARK: JSON

    @available(*, deprecated, message: "JSON conforms to Codable; use generic interfaces instead")
    @_disfavoredOverload
    public func request(endpoint: Endpoint) async throws(NetworkError) -> JSON {
        try await request(endpoint: endpoint) as JSON
    }
    
    // MARK: Raw
    
    @discardableResult
    public func request(endpoint: Endpoint) async throws(NetworkError) -> NetworkResponse {
        let endpointPath = await endpoint.path.resolveUrl()
        let url: URL

        // If endpoint already contains an absolute path, do not concatenate
        // with baseURL and use that instead
        if let endpointPath, endpointPath.isAbsolute {
            url = endpointPath
        } else {
            // If endpoint has only relative path, resolve it over baseURL
            let baseUrl = await baseUrl.resolveUrl()
            let endpointResolvedUrl = await endpoint.url(on: baseUrl)

            // If neither endpoint nor baseURL are specified, URL cannot be resolved
            guard let endpointResolvedUrl else {
                throw URLError(.badURL).asNetworkError()
            }

            // URL is resolved
            url = endpointResolvedUrl
        }

        // url + method
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // headers
        endpoint.headers?.resolve().forEach { header in
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }
        
        // encoding parameters
        try applyParameters(to: &request, endpoint, url)

        return try await executeRequest(request: &request)
    }

}

// MARK: - Private

private extension NetworkSession {

    func executeRequest(request: inout URLRequest) async throws(NetworkError) -> NetworkResponse {
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
        sessionHeaders.resolve().forEach { header in
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
            closeProxyForTask(dataTask)

            let validator = DefaultValidationProvider()
            let response = dataTask.response
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            
            try validator.validate(statusCode: statusCode, data: data)
            return NetworkResponse(data: data, response: response)
        } catch let networkError {
            return try await retryRequest(request: &request, error: networkError)
        }
    }

    func retryRequest(request: inout URLRequest, error networkError: NetworkError) async throws(NetworkError) -> NetworkResponse {
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

    private func applyParameters(
        to request: inout URLRequest,
        _ endpoint: any Endpoint,
        _ url: URL,
    ) throws(NetworkError) {
        if case .none = endpoint.parameters {
            request.httpBody = nil
            return
        }
        if endpoint.encoding is URLEncoding {
            if case .data = endpoint.parameters {
                let message = "Encoding raw data into query is not supported"
                logger.logNetworkEvent(message: message, level: .error, file: #file, line: #line)
                throw NetworkError.local(URLError(.cannotEncodeRawData))
            }
            applyQueryParameters(to: &request, endpoint, url)
        } else if endpoint.encoding is JSONEncoding {
            if case .query = endpoint.parameters {
                let message = "Attempt to encode query parameters as JSON body"
                logger.logNetworkEvent(message: message, level: .error, file: #file, line: #line)
                throw NetworkError.local(URLError(.cannotEncodeRawData))
            }
            if endpoint.method.hasRequestBody {
                try applyBodyParameters(to: &request, endpoint, url)
            } else {
                let message = "Attempted to encode body for request that does not allow a request body"
                logger.logNetworkEvent(message: message, level: .error, file: #file, line: #line)
                throw NetworkError.local(URLError(.cannotEncodeRawData))
            }
        } else { // AutomaticEncoding or not specified
            if endpoint.method.hasRequestBody { // Apply request body if available
                try applyBodyParameters(to: &request, endpoint, url)
            } else { // else apply as query
                applyQueryParameters(to: &request, endpoint, url)
            }
        }
    }

    private func applyBodyParameters(to request: inout URLRequest, _ endpoint: any Endpoint, _ url: URL) throws(NetworkError) {
        request.httpBody = try endpoint.parameters?.data()
    }

    private func applyQueryParameters(to request: inout URLRequest, _ endpoint: any Endpoint, _ url: URL) {
        if #available(iOS 16, macOS 13, *) {
            request.url?.append(queryItems: endpoint.parameters?.queryItems() ?? [])
        } else {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems?.append(contentsOf: endpoint.parameters?.queryItems() ?? [])
            request.url = urlComponents?.url
        }
    }

}

// MARK: - Sample

// The following code is a sample for testing the syntax.
//private func sample() async {
//    let session = NetworkSession(
//        baseUrl: "https://api.sampleapis.com/",
//        baseHeaders: [HTTPHeader("User-Agent: iOS app")],
//        interceptor: CompositeInterceptor(interceptors: [
//            AuthenticationInterceptor(authenticator: NoAuthenticator())
//        ])
//    )
//
//    do {
//        let coffeeListA: String = try await session.request(endpoint: CoffeeEndpoint.hot)
//        let coffeeListB: Data = try await session.get("/cards/list")
//        
//        
//        let answers = Data()
//        let data: Data = try await session.post("/coffee/survey/new")
//        
//        try await session.delete("/coffee/3")
//        
//        try await session.request(
//            endpoint: at("/coffee/4")
//                .method(.get)
//                .header("Content-Type: application/xml")
//                .body(data: answers)
//        )
//    } catch let error {
//        assert(error is NetworkError)
//    }
//}
//
//enum CoffeeEndpoint: Endpoint {
//
//    case hot
//
//    var method: HTTPMethod { .get }
//    var path: URLConvertible { "/coffee/hot" }
//    var headers: HTTPHeaders? { nil }
//    var parameters: EndpointParameters? { nil }
//
//}
//
//
//enum Endpoints {
//    static let hotCoffee = "/coffee/hot"
//}
