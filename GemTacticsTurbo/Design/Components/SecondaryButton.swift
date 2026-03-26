//
//  SecondaryButton.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct SecondaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppSpacing.buttonHeight)
                .background(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                        .stroke(AppColors.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
                .opacity(isEnabled ? 1 : 0.6)
        }
    }
}
