//
//  Resource.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 04/01/2024.
//

import Alamofire
import Combine
import Foundation

public protocol Resource: EndpointBindable, Codable, Hashable {

    static var placeholder: Self { get }

}

extension Resource {

    internal func dataTaskPublisher(
        using session: NetworkSession
    ) -> AnyPublisher<ResourceState<Self>, Never> {
        session.request(endpoint: Self.endpoint(self))
            .goodify(type: Self.self)
            .receive(on: DispatchQueue.main)
            .map { .available($0) }
            .catch { Just(.stale(self, $0)).eraseToAnyPublisher() }
            .prepend(.uploading(self))
            .eraseToAnyPublisher()
    }

}

public enum ResourceState<R: Resource>: Equatable {

    case unavailable
    case loading

    case available(R)
    case pending(R)
    case uploading(R)
    case stale(R, AFError)

    public var isAvailable: Bool {
        switch self {
        case .unavailable, .loading:
            return false

        default:
            return true
        }
    }

    public var resource: R? {
        switch self {
        case .unavailable, .loading:
            return nil

        case .available(let resource), .pending(let resource), .uploading(let resource):
            return resource

        case .stale(let resource, _):
            return resource
        }
    }

    public var unwrapped: R {
        guard let resource else { preconditionFailure("Accessing unavailable resource") }
        return resource
    }

}
