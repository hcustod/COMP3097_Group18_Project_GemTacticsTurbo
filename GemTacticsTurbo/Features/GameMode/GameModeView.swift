//
//  GameModeView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct GameModeView: View {
    @ObservedObject var router: AppRouter

    var body: some View {
        ScreenContainer(
            title: "Game Mode",
            subtitle: "Choose a difficulty and jump straight into a live match-3 round with the selected rules."
        ) {
            SectionHeader(
                title: "Mode Select",
                subtitle: "Each option is generated from the centralized difficulty model so the rules stay consistent across the app."
            )

            StatCard(
                title: "Selection Flow",
                value: "Difficulty Ready",
                detail: "Pick a difficulty to start a live board session with the matching move limit, timer, and target score."
            )

            VStack(spacing: AppSpacing.medium) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyCard(difficulty: difficulty) {
                        router.show(.game(difficulty))
                    }
                }

                SecondaryButton(title: "Back to Home") {
                    router.show(.home)
                }
            }
        }
        .navigationTitle("Game Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DifficultyCard: View {
    let difficulty: Difficulty
    let action: () -> Void

    private var multiplierText: String {
        String(format: "%.1f", difficulty.scoreMultiplier)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(difficulty.displayName)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: AppSpacing.medium) {
                difficultyDetail(title: "Moves", value: "\(difficulty.moveLimit)")
                difficultyDetail(title: "Time", value: "\(difficulty.timeLimit)s")
                difficultyDetail(title: "Target", value: "\(difficulty.targetScore)")
            }

            Text("Score multiplier: \(multiplierText)x")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)

            PrimaryButton(title: "Play \(difficulty.displayName)") {
                action()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .stroke(AppColors.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
    }

    private func difficultyDetail(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(title.uppercased())
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)

            Text(value)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
