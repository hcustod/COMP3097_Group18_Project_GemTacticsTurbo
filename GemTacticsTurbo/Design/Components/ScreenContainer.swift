//
//  ScreenContainer.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct ScreenContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    private let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(title)
                            .font(AppTypography.appTitle)
                            .foregroundStyle(AppColors.textPrimary)

                        if let subtitle {
                            Text(subtitle)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.screenVertical)
            }
        }
    }
}
