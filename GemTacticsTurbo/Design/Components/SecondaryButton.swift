import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ArcadeButtonFace(palette: .secondary) {
                Text(title.uppercased())
                    .font(AppTypography.buttonArcade)
                    .kerning(0.8)
                    .foregroundStyle(AppColors.textPrimary)
                    .shadow(color: Color.black.opacity(0.42), radius: 0, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
            }
        }
        .buttonStyle(.plain)
    }
}
