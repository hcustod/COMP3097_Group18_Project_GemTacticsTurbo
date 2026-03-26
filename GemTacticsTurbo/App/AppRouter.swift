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

    func showLaunching() {
        authPath.removeAll()
        mainPath.removeAll()
        rootState = .launching
    }

    func showLogin() {
        authPath.removeAll()
        rootState = .unauthenticated
    }

    func showRegister() {
        rootState = .unauthenticated
        authPath = [.register]
    }

    func enterAuthenticatedHome() {
        authPath.removeAll()
        mainPath.removeAll()
        rootState = .authenticated
    }

    func enterGuestHome() {
        authPath.removeAll()
        mainPath.removeAll()
        rootState = .guest
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
        authPath.removeAll()
        mainPath.removeAll()

        switch user {
        case .some(let authUser) where authUser.isGuest:
            rootState = .guest
        case .some:
            rootState = .authenticated
        case .none:
            rootState = .unauthenticated
        }
    }

    func signOut() {
        authPath.removeAll()
        mainPath.removeAll()
        rootState = .unauthenticated
    }
}
