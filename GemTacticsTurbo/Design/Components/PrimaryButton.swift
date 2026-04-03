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
                .frame(maxWidth: .infinity, minHeight: AppSpacing.buttonHeight)
                .padding(.horizontal, AppSpacing.buttonPaddingHorizontal)
                .background(AppColors.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard, style: .continuous))
                .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .shadow(
            color: AppColors.accentPrimary.opacity(isEnabled ? 0.42 : 0.12),
            radius: isEnabled ? 14 : 5,
            y: isEnabled ? 7 : 2
        )
    }
}
