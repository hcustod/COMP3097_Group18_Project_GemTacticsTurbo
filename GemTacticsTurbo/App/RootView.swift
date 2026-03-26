//
//  RootView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var router = AppRouter()
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
        .onReceive(authService.observeAuthState()) { user in
            router.applyAuthState(user)
        }
    }
}

private struct LaunchingPlaceholderView: View {
    var body: some View {
        ScreenContainer(
            title: "Gem Tactics Turbo",
            subtitle: "Checking the current session and preparing the app flow."
        ) {
            SectionHeader(
                title: "Launching",
                subtitle: "Local builds without Firebase configuration now fall straight into guest play so the full MVP remains usable in Xcode."
            )

            ProgressView()
                .tint(AppColors.accentPrimary)
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
