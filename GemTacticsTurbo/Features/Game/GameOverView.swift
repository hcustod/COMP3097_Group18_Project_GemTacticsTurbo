//
//  GameOverView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct GameOverView: View {
    let title: String
    let message: String
    let score: Int
    let onReplay: () -> Void
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Text(title)
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text(message)
                .font(AppTypography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)

            Text("Score \(score)")
                .font(AppTypography.statValue)
                .foregroundStyle(AppColors.textPrimary)

            PrimaryButton(title: "Play Again") {
                onReplay()
            }

            SecondaryButton(title: "Home") {
                onHome()
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .fill(AppColors.backgroundGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .stroke(AppColors.stroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 16, y: 8)
    }
}
