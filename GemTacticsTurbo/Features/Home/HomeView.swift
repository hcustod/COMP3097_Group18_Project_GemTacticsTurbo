import SwiftUI

struct HomeView: View {
    @ObservedObject var router: AppRouter

    var body: some View {
        ScreenContainer(
            scrollEnabled: false,
            horizontalPadding: AppSpacing.medium,
            verticalPadding: AppSpacing.xSmall
        ) {
            GeometryReader { geometry in
                ViewThatFits(in: .vertical) {
                    homeContent(in: geometry.size, compact: false)
                    homeContent(in: geometry.size, compact: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func homeContent(in size: CGSize, compact: Bool) -> some View {
        let isLandscape = size.width > size.height
        let spacing = compact ? 10.0 : AppSpacing.medium
        let logoWidth = min(
            isLandscape ? size.width * 0.35 : size.width * 0.90,
            compact ? 328 : 430
        )
        let commandDeckWidth = min(
            isLandscape ? size.width * 0.58 : size.width,
            compact ? 520 : 600
        )

        Group {
            if isLandscape {
                HStack(alignment: .center, spacing: spacing) {
                    VStack(spacing: compact ? 8 : 12) {
                        GemTacticsLogoView(
                            variant: .home,
                            maxWidth: logoWidth
                        )
                        .frame(maxWidth: .infinity, alignment: .center)

                        playerStatusBadge
                    }
                    .frame(maxWidth: max(logoWidth, 300), maxHeight: .infinity)

                    homeActionDeck(compact: compact)
                        .frame(maxWidth: commandDeckWidth)
                }
            } else {
                VStack(spacing: spacing) {
                    GemTacticsLogoView(
                        variant: .home,
                        maxWidth: logoWidth
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, compact ? 0 : 4)

                    playerStatusBadge

                    homeActionDeck(compact: compact)
                        .frame(maxWidth: commandDeckWidth)

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func homeActionDeck(compact: Bool) -> some View {
        VStack(spacing: compact ? 9 : AppSpacing.small) {
            HomeHeroButton(
                title: "Start Game",
                subtitle: "Select Stage",
                badge: "A"
            ) {
                router.show(.gameMode)
            }
            .frame(height: compact ? 76 : 88)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: compact ? 8 : 10),
                    GridItem(.flexible(), spacing: compact ? 8 : 10)
                ],
                spacing: compact ? 8 : 10
            ) {
                HomeMenuTile(
                    title: "Guide",
                    subtitle: "Moves",
                    badge: "?",
                    tone: .cyan,
                    compact: compact
                ) {
                    router.show(.howToPlay)
                }

                HomeMenuTile(
                    title: "Ranks",
                    subtitle: "Scores",
                    badge: "#",
                    tone: .gold,
                    compact: compact
                ) {
                    router.show(.leaderboard)
                }

                HomeMenuTile(
                    title: "Player",
                    subtitle: router.isGuest ? "Guest" : "Stats",
                    badge: "ID",
                    tone: .blue,
                    compact: compact
                ) {
                    router.show(.profile)
                }

                HomeMenuTile(
                    title: "Options",
                    subtitle: "Setup",
                    badge: "OP",
                    tone: .red,
                    compact: compact
                ) {
                    router.show(.settings)
                }
            }
        }
        .padding(compact ? 10 : 14)
        .background {
            HomeCommandPanelSurface()
        }
    }

    private var playerStatusBadge: some View {
        HStack(spacing: 8) {
            Text(router.isGuest ? "GUEST MODE" : "PLAYER READY")
                .font(AppTypography.hudLabel)
                .foregroundStyle(AppColors.arcadePanelGlow)
                .kerning(0.8)

            Rectangle()
                .fill(AppColors.arcadeWarmEdge.opacity(0.75))
                .frame(width: 3, height: 16)

            Text(router.isGuest ? "Quick play enabled" : "Profile loaded")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background {
            Capsule(style: .continuous)
                .fill(AppColors.arcadeInk.opacity(0.72))
        }
        .overlay {
            Capsule(style: .continuous)
                .stroke(AppColors.arcadePanelGlow.opacity(0.30), lineWidth: 1)
        }
    }
}

private enum HomeButtonTone {
    case primary
    case cyan
    case gold
    case blue
    case red

    var fillColors: [Color] {
        switch self {
        case .primary:
            return [
                AppColors.arcadePrimaryTop,
                AppColors.arcadePrimaryMid,
                AppColors.arcadePrimaryBottom
            ]
        case .cyan:
            return [
                Color(red: 0.52, green: 1.00, blue: 1.00),
                Color(red: 0.05, green: 0.72, blue: 0.86),
                Color(red: 0.02, green: 0.23, blue: 0.58)
            ]
        case .gold:
            return [
                Color(red: 1.00, green: 0.94, blue: 0.36),
                Color(red: 1.00, green: 0.58, blue: 0.10),
                Color(red: 0.64, green: 0.22, blue: 0.02)
            ]
        case .blue:
            return [
                Color(red: 0.50, green: 0.70, blue: 1.00),
                Color(red: 0.12, green: 0.34, blue: 0.98),
                Color(red: 0.06, green: 0.08, blue: 0.42)
            ]
        case .red:
            return [
                Color(red: 1.00, green: 0.42, blue: 0.36),
                Color(red: 0.90, green: 0.10, blue: 0.20),
                Color(red: 0.42, green: 0.02, blue: 0.12)
            ]
        }
    }

    var edgeColor: Color {
        switch self {
        case .primary, .gold, .red:
            return AppColors.arcadeWarmEdge
        case .cyan, .blue:
            return AppColors.arcadePanelGlow
        }
    }
}

private struct HomeHeroButton: View {
    let title: String
    let subtitle: String
    let badge: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HomeArcadeButtonSurface(tone: .primary, chamfer: 20)

                HStack(spacing: 14) {
                    HomeButtonBadge(text: badge, tone: .primary, isLarge: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title.uppercased())
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)
                            .kerning(1.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)

                        Text(subtitle.uppercased())
                            .font(AppTypography.hudLabel)
                            .foregroundStyle(Color.white.opacity(0.78))
                            .kerning(1.1)
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 4) {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.72))
                            .frame(width: 18, height: 4)

                        Capsule(style: .continuous)
                            .fill(AppColors.arcadeWarmEdge.opacity(0.92))
                            .frame(width: 30, height: 4)

                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.22))
                            .frame(width: 18, height: 4)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct HomeMenuTile: View {
    let title: String
    let subtitle: String
    let badge: String
    let tone: HomeButtonTone
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HomeArcadeButtonSurface(tone: tone, chamfer: 14)

                HStack(spacing: compact ? 7 : 10) {
                    HomeButtonBadge(text: badge, tone: tone, isLarge: false)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.uppercased())
                            .font(.system(size: compact ? 14 : 16, weight: .black, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)
                            .kerning(0.8)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text(subtitle.uppercased())
                            .font(AppTypography.hudLabel)
                            .foregroundStyle(Color.white.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, compact ? 9 : 12)
            }
            .frame(minHeight: compact ? 56 : 64)
        }
        .buttonStyle(.plain)
    }
}

private struct HomeButtonBadge: View {
    let text: String
    let tone: HomeButtonTone
    let isLarge: Bool

    var body: some View {
        Text(text)
            .font(.system(size: isLarge ? 18 : 12, weight: .black, design: .rounded))
            .foregroundStyle(AppColors.textPrimary)
            .frame(width: isLarge ? 44 : 34, height: isLarge ? 44 : 34)
            .background {
                HomeArcadeButtonShape(chamfer: isLarge ? 10 : 8)
                    .fill(AppColors.arcadeInk.opacity(0.78))
            }
            .overlay {
                HomeArcadeButtonShape(chamfer: isLarge ? 9 : 7)
                    .stroke(tone.edgeColor.opacity(0.70), lineWidth: 1.4)
                    .padding(2)
            }
            .shadow(color: tone.edgeColor.opacity(0.32), radius: 7)
    }
}

private struct HomeArcadeButtonSurface: View {
    let tone: HomeButtonTone
    let chamfer: CGFloat

    var body: some View {
        ZStack {
            HomeArcadeButtonShape(chamfer: chamfer)
                .fill(AppColors.arcadeInk.opacity(0.88))
                .offset(y: 7)

            HomeArcadeButtonShape(chamfer: chamfer)
                .fill(
                    LinearGradient(
                        colors: tone.fillColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HomeButtonTexture(tone: tone)
                .clipShape(HomeArcadeButtonShape(chamfer: chamfer))

            HomeArcadeButtonShape(chamfer: max(chamfer - 3, 1))
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.30),
                            Color.white.opacity(0.04),
                            Color.black.opacity(0.20)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(3)

            HomeArcadeButtonShape(chamfer: chamfer)
                .stroke(AppColors.arcadeInk.opacity(0.94), lineWidth: 3)

            HomeArcadeButtonShape(chamfer: max(chamfer - 3, 1))
                .stroke(AppColors.arcadeBevelHighlight.opacity(0.70), lineWidth: 1.2)
                .padding(3)

            HomeArcadeButtonShape(chamfer: max(chamfer - 1.5, 1))
                .stroke(tone.edgeColor.opacity(0.82), lineWidth: 1.6)
                .padding(1.5)
        }
        .shadow(color: tone.edgeColor.opacity(0.22), radius: 15, y: 8)
    }
}

private struct HomeButtonTexture: View {
    let tone: HomeButtonTone

    var body: some View {
        Canvas { context, canvasSize in
            var diagonalLines = Path()
            let rise = canvasSize.height * 1.15

            for start in stride(from: -rise, through: canvasSize.width + rise, by: 16) {
                diagonalLines.move(to: CGPoint(x: start, y: canvasSize.height))
                diagonalLines.addLine(to: CGPoint(x: start + rise, y: 0))
            }

            context.stroke(
                diagonalLines,
                with: .color(Color.white.opacity(0.075)),
                lineWidth: 1.1
            )

            var scanlines = Path()
            for y in stride(from: 4 as CGFloat, through: canvasSize.height, by: 6) {
                scanlines.addRect(CGRect(x: 0, y: y, width: canvasSize.width, height: 1))
            }

            context.fill(scanlines, with: .color(Color.black.opacity(0.10)))

            var sideDots = Path()
            for y in stride(from: canvasSize.height * 0.24, through: canvasSize.height * 0.80, by: 8) {
                sideDots.addEllipse(
                    in: CGRect(
                        x: canvasSize.width * 0.86,
                        y: y,
                        width: 2.4,
                        height: 2.4
                    )
                )
            }

            context.fill(sideDots, with: .color(tone.edgeColor.opacity(0.22)))
        }
        .allowsHitTesting(false)
    }
}

private struct HomeCommandPanelSurface: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.arcadeInk.opacity(0.84))
                .offset(y: 10)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.20, blue: 0.50),
                            Color(red: 0.05, green: 0.07, blue: 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.arcadePanelGlow.opacity(0.46),
                            AppColors.arcadeWarmEdge.opacity(0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(3)
        }
    }
}

private struct HomeArcadeButtonShape: Shape {
    var chamfer: CGFloat

    func path(in rect: CGRect) -> Path {
        let inset = min(chamfer, min(rect.width, rect.height) * 0.30)

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
