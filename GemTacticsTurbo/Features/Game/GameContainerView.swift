//
//  GameContainerView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SpriteKit
import SwiftUI
import UIKit

struct GameContainerView: View {
    @ObservedObject var router: AppRouter
    @EnvironmentObject private var settingsStore: SettingsStore
    let difficulty: Difficulty
    @StateObject private var viewModel: GameViewModel
    @StateObject private var sceneCoordinator: GameSceneCoordinator

    init(router: AppRouter, difficulty: Difficulty) {
        self._router = ObservedObject(wrappedValue: router)
        self.difficulty = difficulty
        let viewModel = GameViewModel(difficulty: difficulty)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._sceneCoordinator = StateObject(
            wrappedValue: GameSceneCoordinator(board: viewModel.board)
        )
    }

    private var timeText: String {
        let minutes = viewModel.session.remainingTime / 60
        let seconds = viewModel.session.remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var boardAspectRatio: CGFloat {
        let rowCount = max(viewModel.session.rowCount, 1)
        let columnCount = max(viewModel.session.columnCount, 1)
        return CGFloat(columnCount) / CGFloat(rowCount)
    }

    private var gameOverTitle: String {
        viewModel.session.isWin ? "You Win" : "Game Over"
    }

    private var gameOverMessage: String {
        viewModel.statusMessage
    }

    var body: some View {
        ZStack {
            ScreenContainer(
                scrollEnabled: false,
                horizontalPadding: AppSpacing.xSmall,
                verticalPadding: AppSpacing.xSmall
            ) {
                GeometryReader { geometry in
                    ViewThatFits(in: .vertical) {
                        gameContent(in: geometry.size, compact: false)
                        gameContent(in: geometry.size, compact: true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(difficulty.displayName)
            .navigationBarTitleDisplayMode(.inline)

            if viewModel.isPreparingBoard {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()

                BoardLoadingOverlay(
                    title: "Loading"
                )
                .padding(24)
            }

            if viewModel.session.isPaused && !viewModel.session.isGameOver {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                PauseOverlayView(
                    onResume: {
                        viewModel.resumeGame()
                    },
                    onRestart: {
                        restartRound()
                    },
                    onQuit: {
                        leaveGame()
                    }
                )
                .padding(24)
            }

            if viewModel.session.isGameOver {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                GameOverView(
                    title: gameOverTitle,
                    message: gameOverMessage,
                    score: viewModel.session.score,
                    onReplay: {
                        restartRound()
                    },
                    onHome: {
                        leaveGame()
                    }
                )
                .padding(24)
            }
        }
        .onAppear {
            sceneCoordinator.configureHapticsEnabled { settingsStore.hapticsEnabled }
            sceneCoordinator.configureSoundEnabled { settingsStore.soundEnabled }
            sceneCoordinator.configureSwapHandler { from, to in
                viewModel.attemptSwap(from: from, to: to)
            }
            sceneCoordinator.render(board: viewModel.board)
            sceneCoordinator.setInteractionEnabled(
                viewModel.session.isActive && !viewModel.isPreparingBoard
            )

            AudioManager.shared.startBackgroundMusic(enabled: settingsStore.musicEnabled)
        }
        .onChange(of: settingsStore.hapticsEnabled) { _, _ in
            sceneCoordinator.configureHapticsEnabled { settingsStore.hapticsEnabled }
        }
        .onChange(of: settingsStore.soundEnabled) { _, _ in
            sceneCoordinator.configureSoundEnabled { settingsStore.soundEnabled }
        }
        .onChange(of: settingsStore.musicEnabled) { _, isEnabled in
            AudioManager.shared.refreshBackgroundMusic(enabled: isEnabled)
        }
        .task {
            await viewModel.prepareInitialBoardIfNeeded()
        }
        .onChange(of: viewModel.session.board) { _, board in
            sceneCoordinator.render(board: board)
        }
        .onChange(of: viewModel.session.isPaused) { _, _ in
            sceneCoordinator.setInteractionEnabled(
                viewModel.session.isActive && !viewModel.isPreparingBoard
            )
        }
        .onChange(of: viewModel.session.isGameOver) { _, isGameOver in
            sceneCoordinator.setInteractionEnabled(
                viewModel.session.isActive && !viewModel.isPreparingBoard
            )

            guard isGameOver else { return }

            AudioManager.shared.stopBackgroundMusic()

            if settingsStore.hapticsEnabled {
                if viewModel.session.isWin {
                    HapticsManager.notification(.success)
                } else {
                    HapticsManager.notification(.error)
                }
            }

            if viewModel.session.isWin {
                AudioManager.shared.playEffect(.win, enabled: settingsStore.soundEnabled)
            } else {
                AudioManager.shared.playEffect(.lose, enabled: settingsStore.soundEnabled)
            }
        }
        .onChange(of: viewModel.isPreparingBoard) { _, _ in
            sceneCoordinator.setInteractionEnabled(
                viewModel.session.isActive && !viewModel.isPreparingBoard
            )
        }
        .onDisappear {
            sceneCoordinator.setInteractionEnabled(false)
            AudioManager.shared.stopBackgroundMusic()
        }
    }

    @ViewBuilder
    private func gameContent(in size: CGSize, compact: Bool) -> some View {
        let isLandscape = size.width > size.height
        let spacing = compact ? 5.0 : AppSpacing.xSmall

        Group {
            if isLandscape {
                HStack(alignment: .center, spacing: spacing) {
                    boardSurface
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    sideGameBar(compact: compact)
                        .frame(
                            width: max(
                                min(size.width * 0.21, 210),
                                compact ? 150 : 172
                            )
                        )
                        .frame(maxHeight: .infinity)
                }
            } else {
                VStack(alignment: .center, spacing: spacing) {
                    topGameBar(compact: compact)

                    boardSurface
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var boardSurface: some View {
        SpriteView(
            scene: sceneCoordinator.scene,
            options: [.allowsTransparency]
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(boardAspectRatio, contentMode: .fit)
        .background {
            ArcadePanelSurface(elevated: true, cornerRadius: AppSpacing.cornerRadius)
        }
        .overlay(
            RoundedRectangle(
                cornerRadius: AppSpacing.cornerRadius,
                style: .continuous
            )
            .stroke(AppColors.arcadeBevelHighlight.opacity(0.18), lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppSpacing.cornerRadius,
                style: .continuous
            )
        )
    }

    private func topGameBar(compact: Bool) -> some View {
        let rowHeight: CGFloat = compact ? 62 : 68

        return ZStack {
            ArcadePanelSurface(
                elevated: true,
                cornerRadius: AppSpacing.cornerRadius
            )

            VStack(spacing: compact ? 4 : 6) {
                HStack(spacing: compact ? 6 : AppSpacing.xSmall) {
                    CompactHUDPill(
                        title: "Score",
                        value: "\(viewModel.session.score)",
                        detail: "Goal \(viewModel.session.targetScore)"
                    )
                    .frame(height: rowHeight)

                    CompactHUDPill(
                        title: "Moves",
                        value: "\(viewModel.session.remainingMoves)"
                    )
                    .frame(height: rowHeight)

                    CompactHUDPill(
                        title: "Time",
                        value: timeText
                    )
                    .frame(height: rowHeight)

                    compactMusicButton()
                        .frame(width: compact ? 46 : 52, height: rowHeight)

                    compactPauseButton()
                        .frame(width: compact ? 46 : 52, height: rowHeight)
                }

                if !compact {
                    Text(viewModel.statusMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, compact ? 8 : AppSpacing.small)
            .padding(.vertical, compact ? 7 : 9)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func sideGameBar(compact: Bool) -> some View {
        ZStack {
            ArcadePanelSurface(
                elevated: true,
                cornerRadius: AppSpacing.cornerRadius
            )

            VStack(alignment: .leading, spacing: compact ? 8 : AppSpacing.small) {
                Text(difficulty.displayName.uppercased())
                    .font(AppTypography.hudLabel)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)

                CompactHUDPill(
                    title: "Score",
                    value: "\(viewModel.session.score)",
                    detail: "Goal \(viewModel.session.targetScore)"
                )

                CompactHUDPill(
                    title: "Moves",
                    value: "\(viewModel.session.remainingMoves)"
                )

                CompactHUDPill(
                    title: "Time",
                    value: timeText
                )

                Text(viewModel.statusMessage)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                VStack(spacing: compact ? 8 : AppSpacing.small) {
                    compactMusicButton()
                        .frame(height: compact ? 58 : 62)

                    compactPauseButton()
                        .frame(height: compact ? 58 : 62)
                }
            }
            .padding(compact ? 8 : AppSpacing.small)
        }
    }
    private func compactMusicButton() -> some View {
        Button {
            AudioManager.shared.playEffect(.click, enabled: settingsStore.soundEnabled)
            settingsStore.musicEnabled.toggle()
        } label: {
            Image(systemName: settingsStore.musicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.title3)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    ArcadeMiniButtonSurface()
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(settingsStore.musicEnabled ? "Turn music off" : "Turn music on")
    }
    
    private func compactPauseButton() -> some View {
        Button {
            viewModel.pauseGame()
        } label: {
            MenuGlyphIcon()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    ArcadeMiniButtonSurface()
                }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.session.isPaused || viewModel.session.isGameOver || viewModel.isPreparingBoard)
        .accessibilityLabel("Open pause menu")
    }

    private func restartRound() {
        guard !viewModel.isPreparingBoard else {
            return
        }

        Task {
            await viewModel.restartGame()
        }
    }

    private func leaveGame() {
        sceneCoordinator.setInteractionEnabled(false)
        router.show(.home)
    }
}

private struct CompactHUDPill: View {
    let title: String
    let value: String
    var detail: String? = nil

    var body: some View {
        ZStack {
            ArcadeHUDPillSurface()

            Rectangle()
                .fill(AppColors.arcadeWarmEdge.opacity(0.84))
                .frame(width: 3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(AppTypography.hudLabel)
                    .foregroundStyle(Color(red: 0.58, green: 0.96, blue: 1.0).opacity(0.76))

                Text(value)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if let detail {
                    Text(detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, 11)
            .padding(.trailing, 9)
            .padding(.vertical, 7)
        }
    }
}

private struct ArcadeHUDPillSurface: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(AppColors.arcadeInk.opacity(0.92))
                .offset(y: 3)

            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.20, green: 0.27, blue: 0.62).opacity(0.96),
                            Color(red: 0.08, green: 0.17, blue: 0.44).opacity(0.98),
                            Color(red: 0.04, green: 0.06, blue: 0.20).opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.clear,
                            AppColors.arcadeWarmEdge.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(1)

            VStack(spacing: 5) {
                Color.white.opacity(0.12)
                    .frame(height: 1)

                Color.black.opacity(0.18)
                    .frame(height: 1)
            }
            .padding(.horizontal, 10)
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(AppColors.arcadeInk.opacity(0.95), lineWidth: 2)

            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(AppColors.arcadePanelGlow.opacity(0.34), lineWidth: 1)
                .padding(2)
        }
    }
}

private struct MenuGlyphIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.arcadeInk.opacity(0.76),
                            Color(red: 0.03, green: 0.05, blue: 0.16).opacity(0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == 1 ? AppColors.arcadeWarmEdge : AppColors.arcadePanelGlow)
                        .frame(width: 18, height: 3)
                        .shadow(color: AppColors.arcadePanelGlow.opacity(0.36), radius: 3)
                }
            }
        }
    }
}

private struct ArcadeMiniButtonSurface: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppColors.arcadeInk.opacity(0.86))
                .offset(y: 4)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.arcadePrimaryTop,
                            AppColors.arcadePrimaryMid,
                            AppColors.arcadePrimaryBottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 6) {
                Color.white.opacity(0.14)
                    .frame(height: 1)

                AppColors.arcadeWarmEdge.opacity(0.18)
                    .frame(height: 1)

                Color.black.opacity(0.20)
                    .frame(height: 1)
            }
            .padding(.horizontal, 8)
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(AppColors.arcadeInk.opacity(0.90), lineWidth: 2)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(AppColors.arcadeBevelHighlight.opacity(0.56), lineWidth: 1)
                .padding(2)
        }
    }
}

private struct BoardLoadingOverlay: View {
    let title: String
    let message: String? = nil

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ProgressView()
                .tint(AppColors.accentPrimary)
                .scaleEffect(1.2)

            Text(title)
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            if let message, !message.isEmpty {
                Text(message)
                    .font(AppTypography.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .fill(AppColors.backgroundGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                .stroke(AppColors.stroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 16, y: 8)
    }
}
