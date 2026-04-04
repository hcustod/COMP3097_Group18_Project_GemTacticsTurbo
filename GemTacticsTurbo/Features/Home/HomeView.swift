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
        ScreenContainer(title: "Gem Tactics Turbo") {
            SectionHeader(title: "Play")

            StatCard(
                title: "Session",
                value: router.isGuest ? "Guest Mode" : "Signed In",
                detail: nil
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

    private var signOutButtonTitle: String {
        if isSigningOut {
            return authService.isRemoteAuthAvailable ? "Signing Out..." : "Ending Session..."
        }

        return authService.isRemoteAuthAvailable ? "Sign Out" : "End Local Session"
    }
}
