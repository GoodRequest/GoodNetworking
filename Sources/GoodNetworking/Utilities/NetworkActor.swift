//
//  NetworkActor.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

import Foundation

// MARK: - Actor

@globalActor public actor NetworkActor {

    public static let shared: NetworkActor = NetworkActor()
    public static let queue: DispatchQueue = DispatchQueue(label: "goodnetworking.queue")

    private let executor: any SerialExecutor

    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: executor)
    }

    public init() {
        self.executor = NetworkActorSerialExecutor(queue: NetworkActor.queue)
    }

    public static func assumeIsolated<T : Sendable>(_ operation: @NetworkActor () throws -> T) rethrows -> T {
        typealias YesActor = @NetworkActor () throws -> T
        typealias NoActor = () throws -> T

        dispatchPrecondition(condition: .onQueue(queue))

        // To do the unsafe cast, we have to pretend it's @escaping.
        return try withoutActuallyEscaping(operation) { (_ fn: @escaping YesActor) throws -> T in
            let rawFn = unsafeBitCast(fn, to: NoActor.self)
            return try rawFn()
        }
    }

}

// MARK: - Executor

internal final class NetworkActorSerialExecutor: SerialExecutor {

    private let queue: DispatchQueue

    internal init(queue: DispatchQueue) {
        self.queue = queue
    }

    internal func enqueue(_ job: UnownedJob) {
        let executor = self.asUnownedSerialExecutor()
        queue.async {
            job.runSynchronously(on: executor)
        }
    }

    internal func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

}
