//
//  Coordinator.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import UIKit
import Combine

class Coordinator<Step> {

    var rootViewController: UIViewController?

    var rootNavigationController: UINavigationController? {
        return rootViewController as? UINavigationController
    }

    var navigationController: UINavigationController? {
        return rootViewController as? UINavigationController
    }

    func start() -> UIViewController? {
        return rootViewController
    }

    init(rootViewController: UIViewController? = nil) {
        self.rootViewController = rootViewController
    }

    func navigate(to stepper: Step) {}

}
