import SwiftUI

struct ProfileView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ScreenContainer(title: "Profile") {
            VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                if router.isGuest {
                    GlassPanel {
                        VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                            Text("Guest Profile")
                                .font(AppTypography.sectionTitle)
                                .foregroundStyle(AppColors.brandGradientText)

                            Text("You can keep playing as a guest, or switch to a full account to sign in with email and keep a named player identity.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(spacing: AppSpacing.stackTight) {
                                PrimaryButton(title: "Create Account") {
                                    router.showRegister()
                                }

                                SecondaryButton(title: "Sign In") {
                                    router.showLogin()
                                }
                            }
                        }
                    }
                }

                GlassPanel(elevated: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text("Stats")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        profileContent
                    }
                }

                SecondaryButton(title: "Home") {
                    router.show(.home)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile()
        }
    }

    @ViewBuilder
    private var profileContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(AppColors.accentPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let errorMessage = viewModel.errorMessage {
            InlineStatusMessage(message: errorMessage)
        } else if let profile = viewModel.profile {
            VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                ProfileStatBlock(
                    overline: "Name",
                    value: profile.displayName,
                    detail: profile.email
                )

                ProfileStatBlock(
                    overline: "Games",
                    value: "\(profile.gamesPlayed)"
                )

                ProfileStatBlock(
                    overline: "Average",
                    value: profile.averageScore.formatted()
                )

                ProfileStatBlock(
                    overline: "Best",
                    value: "\(profile.highestScore)"
                )

                ProfileStatBlock(
                    overline: "Total",
                    value: profile.totalScore.formatted()
                )

                ProfileStatBlock(
                    overline: "Matches",
                    value: "\(profile.totalMatches)"
                )

                SecondaryButton(title: "Refresh") {
                    Task {
                        await viewModel.loadProfile()
                    }
                }
            }
        } else {
            InlineStatusMessage(message: "No profile data is available for the current user.")
        }
    }
}

private struct ProfileStatBlock: View {
    let overline: String
    let value: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(overline.uppercased())
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
            Text(value)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppSpacing.xSmall)
    }
}
