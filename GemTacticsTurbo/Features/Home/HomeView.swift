import SwiftUI

struct HomeView: View {
    @ObservedObject var router: AppRouter
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
        ScreenContainer(title: "Gem Tactics Turbo") {
            VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                GlassPanel(elevated: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                        Text("Session")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textMuted)
                        Text(sessionPresentation.sessionStatusTitle)
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.textPrimary)

                        if let signOutErrorMessage {
                            InlineStatusMessage(message: signOutErrorMessage)
                        }
                    }
                }

                GlassPanel {
                    VStack(spacing: AppSpacing.stackTight) {
                        PrimaryButton(title: "Play") {
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
