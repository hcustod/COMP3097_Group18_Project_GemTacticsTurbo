import SwiftUI

struct HomeView: View {
    @ObservedObject var router: AppRouter
    @State private var isSigningOut = false
    @State private var signOutErrorMessage: String?

    private let authService = AuthService.shared
    private var sessionPresentation: AuthSessionPresentation {
        AuthSessionPresentation.make(
            isGuest: router.isGuest,
            isSigningOut: isSigningOut
        )
    }

    var body: some View {
        ScreenContainer(scrollEnabled: false) {
            GeometryReader { geometry in
                ViewThatFits(in: .vertical) {
                    homeContent(in: geometry.size, compact: false)
                    homeContent(in: geometry.size, compact: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func homeContent(in size: CGSize, compact: Bool) -> some View {
        let isLandscape = size.width > size.height
        let spacing = compact ? AppSpacing.medium : AppSpacing.large
        let gridSpacing = compact ? AppSpacing.xSmall + 2 : AppSpacing.small
        let logoWidth = min(
            isLandscape ? size.width * 0.34 : size.width * 0.82,
            compact ? 300 : 380
        )

        Group {
            if isLandscape {
                HStack(alignment: .center, spacing: spacing) {
                    VStack(spacing: spacing) {
                        Spacer(minLength: 0)
                        GemTacticsLogoView(
                            variant: .home,
                            maxWidth: logoWidth
                        )
                        .frame(maxWidth: .infinity, alignment: .center)

                        sessionPanel(compact: compact)

                        if let signOutErrorMessage {
                            InlineStatusMessage(message: signOutErrorMessage)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: 360)

                    homeMenuGrid(spacing: gridSpacing)
                        .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: spacing) {
                    Spacer(minLength: compact ? 0 : AppSpacing.xSmall)

                    GemTacticsLogoView(
                        variant: .home,
                        maxWidth: logoWidth
                    )
                    .frame(maxWidth: .infinity)

                    sessionPanel(compact: compact)

                    if let signOutErrorMessage {
                        InlineStatusMessage(message: signOutErrorMessage)
                    }

                    homeMenuGrid(spacing: gridSpacing)

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func homeMenuGrid(spacing: CGFloat) -> some View {
        LazyVGrid(columns: homeGridColumns(spacing: spacing), spacing: spacing) {
            PrimaryButton(title: "Play") {
                router.show(.gameMode)
            }

            SecondaryButton(title: "How To Play") {
                router.show(.howToPlay)
            }

            SecondaryButton(title: "Leaderboard") {
                router.show(.leaderboard)
            }

            SecondaryButton(title: "Profile") {
                router.show(.profile)
            }

            SecondaryButton(title: "Settings") {
                router.show(.settings)
            }

            SecondaryButton(title: sessionPresentation.signOutButtonTitle) {
                signOut()
            }
            .disabled(isSigningOut)
        }
    }

    private func homeGridColumns(spacing: CGFloat) -> [GridItem] {
        [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }

    private func sessionPanel(compact: Bool) -> some View {
        GlassPanel(
            elevated: true,
            contentPadding: compact ? 14 : 16
        ) {
            HStack(alignment: .center, spacing: compact ? 10 : 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionPresentation.sessionStatusTitle)
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    Text(sessionMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: AppSpacing.small)

                Text(router.isGuest ? "GUEST" : "SIGNED")
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, compact ? 10 : 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule(style: .continuous)
                            .fill(AppColors.arcadeInk.opacity(0.42))
                    }
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(AppColors.glassBorderStrong, lineWidth: 1.2)
                    )
                    .clipShape(Capsule(style: .continuous))
            }
        }
    }

    private var sessionMessage: String {
        if router.isGuest {
            return "Quick play is live."
        }

        return "Profile and leaderboard are ready."
    }

    private func signOut() {
        signOutErrorMessage = nil
        isSigningOut = true
        defer { isSigningOut = false }

        do {
            try authService.signOut()
        } catch {
            signOutErrorMessage = authService.errorMessage(for: error)
        }
    }
}
