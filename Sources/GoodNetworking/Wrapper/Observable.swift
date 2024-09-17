//
//  Observable.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 10/12/2023.
//

import Combine

@propertyWrapper public final class ObservableValue<T>: ObservableObject {

    @Published public var wrappedValue: T

    public init(_ wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

}
