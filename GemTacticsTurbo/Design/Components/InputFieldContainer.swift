//
//  InputFieldContainer.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct InputFieldContainer<Content: View>: View {
    let title: String
    var detail: String? = nil
    private let content: Content

    init(
        title: String,
        detail: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(title.uppercased())
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)

            if let detail {
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            content
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.medium)
                .frame(maxWidth: .infinity, minHeight: AppSpacing.buttonHeight, alignment: .leading)
                .background {
                    ArcadePanelSurface(cornerRadius: AppSpacing.cornerRadius)
                }
        }
    }
}
