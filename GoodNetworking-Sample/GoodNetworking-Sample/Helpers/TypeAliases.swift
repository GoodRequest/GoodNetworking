//
//  TypeAliases.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import Combine
import Alamofire

typealias DI = DependencyContainer
typealias RequestPublisher<Model> = AnyPublisher<Model, AFError>
