//
//  DependencyContainer.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import Foundation

protocol WithRequestManager: AnyObject {

    var requestManager: RequestManagerType { get }

}

final class DependencyContainer: WithRequestManager {

    lazy var requestManager: RequestManagerType = RequestManager(baseServer: .base)

}
