import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        ScreenContainer(title: "Leaderboard") {
            VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text("Difficulty")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                Text(difficulty.displayName).tag(difficulty)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                GlassPanel(elevated: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text("Top Scores")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        leaderboardContent
                    }
                }

                SecondaryButton(title: "Home") {
                    router.show(.home)
                }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: viewModel.selectedDifficulty) {
            await viewModel.loadScores()
        }
    }

    @ViewBuilder
    private var leaderboardContent: some View {
        if viewModel.isLoading {
            VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                Text("Loading")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ProgressView()
                .tint(AppColors.accentPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: AppSpacing.stackStandard) {
                InlineStatusMessage(message: errorMessage)

                SecondaryButton(title: "Retry") {
                    Task {
                        await viewModel.loadScores()
                    }
                }
            }
        } else if viewModel.entries.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                Text("No scores yet")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: AppSpacing.stackTight) {
                ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRow(
                        rank: index + 1,
                        entry: entry
                    )
                }
            }
        }
    }

}

private struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry

    private var timestampText: String {
        entry.timestamp.formatted(date: .abbreviated, time: .omitted)
    }

    private var rankForeground: AnyShapeStyle {
        switch rank {
        case 1:
            AnyShapeStyle(AppColors.rankGoldGradient)
        case 2:
            AnyShapeStyle(AppColors.rankSilverForeground)
        case 3:
            AnyShapeStyle(AppColors.rankBronzeGradient)
        default:
            AnyShapeStyle(AppColors.accentSecondary)
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            Text("#\(rank)")
                .font(AppTypography.hudValue)
                .foregroundStyle(rankForeground)
                .frame(width: 48, alignment: .leading)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(entry.displayName)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Text("\(entry.difficulty.displayName) • \(timestampText)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer(minLength: AppSpacing.small)

            Text(entry.score.formatted())
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(AppSpacing.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard, style: .continuous)
                .fill(AppColors.glassFillElevated)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard, style: .continuous)
                .stroke(AppColors.glassBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard, style: .continuous))
    }
}
