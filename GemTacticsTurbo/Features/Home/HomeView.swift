import SwiftUI

struct HomeView: View {
    @ObservedObject var router: AppRouter
    @State private var isSigningOut = false
    @State private var signOutErrorMessage: String?

    private let authService = AuthService.shared
    private var sessionPresentation: AuthSessionPresentation {
        AuthSessionPresentation.make(
            isGuest: router.isGuest,
            isRemoteAuthAvailable: authService.isRemoteAuthAvailable,
            isSigningOut: isSigningOut
        )
    }

    var body: some View {
        ScreenContainer(
            title: "Gem Tactics Turbo",
            subtitle: sessionPresentation.homeSubtitle
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                GlassPanel(elevated: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text("Home")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        Text("Jump into a round, review your stats, or manage the current session.")
                            .font(AppTypography.label)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text("SESSION")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textMuted)
                            Text(sessionPresentation.sessionStatusTitle)
                                .font(AppTypography.bodyStrong)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(sessionPresentation.homeSessionDetail)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, AppSpacing.xSmall)

                        if let signOutErrorMessage {
                            InlineStatusMessage(message: signOutErrorMessage)
                        }
                    }
                }

                GlassPanel {
                    VStack(spacing: AppSpacing.stackTight) {
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

                        SecondaryButton(title: sessionPresentation.signOutButtonTitle) {
                            signOut()
                        }
                        .disabled(isSigningOut)
                    }
                }
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
}
