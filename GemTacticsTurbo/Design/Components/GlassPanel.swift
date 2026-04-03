import SwiftUI

struct GlassPanel<Content: View>: View {
    private let elevated: Bool
    private let content: Content

    init(elevated: Bool = false, @ViewBuilder content: () -> Content) {
        self.elevated = elevated
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.cardPaddingLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: AppSpacing.radiusPanel, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: AppSpacing.radiusPanel, style: .continuous)
                        .fill(elevated ? AppColors.glassFillElevated : AppColors.glassFill)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusPanel, style: .continuous)
                    .stroke(AppColors.glassBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusPanel, style: .continuous))
    }
}
