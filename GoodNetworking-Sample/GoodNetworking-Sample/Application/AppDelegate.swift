//
//  AppDelegate.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import UIKit
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow()

        UINavigationBar.setAppearance()

        AppCoordinator(window: window, di: DI()).start()

        return true
    }

}

