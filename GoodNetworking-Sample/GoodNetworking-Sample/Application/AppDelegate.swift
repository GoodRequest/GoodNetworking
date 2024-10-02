//
//  AppDelegate.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import Combine
import GoodNetworking
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        NetworkSession.makeSampleAsyncSession()
        return true
    }

}

@main struct GoodNetworkingSample: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                UserListScreen()
            }
        }
    }

}
