import SwiftUI

struct GlassIconButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: AppSpacing.iconButtonSize, height: AppSpacing.iconButtonSize)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppSpacing.radiusInput, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: AppSpacing.radiusInput, style: .continuous)
                            .fill(AppColors.glassFill)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusInput, style: .continuous)
                        .stroke(AppColors.glassBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusInput, style: .continuous))
                .opacity(isEnabled ? 1 : 0.48)
        }
        .buttonStyle(.plain)
    }
}
