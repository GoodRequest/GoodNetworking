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
        name: String? = nil
    ) {
        self.name = name ?? "NetworkSession"
        
        self.baseUrl = baseUrl
        self.sessionHeaders = baseHeaders
        self.interceptor = interceptor
        self.logger = logger

        let operationQueue = OperationQueue()
        operationQueue.name = "NetworkActorSerialExecutorOperationQueue"
        operationQueue.underlyingQueue = NetworkActor.queue

        let configuration = URLSessionConfiguration.ephemeral
        
        self.configuration = configuration
        self.delegateQueue = operationQueue

        // create URLSession lazily, isolated on @NetworkActor, when requested first time

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
//        // SSL Pinning: Compare server certificate with local (pinned) certificate
//        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
//              let serverTrust = challenge.protectionSpace.serverTrust,
//              let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0),
//              let pinnedCertificateData = Self.pinnedCertificateData()
//        else {
//            completionHandler(.cancelAuthenticationChallenge, nil)
//            return
//        }
//
//        // Extract server certificate data
//        let serverCertificateData = SecCertificateCopyData(serverCertificate) as Data
//
//        if serverCertificateData == pinnedCertificateData {
//            let credential = URLCredential(trust: serverTrust)
//            completionHandler(.useCredential, credential)
//        } else {
//            completionHandler(.cancelAuthenticationChallenge, nil)
//        }
        
        #warning("TODO: Enable SSL pinning")
        // https://developer.apple.com/documentation/foundation/performing-manual-server-trust-authentication
        
        // remove
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
        case is Data.Type, is Optional<Data>.Type:
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
        let endpointPath = await endpoint.path.resolveUrl()
        let baseUrl = await baseUrl.resolveUrl()
        let url: URL
        
        // Check if endpointPath is absolute
        let endpointHasScheme: Bool = if let endpointPath,
                                         let endpointPathScheme = endpointPath.scheme,
                                         !endpointPathScheme.isEmpty { true } else { false }
        
        let endpointHasHost: Bool = if let endpointPath,
                                       let endpointPathHost = endpointPath.host,
                                       !endpointPathHost.isEmpty { true } else { false }
        
        // Check if baseUrl is resolvable
        let baseUrlHasScheme: Bool = if let baseUrl,
                                        let baseUrlScheme = baseUrl.scheme,
                                        !baseUrlScheme.isEmpty { true } else { false }
        
        let baseUrlHasHost: Bool = if let baseUrl,
                                      let baseUrlHost = baseUrl.host,
                                      !baseUrlHost.isEmpty { true } else { false }
        
        let endpointIsAbsolutePath = endpointHasScheme && endpointHasHost
        if endpointIsAbsolutePath, let endpointPath {
            url = endpointPath
        } else {
            let endpointResolvedUrl = await endpoint.url(on: baseUrl)
            if let endpointResolvedUrl {
                url = endpointResolvedUrl
            } else {
                throw URLError(.badURL).asNetworkError()
            }
        }

        // url + method
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // headers
        endpoint.headers?.resolve().forEach { header in
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
