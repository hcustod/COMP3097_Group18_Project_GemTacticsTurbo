//
//  HomeView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var router: AppRouter
    @State private var isSigningOut = false
    @State private var signOutErrorMessage: String?

    private let authService = AuthService.shared

    var body: some View {
        ScreenContainer(
            title: "Gem Tactics Turbo",
            subtitle: homeSubtitle
        ) {
            SectionHeader(
                title: "Home",
                subtitle: "Jump into a round, review your stats, or manage the current session."
            )

            StatCard(
                title: "Session",
                value: router.isGuest ? "Guest Mode" : "Signed In",
                detail: sessionDetail
            )

            if let signOutErrorMessage {
                InlineStatusMessage(message: signOutErrorMessage)
            }

            VStack(spacing: AppSpacing.medium) {
                PrimaryButton(title: "Game Mode") {
                    router.show(.gameMode)
                }

                SecondaryButton(title: "How To Play") {
                    router.show(.howToPlay)
                }

                SecondaryButton(title: "Leaderboard") {
                    router.show(.leaderboard)
                }

                SecondaryButton(title: "Profile") {
                    router.show(.profile)
                }

                SecondaryButton(title: "Settings") {
                    router.show(.settings)
                }

                SecondaryButton(title: signOutButtonTitle) {
                    signOut()
                }
                .disabled(isSigningOut)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signOut() {
        signOutErrorMessage = nil
        isSigningOut = true
        defer { isSigningOut = false }

        do {
            try authService.signOut()
        } catch {
            signOutErrorMessage = authService.errorMessage(for: error)
        }
    }

    private var homeSubtitle: String {
        if router.isGuest && !authService.isRemoteAuthAvailable {
            return "Local guest mode is active. You can play rounds, store guest stats, and review an on-device leaderboard from here."
        }

        if router.isGuest {
            return "Guest access is active through anonymous authentication. You can play, save scores, and keep local guest stats from here."
        }

        return "Authenticated access is active through email sign-in. Use Home as the main hub for gameplay, profile, leaderboard, and settings."
    }

    private var signOutButtonTitle: String {
        if isSigningOut {
            return authService.isRemoteAuthAvailable ? "Signing Out..." : "Ending Session..."
        }

        return authService.isRemoteAuthAvailable ? "Sign Out" : "End Local Session"
    }

    private var sessionDetail: String {
        if router.isGuest && !authService.isRemoteAuthAvailable {
            return "This session was created locally so the app can run without Firebase setup."
        }

        if router.isGuest {
            return "This session was created with Firebase anonymous authentication."
        }

        return "This session was created through the email authentication flow."
    }
}
