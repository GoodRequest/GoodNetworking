//
//  AsyncLock.swift
//  GoodReactor
//
//  Created by Filip Šašala on 26/08/2024.
//

// Implementation of AsyncLock using Swift Concurrency
// Inspired by https://github.com/mattmassicotte/Lock

import Foundation

public final class AsyncLock: @unchecked Sendable {

    private enum State {
        typealias Continuation = CheckedContinuation<Void, Never>

        case unlocked
        case locked([Continuation])

        mutating func addContinuation(_ continuation: Continuation) {
            guard case var .locked(continuations) = self else {
                fatalError("Continuations cannot be added when unlocked")
            }

            continuations.append(continuation)

            self = .locked(continuations)
        }

        mutating func resumeNextContinuation() {
            guard case var .locked(continuations) = self else {
                fatalError("No continuations to resume")
            }

            if continuations.isEmpty {
                self = .unlocked
                return
            }

            let continuation = continuations.removeFirst()
            continuation.resume()

            self = .locked(continuations)
        }
    }

    private var state = State.unlocked

    public init() {}

    public func lock(isolation: isolated (any Actor)? = #isolation) async {
        switch state {
        case .unlocked:
            self.state = .locked([])
        case .locked:
            await withCheckedContinuation { continuation in
                state.addContinuation(continuation)
            }
        }
    }

    public func unlock() {
        state.resumeNextContinuation()
    }

}
