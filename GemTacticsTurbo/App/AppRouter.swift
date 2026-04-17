//
//  AppRouter.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import Foundation

@MainActor
final class AppRouter: ObservableObject {
    enum RootState {
        case launching
        case unauthenticated
        case authenticated
        case guest
    }

    enum AuthScreen: Hashable {
        case login
        case register
    }

    enum MainScreen: Hashable {
        case home
        case login
        case register
        case howToPlay
        case gameMode
        case game(Difficulty)
        case leaderboard
        case profile
        case settings
        case deleteAccount
    }

    @Published var rootState: RootState = .launching
    @Published var authPath: [AuthScreen] = []
    @Published var mainPath: [MainScreen] = []

    var isGuest: Bool {
        rootState == .guest
    }

    func showLogin() {
        switch rootState {
        case .launching:
            return
        case .unauthenticated:
            authPath = [.login]
            rootState = .unauthenticated
        case .authenticated:
            return
        case .guest:
            showGuestAccountScreen(.login)
        }
    }

    func showRegister() {
        switch rootState {
        case .launching:
            return
        case .unauthenticated:
            rootState = .unauthenticated
            authPath.removeAll()
        case .authenticated:
            return
        case .guest:
            showGuestAccountScreen(.register)
        }
    }

    func show(_ screen: MainScreen) {
        guard rootState == .authenticated || rootState == .guest else {
            return
        }

        if screen == .home {
            mainPath.removeAll()
            return
        }

        if let existingIndex = mainPath.firstIndex(of: screen) {
            mainPath = Array(mainPath.prefix(through: existingIndex))
            return
        }

        if case .game = screen, let existingGameIndex = mainPath.firstIndex(where: { pathScreen in
            if case .game = pathScreen {
                return true
            }

            return false
        }) {
            mainPath = Array(mainPath.prefix(upTo: existingGameIndex))
        }

        mainPath.append(screen)
    }

    func applyAuthState(_ user: AuthUser?) {
        let newRootState: RootState

        switch user {
        case .some(let authUser) where authUser.isGuest:
            newRootState = .guest
        case .some:
            newRootState = .authenticated
        case .none:
            newRootState = .unauthenticated
        }

        guard rootState != newRootState else {
            return
        }

        authPath.removeAll()
        mainPath.removeAll()
        rootState = newRootState
    }

    func signOut() {
        authPath.removeAll()
        mainPath.removeAll()
        rootState = .unauthenticated
    }

    private func showGuestAccountScreen(_ screen: MainScreen) {
        guard rootState == .guest else {
            return
        }

        if let existingIndex = mainPath.firstIndex(of: screen) {
            mainPath = Array(mainPath.prefix(through: existingIndex))
            return
        }

        if let authScreenIndex = mainPath.firstIndex(where: { pathScreen in
            pathScreen == .login || pathScreen == .register
        }) {
            mainPath = Array(mainPath.prefix(upTo: authScreenIndex))
        }

        mainPath.append(screen)
    }
}
