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
        ScreenContainer(
            title: "Leaderboard",
            subtitle: viewModel.isUsingLocalLeaderboard
                ? "This local build uses on-device leaderboard storage so completed guest rounds still appear in the app."
                : "Top scores load by difficulty from Firestore, including anonymous guest runs."
        ) {
            SectionHeader(
                title: "Difficulty",
                subtitle: viewModel.isUsingLocalLeaderboard
                    ? "Switch filters to review the best locally saved scores for each mode."
                    : "Switch filters to load the current top scores for each mode."
            )

            Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.displayName).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)

            SectionHeader(
                title: "Rankings",
                subtitle: rankingsSubtitle
            )

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
            StatCard(
                title: "Status",
                value: "Loading",
                detail: "Fetching leaderboard entries for \(viewModel.selectedDifficulty.displayName)."
            )

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
                title: "No Scores Yet",
                value: viewModel.selectedDifficulty.displayName,
                detail: viewModel.isUsingLocalLeaderboard
                    ? "Finish a round to seed the local leaderboard for this difficulty."
                    : "Finish a round to seed the leaderboard for this difficulty."
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

    private var rankingsSubtitle: String {
        if viewModel.isLoading {
            return "Loading scores for \(viewModel.selectedDifficulty.displayName)."
        }

        if viewModel.errorMessage != nil {
            return "Leaderboard loading failed."
        }

        if viewModel.entries.isEmpty {
            return viewModel.isUsingLocalLeaderboard
                ? "No local scores have been saved for this difficulty yet."
                : "No scores have been saved for this difficulty yet."
        }

        return viewModel.isUsingLocalLeaderboard
            ? "Showing the top \(viewModel.entries.count) locally saved scores for \(viewModel.selectedDifficulty.displayName)."
            : "Showing the top \(viewModel.entries.count) scores for \(viewModel.selectedDifficulty.displayName)."
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
