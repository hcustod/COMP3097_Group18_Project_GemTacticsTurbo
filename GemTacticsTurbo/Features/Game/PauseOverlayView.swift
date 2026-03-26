//
//  PauseOverlayView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct PauseOverlayView: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Text("Game Paused")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text("Timer countdown and swap input are suspended until you resume.")
                .font(AppTypography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)

            PrimaryButton(title: "Resume") {
                onResume()
            }

            SecondaryButton(title: "Restart Round") {
                onRestart()
            }

            SecondaryButton(title: "Quit to Home") {
                onQuit()
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
