//
//  AFErrorExtensions.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 03/01/2024.
//

import Alamofire

extension AFError: Equatable {

    public static func == (lhs: AFError, rhs: AFError) -> Bool {
        false // every AFError is unique
    }

}
