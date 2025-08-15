//
//  DataTaskProxy.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 07/08/2025.
//

import Foundation

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

        logger.logNetworkEvent(
            message: prepareRequestInfo(),
            level: receivedError == nil ? .debug : .warning,
            file: #file,
            line: #line
        )

        continuation?.resume()
        continuation = nil
    }

    internal func waitForCompletion() async {
        assert(self.continuation == nil, "CALLING RESULT/DATA CONCURRENTLY WILL LEAK RESOURCES")
        assert(isFinished == false, "FINISHED PROXY CANNOT RESUME CONTINUATION")
        await withCheckedContinuation { self.continuation = $0 }
    }

}
