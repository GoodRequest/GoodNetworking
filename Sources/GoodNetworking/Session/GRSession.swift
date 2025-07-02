//
//  GRSession.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

import Foundation

// MARK: - Interception

public protocol Interceptor: Sendable {

    func intercept(urlRequest: inout URLRequest)

}

public final class NoInterceptor: Interceptor {

    public init() {}
    public func intercept(urlRequest: inout URLRequest) {}

}

public final class CompositeInterceptor: Interceptor {

    private let interceptors: [Interceptor]

    public init(interceptors: [Interceptor]) {
        self.interceptors = interceptors
    }

    public func intercept(urlRequest: inout URLRequest) {
        for interceptor in interceptors {
            interceptor.intercept(urlRequest: &urlRequest)
        }
    }

}

// MARK: - Initialization

@NetworkActor public final class NetworkSession: NSObject, Sendable {

    private let baseUrl: any URLConvertible
    private let baseHeaders: HTTPHeaders
    private let interceptor: any Interceptor

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
        self.baseHeaders = baseHeaders
        self.interceptor = interceptor

        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = NetworkActor.queue

        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = baseHeaders.map { $0.resolveHeader() }.reduce(into: [:], { $0[$1.name] = $1.value })

        self.configuration = configuration
        self.delegateQueue = operationQueue

        // create URLSession lazily, isolated on @NetworkActor, when required first time

        super.init()
    }

}

internal extension NetworkSession {

    func proxyForTask(_ task: URLSessionTask) -> DataTaskProxy {
        if let existingProxy = self.taskProxyMap[task.taskIdentifier] {
            return existingProxy
        } else {
            let newProxy = DataTaskProxy(task: task)
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

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        NetworkActor.assumeIsolated {
            print(Thread.current.name)
        }
    }

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

    public func request<F: Error>(
        endpoint: Endpoint,
        validationProvider: any ValidationProviding<F> = DefaultValidationProvider()
    ) async throws(F) {
        _ = try await request(endpoint: endpoint, validationProvider: validationProvider)
    }

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
        let data = try await request(endpoint: endpoint)

        // exist-fast if decoding is not needed
        if T.self is Data.Type {
            return data as! T
        }

        do {
            let model = try JSONDecoder().decode(T.self, from: data)
            return model
        } catch {
            throw URLError(.cannotDecodeRawData).asNetworkError()
        }
    }

    public func request(endpoint: Endpoint) async throws(NetworkError) -> Data {
        guard let url = await URL(string: endpoint.path, relativeTo: baseUrl.resolveUrl()) else {
            throw URLError(.badURL).asNetworkError()
        }

        // url + method
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // encoding
        if endpoint.encoding is URLEncoding {
            if #available(iOS 16, *) {
                request.url?.append(queryItems: endpoint.parameters?.queryItems() ?? [])
            } else {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                urlComponents?.queryItems?.append(contentsOf: endpoint.parameters?.queryItems() ?? [])
                request.url = urlComponents?.url
            }
        } else if endpoint.encoding is JSONEncoding {
            request.httpBody = endpoint.parameters?.data()
        } else {
            throw URLError(.cannotEncodeRawData).asNetworkError()
        }

        interceptor.intercept(urlRequest: &request)

        let dataTask = session.dataTask(with: request)
        let dataTaskProxy = proxyForTask(dataTask)
        return try await dataTaskProxy.data()
    }

}

// MARK: - Shorthand requests

extension NetworkSession {

    public func get(_ path: URLConvertible) async throws(NetworkError) -> Data {
        guard let url = await path.resolveUrl() else {
            throw URLError(.badURL).asNetworkError()
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.httpBody = nil

        interceptor.intercept(urlRequest: &request)

        let dataTask = session.dataTask(with: request)
        let dataTaskProxy = proxyForTask(dataTask)
        return try await dataTaskProxy.data()
    }

}

// MARK: - Custom URLErrors

extension URLError.Code {

    public static var cannotEncodeRawData: URLError.Code {
        URLError.Code(rawValue: 7777)
    }

}

// MARK: - DataTaskProxy

@NetworkActor final class DataTaskProxy {

    private(set) var task: URLSessionTask

    private var receivedData: Data = Data()
    private var receivedError: (URLError)? = nil
    private var isFinished = false
    private var continuation: CheckedContinuation<Void, Never>? = nil

    func data() async throws(NetworkError) -> Data {
        if !isFinished { await waitForCompletion() }
        if let receivedError { throw receivedError.asNetworkError() }
        return receivedData
    }

    func result() async -> Result<Data, NetworkError> {
        if !isFinished { await waitForCompletion() }
        if let receivedError {
            return .failure(receivedError.asNetworkError())
        } else {
            return .success(receivedData)
        }
    }

    init(task: URLSessionTask) {
        self.task = task
    }

    func dataTaskDidReceive(data: Data) {
        assert(isFinished == false, "ILLEGAL ATTEMPT TO APPEND DATA TO FINISHED PROXY INSTANCE")
        receivedData.append(data)
    }

    func dataTaskDidComplete(withError error: (any Error)?) {
        assert(isFinished == false, "ILLEGAL ATTEMPT TO RESUME FINISHED CONTINUATION")
        self.isFinished = true

        if let error = error as? URLError {
            self.receivedError = error
        } else {
            fatalError("URLSessionTaskDelegate does not throw URLErrors")
        }

        continuation?.resume()
        continuation = nil
    }

    func waitForCompletion() async {
        assert(self.continuation == nil, "CALLING RESULT/DATA CONCURRENTLY WILL LEAK RESOURCES")
        assert(isFinished == false, "FINISHED PROXY CANNOT RESUME CONTINUATION")
        try await withCheckedContinuation { self.continuation = $0 }
    }

}

// MARK: - Sample

func x() async {
    let session = NetworkSession(
        baseUrl: "https://api.sampleapis.com/",
        baseHeaders: [HTTPHeader("User-Agent: iOS app")]
    )

    do {
        try await session.request(endpoint: CoffeeEndpoint.hot) as String
        try await session.get("/coffee/hot")
    } catch let error {
        assert(error is URLError)
    }

}

enum CoffeeEndpoint: Endpoint {

    case hot

    var method: HTTPMethod { .get }
    var path: String { "/coffee/hot" }

}


enum Endpoints {
    static let hotCoffee = "/coffee/hot"
}
