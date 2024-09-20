////
////  BaseUrlProviding.swift
////  GoodNetworking
////
////  Created by Andrej Jasso on 20/09/2024.
////

public protocol BaseUrlProviding: Sendable {

    func resolveBaseUrl() async -> String?
    
}

extension String: BaseUrlProviding {

    public func resolveBaseUrl() async -> String? {
        self
    }

}
