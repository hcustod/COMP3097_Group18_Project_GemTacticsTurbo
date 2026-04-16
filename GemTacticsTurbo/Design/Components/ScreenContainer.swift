import SwiftUI

struct ScreenContainer<Content: View>: View {
    let title: String?
    let subtitle: String?
    let scrollEnabled: Bool
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    private let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        scrollEnabled: Bool = true,
        horizontalPadding: CGFloat = AppSpacing.pagePadding,
        verticalPadding: CGFloat = AppSpacing.pagePadding,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.scrollEnabled = scrollEnabled
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()

            ArcadeBackdropTexture()
                .ignoresSafeArea()

            if scrollEnabled {
                ScrollView(showsIndicators: false) {
                    containerBody
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, verticalPadding)
                }
            } else {
                containerBody
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
            }
        }
    }

    private var containerBody: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
            if let title, !title.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(title)
                        .font(AppTypography.appTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ArcadeBackdropTexture: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Canvas { context, canvasSize in
                    var scanlines = Path()
                    for y in stride(from: 0 as CGFloat, through: canvasSize.height, by: 4) {
                        scanlines.addRect(CGRect(x: 0, y: y, width: canvasSize.width, height: 1))
                    }
                    context.fill(scanlines, with: .color(Color.black.opacity(0.16)))

                    var dotGrid = Path()
                    for y in stride(from: 12 as CGFloat, through: canvasSize.height, by: 26) {
                        for x in stride(from: 12 as CGFloat, through: canvasSize.width, by: 26) {
                            dotGrid.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                        }
                    }
                    context.fill(
                        dotGrid,
                        with: .color(Color(red: 0.18, green: 0.44, blue: 0.78).opacity(0.12))
                    )

                    var diagonals = Path()
                    let diagonalRise = canvasSize.height * 0.9
                    for start in stride(from: -diagonalRise, through: canvasSize.width + diagonalRise, by: 42) {
                        diagonals.move(to: CGPoint(x: start, y: canvasSize.height))
                        diagonals.addLine(to: CGPoint(x: start + diagonalRise, y: 0))
                    }
                    context.stroke(
                        diagonals,
                        with: .color(Color.white.opacity(0.035)),
                        lineWidth: 1.2
                    )
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.08),
                                .clear,
                                Color.black.opacity(0.30)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Ellipse()
                    .fill(Color(red: 0.18, green: 0.82, blue: 1.00).opacity(0.10))
                    .frame(width: size.width * 0.74, height: size.height * 0.36)
                    .offset(x: -size.width * 0.10, y: -size.height * 0.34)
                    .blur(radius: 90)

                Ellipse()
                    .fill(Color(red: 1.00, green: 0.36, blue: 0.10).opacity(0.08))
                    .frame(width: size.width * 0.52, height: size.height * 0.24)
                    .offset(x: size.width * 0.28, y: size.height * 0.30)
                    .blur(radius: 70)
            }
            .opacity(0.96)
        }
        .allowsHitTesting(false)
    }
}

struct GemTacticsLogoView: View {
    enum Variant {
        case launch
        case home

        var assetName: String {
            switch self {
            case .launch:
                return "LaunchLogo"
            case .home:
                return "HomeLogo"
            }
        }
    }

    let variant: Variant
    var maxWidth: CGFloat? = nil

    var body: some View {
        Image(variant.assetName)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFit()
            .frame(maxWidth: maxWidth)
            .overlay {
                if variant == .home {
                    GeometryReader { proxy in
                        ZStack {
                            HomeLogoGemEffectsOverlay()

                            TurboBadgeFireOverlay()
                                .frame(
                                    width: proxy.size.width * 0.31,
                                    height: proxy.size.height * 0.23
                                )
                                .position(
                                    x: proxy.size.width * 0.80,
                                    y: proxy.size.height * 0.77
                                )
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                    .allowsHitTesting(false)
                }
            }
            .accessibilityHidden(true)
    }
}

private struct HomeLogoGemEffectsOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                RetroDiamondGemOverlay(twinklePhase: 0.2)
                    .frame(width: size.width * 0.17, height: size.height * 0.28)
                    .position(x: size.width * 0.074, y: size.height * 0.226)

                RetroDiamondGemOverlay(twinklePhase: 1.4)
                    .frame(width: size.width * 0.17, height: size.height * 0.28)
                    .position(x: size.width * 0.924, y: size.height * 0.605)
            }
        }
    }
}

