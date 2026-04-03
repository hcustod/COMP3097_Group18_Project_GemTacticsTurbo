import SwiftUI

struct SettingsView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var settingsStore = SettingsStore()
    @State private var isSigningOut = false
    @State private var signOutErrorMessage: String?

    private let authService = AuthService.shared

    var body: some View {
        ScreenContainer(
            title: "Settings",
            subtitle: authService.isRemoteAuthAvailable
                ? "Preferences persist locally on this device, while account actions stay tied to the current auth session."
                : "Preferences and guest-session testing both run locally in this build."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text("Preferences")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        Text("Audio and feedback toggles are stored locally with UserDefaults-backed settings.")
                            .font(AppTypography.label)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                title: "Sound Effects",
                                detail: "Controls gem swap and game event sound cues.",
                                isOn: $settingsStore.soundEnabled
                            )

                            Divider()
                                .background(AppColors.glassBorder.opacity(0.5))
                                .padding(.vertical, AppSpacing.xSmall)

                            SettingsToggleRow(
                                title: "Music",
                                detail: "Keeps the background soundtrack enabled in the MVP build.",
                                isOn: $settingsStore.musicEnabled
                            )

                            Divider()
                                .background(AppColors.glassBorder.opacity(0.5))
                                .padding(.vertical, AppSpacing.xSmall)

                            SettingsToggleRow(
                                title: "Haptics",
                                detail: "Enables tactile feedback for supported devices.",
                                isOn: $settingsStore.hapticsEnabled
                            )
                        }
                    }
                }

                GlassPanel(elevated: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text("Account")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        Text(
                            router.isGuest
                                ? "Guest sessions can sign out, but they do not expose permanent account deletion."
                                : "Registered accounts can sign out or permanently delete the current account."
                        )
                        .font(AppTypography.label)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                            Text("CURRENT SESSION")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textMuted)
                            Text(router.isGuest ? "Guest Session" : "Registered Session")
                                .font(AppTypography.bodyStrong)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(
                                router.isGuest
                                    ? "Anonymous authentication keeps leaderboard access simple without a permanent profile."
                                    : "This account can load profile stats, save scores, and be deleted from Firebase Auth."
                            )
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, AppSpacing.xSmall)

                        if let signOutErrorMessage {
                            InlineStatusMessage(message: signOutErrorMessage)
                        }

                        VStack(spacing: AppSpacing.stackTight) {
                            if router.isGuest {
                                InlineStatusMessage(message: "Guest sessions do not offer account deletion. Sign out to end the current session.")
                            } else {
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
                }
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
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .tint(AppColors.accentPrimary)
        .padding(.vertical, AppSpacing.xSmall)
    }
}
