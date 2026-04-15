import SwiftUI

enum ArcadeButtonPalette {
    case primary
    case secondary

    var fillColors: [Color] {
        switch self {
        case .primary:
            return [AppColors.arcadePrimaryTop, AppColors.arcadePrimaryMid, AppColors.arcadePrimaryBottom]
        case .secondary:
            return [AppColors.arcadeSecondaryTop, AppColors.arcadeSecondaryMid, AppColors.arcadeSecondaryBottom]
        }
    }

    var edgeColor: Color {
        switch self {
        case .primary:
            return AppColors.arcadeWarmEdge
        case .secondary:
            return AppColors.arcadePanelGlow
        }
    }

    var glowColor: Color {
        switch self {
        case .primary:
            return AppColors.arcadeWarmEdge
        case .secondary:
            return AppColors.arcadePanelGlow
        }
    }
}

struct ArcadeButtonFace<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled

    let palette: ArcadeButtonPalette
    let label: Label

    init(
        palette: ArcadeButtonPalette,
        @ViewBuilder label: () -> Label
    ) {
        self.palette = palette
        self.label = label()
    }

    var body: some View {
        ZStack {
            ArcadeButtonShape(chamfer: 16)
                .fill(AppColors.arcadeInk.opacity(isEnabled ? 0.86 : 0.58))
                .offset(y: isEnabled ? 7 : 4)

            ArcadeButtonShape(chamfer: 16)
                .fill(
                    LinearGradient(
                        colors: palette.fillColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            ArcadeButtonTexture(palette: palette)
                .clipShape(ArcadeButtonShape(chamfer: 16))

            ArcadeButtonShape(chamfer: 13)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.arcadeBevelHighlight.opacity(isEnabled ? 0.40 : 0.18),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .padding(3)

            ArcadeButtonShape(chamfer: 16)
                .stroke(AppColors.arcadeInk.opacity(0.92), lineWidth: 3)

            ArcadeButtonShape(chamfer: 13)
                .stroke(AppColors.arcadeBevelHighlight.opacity(0.78), lineWidth: 1.2)
                .padding(3)

            ArcadeButtonShape(chamfer: 14.5)
                .stroke(palette.edgeColor.opacity(0.70), lineWidth: 1.4)
                .padding(1.5)

            label
                .padding(.horizontal, AppSpacing.buttonPaddingHorizontal)
                .frame(maxWidth: .infinity, minHeight: AppSpacing.buttonHeight)
        }
        .shadow(
            color: palette.glowColor.opacity(isEnabled ? 0.28 : 0.10),
            radius: isEnabled ? 14 : 5,
            y: isEnabled ? 7 : 3
        )
        .opacity(isEnabled ? 1 : 0.60)
    }
}

private struct ArcadeButtonTexture: View {
    let palette: ArcadeButtonPalette

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Canvas { context, canvasSize in
                    var diagonalLines = Path()
                    let diagonalStep: CGFloat = 18
                    let diagonalRise = canvasSize.height * 0.92

                    for start in stride(from: -diagonalRise, through: canvasSize.width + diagonalRise, by: diagonalStep) {
                        diagonalLines.move(to: CGPoint(x: start, y: canvasSize.height))
                        diagonalLines.addLine(to: CGPoint(x: start + diagonalRise, y: 0))
                    }

                    context.stroke(
                        diagonalLines,
                        with: .color(Color.white.opacity(0.07)),
                        lineWidth: 1.2
                    )

                    var scanlines = Path()
                    for y in stride(from: 5 as CGFloat, through: canvasSize.height, by: 5) {
                        scanlines.addRect(CGRect(x: 0, y: y, width: canvasSize.width, height: 0.85))
                    }

                    context.fill(
                        scanlines,
                        with: .color(Color.black.opacity(0.09))
                    )

                    var dotField = Path()
                    for y in stride(from: canvasSize.height * 0.22, through: canvasSize.height * 0.78, by: 8) {
                        for x in stride(from: canvasSize.width * 0.66, through: canvasSize.width * 0.96, by: 10) {
                            dotField.addEllipse(in: CGRect(x: x, y: y, width: 2.2, height: 2.2))
                        }
                    }

                    context.fill(
                        dotField,
                        with: .color(palette.edgeColor.opacity(0.18))
                    )
                }

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        .clear,
                        palette.edgeColor.opacity(0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: size.width * 0.42, height: size.height * 0.18)
                    .rotationEffect(.degrees(-16))
                    .offset(x: -size.width * 0.18, y: -size.height * 0.18)
                    .blur(radius: 2.8)
            }
            .compositingGroup()
        }
        .allowsHitTesting(false)
    }
}

private struct ArcadeButtonShape: Shape {
    var chamfer: CGFloat

    func path(in rect: CGRect) -> Path {
        let inset = min(chamfer, min(rect.width, rect.height) * 0.28)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + inset))
        path.closeSubpath()
        return path
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ArcadeButtonFace(palette: .primary) {
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
