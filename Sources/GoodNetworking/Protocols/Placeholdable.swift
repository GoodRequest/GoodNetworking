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

extension Array: Placeholdable where Element: Placeholdable {

    public static var placeholder: [Element] { [.placeholder, .placeholder, .placeholder] }

}
