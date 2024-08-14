//
//  Remote.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 04/01/2024.
//

/// Represents a resource available on a remote machine (eg. on a web server).
public protocol RemoteResource<Resource>: Sendable {

    associatedtype Resource: (Placeholdable & Sendable)

}
