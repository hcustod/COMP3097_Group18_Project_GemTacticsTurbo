//
//  AppDelegate.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import FirebaseCore
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let hasFirebaseConfiguration = Bundle.main.path(
            forResource: "GoogleService-Info",
            ofType: "plist"
        ) != nil

        if !isRunningTests, hasFirebaseConfiguration, FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        return true
    }
}
