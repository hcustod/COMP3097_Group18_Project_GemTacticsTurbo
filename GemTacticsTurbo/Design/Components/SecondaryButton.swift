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
                .frame(maxWidth: .infinity, minHeight: AppSpacing.buttonHeight)
                .padding(.horizontal, AppSpacing.buttonPaddingHorizontal)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppSpacing.radiusCard, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: AppSpacing.radiusCard, style: .continuous)
                            .fill(AppColors.glassFill)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusCard, style: .continuous)
                        .stroke(AppColors.glassBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard, style: .continuous))
                .opacity(isEnabled ? 1 : 0.48)
        }
        .buttonStyle(.plain)
    }
}
