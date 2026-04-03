import SwiftUI

struct ProfileView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ScreenContainer(
            title: "Profile",
            subtitle: router.isGuest
                ? "Guest stats are stored locally for the current anonymous session."
                : "Completed games now update your Firestore-backed profile stats automatically."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                GlassPanel(elevated: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text("Overview")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        Text(sectionSubtitle)
                            .font(AppTypography.label)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        profileContent
                    }
                }

                SecondaryButton(title: "Back to Home") {
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
            VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                Text("STATUS")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                Text("Loading")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Fetching the current profile data.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ProgressView()
                .tint(AppColors.accentPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let errorMessage = viewModel.errorMessage {
            InlineStatusMessage(message: errorMessage)
        } else if let profile = viewModel.profile {
            VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                ProfileStatBlock(
                    overline: "Display Name",
                    value: profile.displayName,
                    detail: profile.email
                        ?? (profile.isGuest ? "Guest sessions do not store an email address." : "No email address is available.")
                )

                ProfileStatBlock(
                    overline: "Avatar",
                    value: profile.avatarName,
                    detail: profile.isGuest
                        ? "Guest sessions use the local guest avatar style for this MVP build."
                        : "Avatar selection is static in the MVP build."
                )

                ProfileStatBlock(
                    overline: "Games Played",
                    value: "\(profile.gamesPlayed)",
                    detail: "Average score: \(profile.averageScore.formatted())"
                )

                ProfileStatBlock(
                    overline: "Highest Score",
                    value: "\(profile.highestScore)",
                    detail: "Unlocked difficulty: \(profile.unlockedDifficulty.capitalized)"
                )

                ProfileStatBlock(
                    overline: "Total Score",
                    value: profile.totalScore.formatted(),
                    detail: "Cumulative score across all completed rounds."
                )

                ProfileStatBlock(
                    overline: "Match Groups",
                    value: "\(profile.totalMatches)",
                    detail: "MVP total matches count every resolved match group across cascade steps."
                )

                SecondaryButton(title: "Refresh Stats") {
                    Task {
                        await viewModel.loadProfile()
                    }
                }
            }
        } else {
            InlineStatusMessage(message: "No profile data is available for the current user.")
        }
    }

    private var sectionSubtitle: String {
        if viewModel.isLoading {
            return "Loading the current profile snapshot."
        }

        if viewModel.errorMessage != nil {
            return "A profile error occurred."
        }

        if router.isGuest {
            return "Guest mode uses local stats for the active anonymous session."
        }

        return "Registered accounts show the latest saved stats from Firestore."
    }
}

private struct ProfileStatBlock: View {
    let overline: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(overline.uppercased())
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
            Text(value)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
            Text(detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppSpacing.xSmall)
    }
}
