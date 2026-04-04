//
//  SettingsView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var settingsStore = SettingsStore()
    @State private var isSigningOut = false
    @State private var signOutErrorMessage: String?

    private let authService = AuthService.shared

    var body: some View {
        ScreenContainer(title: "Settings") {
            SectionHeader(title: "Preferences")

            VStack(spacing: AppSpacing.medium) {
                SettingsToggleRow(
                    title: "Sound Effects",
                    isOn: $settingsStore.soundEnabled
                )

                SettingsToggleRow(
                    title: "Music",
                    isOn: $settingsStore.musicEnabled
                )

                SettingsToggleRow(
                    title: "Haptics",
                    isOn: $settingsStore.hapticsEnabled
                )
            }

            SectionHeader(title: "Session")

            StatCard(
                title: "Current",
                value: router.isGuest ? "Guest Session" : "Registered Session",
                detail: nil
            )

            if let signOutErrorMessage {
                InlineStatusMessage(message: signOutErrorMessage)
            }

            VStack(spacing: AppSpacing.medium) {
                if !router.isGuest {
                    PrimaryButton(title: "Delete Account") {
                        router.show(.deleteAccount)
                    }
                }

                SecondaryButton(title: "Back to Home") {
                    router.show(.home)
                }

                SecondaryButton(title: signOutButtonTitle) {
                    signOut()
                }
                .disabled(isSigningOut)
            }
        }
        .navigationTitle("Settings")
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

private struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Toggle(isOn: $isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
            .tint(AppColors.accentPrimary)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .stroke(AppColors.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
    }
}
