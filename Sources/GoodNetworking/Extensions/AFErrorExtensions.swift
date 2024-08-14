//
//  AFErrorExtensions.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 03/01/2024.
//

import Alamofire
import Foundation

extension AFError: @unchecked Sendable {}

extension AFError: @retroactive Equatable {

    public static func == (lhs: AFError, rhs: AFError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }

}

extension AFError: @retroactive Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.localizedDescription)
    }

}
