//
//  Placeholdable.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 14/08/2024.
//

/// Requires a default, placeholder value.
public protocol Placeholdable: Equatable {

    static var placeholder: Self { get }

}
