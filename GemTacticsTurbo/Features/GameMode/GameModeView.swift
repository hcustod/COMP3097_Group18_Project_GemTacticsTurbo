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
        ScreenContainer(title: "Choose Difficulty") {
            SectionHeader(title: "Modes")

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

    private var scoreMultiplierText: String {
        String(format: "x%.1f", difficulty.scoreMultiplier)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(difficulty.displayName)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: AppSpacing.medium) {
                difficultyDetail(title: "Moves", value: "\(difficulty.moveLimit)")
                difficultyDetail(title: "Time", value: "\(difficulty.timeLimit)s")
                difficultyDetail(title: "Goal", value: "\(difficulty.targetScore)")
                difficultyDetail(title: "Score", value: scoreMultiplierText)
            }

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
