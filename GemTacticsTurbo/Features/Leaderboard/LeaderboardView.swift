//
//  LeaderboardView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        ScreenContainer(title: "Leaderboard") {
            SectionHeader(title: "Difficulty")

            Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.displayName).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.isUsingLocalLeaderboard {
                Text("Local scores")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            leaderboardContent

            SecondaryButton(title: "Back to Home") {
                router.show(.home)
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
            ProgressView()
                .tint(AppColors.accentPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: AppSpacing.medium) {
                InlineStatusMessage(message: errorMessage)

                SecondaryButton(title: "Retry") {
                    Task {
                        await viewModel.loadScores()
                    }
                }
            }
        } else if viewModel.entries.isEmpty {
            StatCard(
                title: "No Scores",
                value: viewModel.selectedDifficulty.displayName
            )
        } else {
            VStack(spacing: AppSpacing.medium) {
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

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Text("#\(rank)")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.accentSecondary)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Text("\(entry.difficulty.displayName) • \(timestampText)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()

            Text(entry.score.formatted())
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
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
