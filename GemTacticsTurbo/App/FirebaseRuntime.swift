//
//  FirebaseRuntime.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import FirebaseCore
import Foundation

enum FirebaseRuntime {
    private static let configurationFileName = "GoogleService-Info"
    private(set) static var isConfigured = false

    static var hasConfigurationFile: Bool {
        Bundle.main.path(
            forResource: configurationFileName,
            ofType: "plist"
        ) != nil
    }

    static func configureIfAvailable() {
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        guard !isRunningTests, hasConfigurationFile else {
            isConfigured = false
            return
        }

        guard !isConfigured else {
            return
        }

        FirebaseApp.configure()
        isConfigured = true
    }
}
