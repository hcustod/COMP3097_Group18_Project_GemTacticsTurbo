import SwiftUI

struct SettingsView: View {
    @ObservedObject var router: AppRouter
    @EnvironmentObject private var settingsStore: SettingsStore
    @State private var isSigningOut = false
    @State private var signOutErrorMessage: String?

    private let authService = AuthService.shared
    private var sessionPresentation: AuthSessionPresentation {
        AuthSessionPresentation.make(
            isGuest: router.isGuest,
            isSigningOut: isSigningOut
        )
    }

    var body: some View {
        ScreenContainer(title: "Settings") {
            VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text("Audio")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                title: "Sound Effects",
                                isOn: $settingsStore.soundEnabled
                            )

                            Divider()
                                .background(AppColors.glassBorder.opacity(0.5))
                                .padding(.vertical, AppSpacing.xSmall)

                            SettingsToggleRow(
                                title: "Music",
                                isOn: $settingsStore.musicEnabled
                            )

                            Divider()
                                .background(AppColors.glassBorder.opacity(0.5))
                                .padding(.vertical, AppSpacing.xSmall)

                            SettingsToggleRow(
                                title: "Haptics",
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

                        VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                            Text("Session")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textMuted)
                            Text(sessionPresentation.sessionStatusTitle)
                                .font(AppTypography.bodyStrong)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        .padding(.vertical, AppSpacing.xSmall)

                        if let signOutErrorMessage {
                            InlineStatusMessage(message: signOutErrorMessage)
                        }

                        VStack(spacing: AppSpacing.stackTight) {
                            if router.isGuest {
                                Text("Guest sessions stay lightweight. You can keep using one, or switch to a full account from here.")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                PrimaryButton(title: "Create Account") {
                                    router.showRegister()
                                }

                                SecondaryButton(title: "Sign In") {
                                    router.showLogin()
                                }
                            } else {
                                PrimaryButton(title: "Delete Account") {
                                    router.show(.deleteAccount)
                                }
                            }

                            if let deletionMessage = sessionPresentation.settingsDeletionMessage {
                                InlineStatusMessage(message: deletionMessage)
                            }

                            SecondaryButton(title: "Home") {
                                router.show(.home)
                            }

                            SecondaryButton(title: sessionPresentation.signOutButtonTitle) {
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
}

private struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
        }
        .tint(AppColors.accentPrimary)
        .padding(.vertical, AppSpacing.xSmall)
    }
}
