//
//  PrimaryButton.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct PrimaryButton: View {
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
                .background(AppColors.accentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous))
                .opacity(isEnabled ? 1 : 0.6)
        }
        .shadow(color: AppColors.accentPrimary.opacity(0.35), radius: 12, y: 6)
    }
}
