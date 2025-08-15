//
//  ResourceState.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 14/08/2024.
//

/// Represents the current state of a resource, optionally with an error associated with the last operation.
///
/// You do not need to create this enum yourself, instead you get its values from the state of a ``Resource``.
public enum ResourceState<R, E: Error> {

    case idle
    case loading
    case failure(E)

    case available(R)
    case pending(R)
    case uploading(R)
    case stale(R, E)
    
    /// Returns `true` when the resource is available for use. See ``value``.
    ///
    /// Resource is considered available when any version of it is accessible locally
    /// on the device. Resources that are yet to be downloaded are considered unavailable
    /// and this property will return `false`.
    public var isAvailable: Bool {
        switch self {
        case .idle, .loading, .failure:
            return false

        default:
            return true
        }
    }

    /// Returns `true` when there is an ongoing network activity (downloading or uploading of data).
    public var isLoading: Bool {
        switch self {
        case .loading, .uploading:
            return true

        default:
            return false
        }
    }

    /// Returns the current value of a resource, or `nil` when the resource is not available.
    /// See ``isAvailable``.
    public var value: R? {
        switch self {
        case .idle, .loading, .failure:
            return nil

        case .available(let resource), .pending(let resource), .uploading(let resource):
            return resource

        case .stale(let resource, _):
            return resource
        }
    }

    /// Returns the current value of a resource or crashes with a `preconditionFailure`.
    /// Check the ``isAvailable`` property first or make sure the resource is always available,
    /// otherwise this is an programming error.
    public var unwrapped: R {
        guard let value else { preconditionFailure("Accessing unavailable resource") }
        return value
    }

    /// Returns the error associated with the last networking operation, if any.
    public var error: E? {
        switch self {
        case .failure(let error), .stale(_, let error):
            return error

        default:
            return nil
        }
    }

    /// Returns `true` when the last networking operation succeeded.
    ///
    /// Syntactic sugar for checking whether ``error`` is `nil`.
    public var isSuccess: Bool {
        error == nil
    }

}

extension ResourceState: Sendable where R: Sendable, E: Sendable {}

// MARK: - Resource state - Equatable

extension ResourceState: Equatable where R: Equatable, E: Equatable {}

/// Equality check using current resource state when resource itself is not equatable
public func ==<R, E>(lhs: ResourceState<R, E>, rhs: ResourceState<R, E>) -> Bool {
    switch lhs {
    case .idle:
        switch rhs {
        case .idle:
            return true
        default:
            return false
        }
    case .loading:
        switch rhs {
        case .loading:
            return true
        default:
            return false
        }
    case .failure:
        switch rhs {
        case .failure:
            return true
        default:
            return false
        }
    case .available:
        switch rhs {
        case .available:
            return true
        default:
            return false
        }
    case .pending:
        switch rhs {
        case .pending:
            return true
        default:
            return false
        }
    case .uploading:
        switch rhs {
        case .uploading:
            return true
        default:
            return false
        }
    case .stale:
        switch rhs {
        case .stale:
            return true
        default:
            return false
        }
    }
}
