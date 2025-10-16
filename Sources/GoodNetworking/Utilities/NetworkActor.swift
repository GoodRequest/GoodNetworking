//
//  NetworkActor.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

import Foundation

// MARK: - Actor

@globalActor public actor NetworkActor {
    
    // MARK: - Static
    
    public static let shared: NetworkActor = NetworkActor()
    public static let queue: DispatchQueue = DispatchQueue(label: "goodnetworking.queue")
    
    private static let executor: NetworkActorExecutor = NetworkActorExecutor()
    
    // MARK: - Computed properties
    
    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        Self.executor.asUnownedSerialExecutor()
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Isolation
    
    public static func assumeIsolated<T>(
        _ block: @NetworkActor () throws -> sending T
    ) rethrows -> sending T {
        typealias YesActor = @NetworkActor () throws -> sending T
        typealias NoActor = () throws -> sending T

        if #available(iOS 18, *) {
            NetworkActor.preconditionIsolated()
        } else {
            // manual call to checkIsolated() as Swift runtime doesn't
            // support custom implementation before iOS 18/26
            executor.checkIsolated()
        }

        return try withoutActuallyEscaping(block) { (_ fn: @escaping YesActor) throws -> sending T in
            try unsafeBitCast(fn, to: NoActor.self)()
        }
    }
    
}

internal final class NetworkActorExecutor: SerialExecutor {
    
    internal func enqueue(_ job: UnownedJob) {
        NetworkActor.queue.async {
            job.runSynchronously(on: NetworkActor.sharedUnownedExecutor)
        }
    }
    
    internal func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
    
    // AVAILABLE: (iOS 26.0, macOS 26.0, *)
    internal func isIsolatingCurrentContext() -> Bool? {
        if OperationQueue.current?.underlyingQueue == NetworkActor.queue {
            return true
        } else {
            return nil
        }
    }
    
    // AVAILABLE: (iOS 18.0, macOS 15.0, *)
    internal func checkIsolated() {
        guard isIsolatingCurrentContext() ?? false else {
            fatalError()
        }
    }
    
}