private struct RetroDiamondGemOverlay: View {
    let twinklePhase: Double

    private let outerGlow = Color(red: 0.12, green: 0.82, blue: 1.00)
    private let midTone = Color(red: 0.10, green: 0.72, blue: 0.95)
    private let deepTone = Color(red: 0.02, green: 0.34, blue: 0.70)
    private let shadowTone = Color(red: 0.01, green: 0.12, blue: 0.33)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let twinkle = CGFloat((sin(time * 2.6 + twinklePhase) + 1) * 0.5)

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                ZStack {
                    DiamondShape()
                        .fill(shadowTone.opacity(0.55))
                        .scaleEffect(x: 1.10, y: 1.13)
                        .offset(x: width * 0.07, y: height * 0.10)
                        .blur(radius: 6)

                    DiamondShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 1.00, blue: 1.00),
                                    outerGlow,
                                    midTone,
                                    deepTone,
                                    shadowTone
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            DiamondShape()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.95),
                                            Color(red: 0.40, green: 0.95, blue: 1.00),
                                            Color(red: 0.02, green: 0.30, blue: 0.58)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.8
                                )
                        }
                        .shadow(color: outerGlow.opacity(0.60), radius: 12)
                        .shadow(color: Color.white.opacity(0.34), radius: 5)

                    DiamondFacetShape()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1.35)
                        .padding(width * 0.10)

                    DiamondShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.85),
                                    Color.white.opacity(0.10),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(x: 0.48, y: 0.38)
                        .offset(x: -width * 0.14, y: -height * 0.18)
                        .blur(radius: 1.2)

                    DiamondShape()
                        .stroke(Color.white.opacity(0.20 + twinkle * 0.10), lineWidth: 1.1)
                        .scaleEffect(0.80)
                        .blur(radius: 0.6)

                    starTwinkle(
                        size: min(width, height) * 0.18,
                        position: CGPoint(x: width * 0.20, y: height * 0.16),
                        opacity: 0.18 + twinkle * 0.18,
                        rotation: -12
                    )

                    starTwinkle(
                        size: min(width, height) * 0.11,
                        position: CGPoint(x: width * 0.81, y: height * 0.26),
                        opacity: 0.08 + twinkle * 0.12,
                        rotation: 10
                    )
                }
                .rotationEffect(.degrees(-6))
            }
        }
    }

    private func starTwinkle(
        size: CGFloat,
        position: CGPoint,
        opacity: CGFloat,
        rotation: CGFloat
    ) -> some View {
        SparkleStarShape()
            .fill(Color.white.opacity(opacity))
            .frame(width: size, height: size)
            .position(position)
            .rotationEffect(.degrees(rotation))
            .shadow(color: Color.white.opacity(opacity * 0.8), radius: 4)
            .blur(radius: 0.2)
    }
}

private struct TurboBadgeFireOverlay: View {
    private let flameColors = [
        Color(red: 1.00, green: 0.97, blue: 0.76),
        Color(red: 1.00, green: 0.79, blue: 0.22),
        Color(red: 1.00, green: 0.43, blue: 0.08),
        Color(red: 0.85, green: 0.08, blue: 0.03)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let pulse = CGFloat((sin(time * 4.6) + 1) * 0.5)

                ZStack {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.88, blue: 0.38).opacity(0.75 + pulse * 0.15),
                                    Color(red: 1.00, green: 0.36, blue: 0.08).opacity(0.28),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: width * 0.90, height: height * 0.18)
                        .position(x: width * 0.50, y: height * 0.24)
                        .blur(radius: 4 + pulse * 2)

                    flame(
                        size: CGSize(width: width * 0.16, height: height * 0.48),
                        basePosition: CGPoint(x: width * 0.18, y: height * 0.22),
                        time: time,
                        phase: 0.0,
                        blur: 2.8
                    )

