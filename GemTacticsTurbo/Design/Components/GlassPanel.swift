import SwiftUI

struct GlassPanel<Content: View>: View {
    private let elevated: Bool
    private let contentPadding: CGFloat
    private let content: Content

    init(
        elevated: Bool = false,
        contentPadding: CGFloat = AppSpacing.cardPaddingLarge,
        @ViewBuilder content: () -> Content
    ) {
        self.elevated = elevated
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        ZStack {
            ArcadePanelSurface(
                elevated: elevated,
                cornerRadius: AppSpacing.radiusPanel
            )

            content
                .padding(contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ArcadePanelSurface: View {
    var elevated: Bool = false
    var cornerRadius: CGFloat = AppSpacing.radiusPanel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppColors.arcadeInk.opacity(elevated ? 0.86 : 0.74))
                .offset(y: elevated ? 10 : 7)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            elevated ? AppColors.arcadePanelTop.opacity(1.0) : AppColors.arcadePanelTop.opacity(0.90),
                            elevated ? AppColors.arcadePanelBottom.opacity(1.0) : AppColors.arcadePanelBottom.opacity(0.94)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius - 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.arcadeBevelHighlight.opacity(elevated ? 0.18 : 0.12),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .padding(3)

            RoundedRectangle(cornerRadius: cornerRadius - 4, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.arcadeBevelHighlight,
                            AppColors.arcadePanelGlow.opacity(0.22)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )
                .padding(3)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColors.arcadeInk.opacity(0.88), lineWidth: 3)

            RoundedRectangle(cornerRadius: cornerRadius - 1.5, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.arcadePanelGlow.opacity(0.36),
                            AppColors.arcadeWarmEdge.opacity(0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.6
                )
                .padding(1.5)
        }
        .shadow(
            color: Color.black.opacity(elevated ? 0.32 : 0.24),
            radius: elevated ? 16 : 10,
            y: elevated ? 10 : 6
        )
    }
}
