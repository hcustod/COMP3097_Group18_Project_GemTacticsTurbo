//
//  AppDelegate.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseRuntime.configureIfAvailable()
        return true
    }
}
