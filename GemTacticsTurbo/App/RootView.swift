//
//  RootView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var router = AppRouter()
    @State private var hasBootstrappedSession = false
    private let authService = AuthService.shared

    var body: some View {
        Group {
            switch router.rootState {
            case .launching:
                LaunchingPlaceholderView()
            case .unauthenticated:
                UnauthenticatedFlowView(router: router)
            case .authenticated, .guest:
                MainFlowView(router: router)
            }
        }
        .tint(AppColors.accentPrimary)
        .preferredColorScheme(.dark)
        .task {
            guard !hasBootstrappedSession else {
                return
            }

            hasBootstrappedSession = true
            await bootstrapSession()
        }
        .onReceive(authService.observeAuthState()) { user in
            router.applyAuthState(user)
        }
    }

    private func bootstrapSession() async {
        if let currentUser = authService.getCurrentUser() {
            router.applyAuthState(currentUser)
            return
        }

        if !authService.isRemoteAuthAvailable {
            _ = try? await authService.signInAnonymously()
            return
        }

        router.applyAuthState(nil)
    }
}

private struct LaunchingPlaceholderView: View {
    var body: some View {
        ScreenContainer(title: "Gem Tactics Turbo") {
            ProgressView()
                .tint(AppColors.accentPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle("Launching")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct UnauthenticatedFlowView: View {
    @ObservedObject var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.authPath) {
            LoginView(router: router)
                .navigationDestination(for: AppRouter.AuthScreen.self) { screen in
                    switch screen {
                    case .login:
                        LoginView(router: router)
                    case .register:
                        RegisterView(router: router)
                    }
                }
        }
    }
}

private struct MainFlowView: View {
    @ObservedObject var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.mainPath) {
            HomeView(router: router)
                .navigationDestination(for: AppRouter.MainScreen.self) { screen in
                    switch screen {
                    case .home:
                        HomeView(router: router)
                    case .howToPlay:
                        HowToPlayView(router: router)
                    case .gameMode:
                        GameModeView(router: router)
                    case .game(let difficulty):
                        GameContainerView(router: router, difficulty: difficulty)
                    case .leaderboard:
                        LeaderboardView(router: router)
                    case .profile:
                        ProfileView(router: router)
                    case .settings:
                        SettingsView(router: router)
                    case .deleteAccount:
                        DeleteAccountView(router: router)
                    }
                }
        }
    }
}
