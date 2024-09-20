////
////  BaseUrlProviding.swift
////  GoodNetworking
////
////  Created by Andrej Jasso on 20/09/2024.
////

import Foundation

public protocol BaseUrlProviding: Sendable {
    func resolveBaseUrl() async -> String?
}
