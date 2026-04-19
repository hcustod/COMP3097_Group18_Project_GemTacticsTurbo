//
//  RootView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//  Author: Tyson Ward-Dicks - 101501186
//  Changes: Updated startup auth flow so users begin at register and auth state routes correctly.
//

import SwiftUI

struct RootView: View {
    @StateObject private var router = AppRouter()
    @StateObject private var settingsStore = SettingsStore()
    @State private var hasBootstrappedSession = false
    @State private var isBootstrappingSession = false
    private let authService = AuthService.shared

    var body: some View {
        Group {
            // Root switch for launch -> auth -> main game flow.
            switch router.rootState {
            case .launching:
                LaunchingPlaceholderView()
            case .unauthenticated:
                UnauthenticatedFlowView(router: router)
            case .authenticated, .guest:
                MainFlowView(router: router)
            }
        }
        .environmentObject(settingsStore)
        .tint(AppColors.accentPrimary)
        .preferredColorScheme(.dark)
        .task {
            guard !hasBootstrappedSession else {
                return
            }

            hasBootstrappedSession = true
            isBootstrappingSession = true
            await bootstrapSession()
            isBootstrappingSession = false
        }
        .onReceive(authService.observeAuthState()) { user in
            guard !isBootstrappingSession else {
                return
            }

            router.applyAuthState(user)
        }
    }

    private func bootstrapSession() async {
        // Guests always restart at auth so the demo flow starts on register.
        if let currentUser = authService.getCurrentUser() {
            if currentUser.isGuest {
                try? authService.signOut()
                router.applyAuthState(nil)
                return
            }

            router.applyAuthState(currentUser)
            return
        }

        router.applyAuthState(nil)
    }
}

private struct LaunchingPlaceholderView: View {
    var body: some View {
        ScreenContainer(scrollEnabled: false) {
            VStack(spacing: AppSpacing.large) {
                Spacer(minLength: 0)

                GemTacticsLogoView(
                    variant: .launch,
                    maxWidth: 340
                )
                .frame(maxWidth: .infinity)

                Text("Loading the cabinet...")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Launching")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct UnauthenticatedFlowView: View {
    @ObservedObject var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.authPath) {
            // Register is the default entry screen, login is pushed from here.
            RegisterView(router: router)
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
            // Home is the main root once auth is done.
            HomeView(router: router)
                .navigationDestination(for: AppRouter.MainScreen.self) { screen in
                    switch screen {
                    case .home:
                        HomeView(router: router)
                    case .login:
                        LoginView(router: router)
                    case .register:
                        RegisterView(router: router)
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