                    flame(
                        size: CGSize(width: width * 0.18, height: height * 0.58),
                        basePosition: CGPoint(x: width * 0.36, y: height * 0.18),
                        time: time,
                        phase: 0.9,
                        blur: 3.2
                    )

                    flame(
                        size: CGSize(width: width * 0.20, height: height * 0.62),
                        basePosition: CGPoint(x: width * 0.56, y: height * 0.16),
                        time: time,
                        phase: 1.8,
                        blur: 3.4
                    )

                    flame(
                        size: CGSize(width: width * 0.15, height: height * 0.44),
                        basePosition: CGPoint(x: width * 0.80, y: height * 0.22),
                        time: time,
                        phase: 2.5,
                        blur: 2.8
                    )

                    spark(
                        size: width * 0.05,
                        basePosition: CGPoint(x: width * 0.26, y: height * 0.02),
                        time: time,
                        phase: 0.2
                    )

                    spark(
                        size: width * 0.045,
                        basePosition: CGPoint(x: width * 0.50, y: height * 0.00),
                        time: time,
                        phase: 1.4
                    )

                    spark(
                        size: width * 0.04,
                        basePosition: CGPoint(x: width * 0.74, y: height * 0.04),
                        time: time,
                        phase: 2.2
                    )
                }
                .compositingGroup()
                .blendMode(.plusLighter)
            }
        }
    }

    private func flame(
        size: CGSize,
        basePosition: CGPoint,
        time: TimeInterval,
        phase: Double,
        blur: CGFloat
    ) -> some View {
        let wave = sin(time * 5.8 + phase)
        let lift = max(0, CGFloat(wave))
        let sway = CGFloat(cos(time * 4.2 + phase)) * size.width * 0.12
        let scaleX = 0.92 + CGFloat((sin(time * 3.2 + phase) + 1) * 0.08)

        return Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        flameColors[0],
                        flameColors[1],
                        flameColors[2],
                        flameColors[3].opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size.width, height: size.height * (1.0 + lift * 0.20))
            .scaleEffect(x: scaleX, y: 1.0, anchor: .bottom)
            .rotationEffect(.degrees(CGFloat(sin(time * 3.4 + phase)) * 3.0))
            .position(
                x: basePosition.x + sway,
                y: basePosition.y - size.height * 0.18 * lift
            )
            .opacity(0.82)
            .blur(radius: blur)
    }

    private func spark(
        size: CGFloat,
        basePosition: CGPoint,
        time: TimeInterval,
        phase: Double
    ) -> some View {
        let flicker = CGFloat((sin(time * 7.2 + phase) + 1) * 0.5)

        return Circle()
            .fill(flameColors[0])
            .frame(width: size * (0.8 + flicker * 0.4))
            .position(
                x: basePosition.x + CGFloat(cos(time * 3.0 + phase)) * size * 0.8,
                y: basePosition.y - flicker * size * 1.6
            )
            .opacity(0.25 + flicker * 0.55)
            .blur(radius: 1.2)
    }
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct DiamondFacetShape: Shape {
    func path(in rect: CGRect) -> Path {
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let right = CGPoint(x: rect.maxX, y: rect.midY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: rect.midY)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let upperLeft = CGPoint(x: rect.midX - rect.width * 0.18, y: rect.midY - rect.height * 0.16)
        let upperRight = CGPoint(x: rect.midX + rect.width * 0.18, y: rect.midY - rect.height * 0.16)

        var path = Path()
        path.move(to: top)
        path.addLine(to: center)
        path.move(to: left)
        path.addLine(to: center)
        path.move(to: right)
        path.addLine(to: center)
        path.move(to: bottom)
        path.addLine(to: center)

        path.move(to: upperLeft)
        path.addLine(to: top)
        path.addLine(to: upperRight)
        path.addLine(to: center)
        path.addLine(to: upperLeft)

        return path
    }
}

private struct SparkleStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.midY - rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.midY + rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.midY + rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.midY - rect.height * 0.12))
        path.closeSubpath()
        return path
    }
}
