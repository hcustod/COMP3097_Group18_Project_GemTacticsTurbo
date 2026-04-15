//
//  StatCard.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var detail: String? = nil

    var body: some View {
        ZStack {
            ArcadePanelSurface(cornerRadius: AppSpacing.cornerRadius)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(title.uppercased())
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)

                Text(value)
                    .font(AppTypography.statValue)
                    .foregroundStyle(AppColors.textPrimary)

                if let detail {
                    Text(detail)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.cardPadding)
        }
    }
}
