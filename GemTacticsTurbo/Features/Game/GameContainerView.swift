//
//  GameContainerView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SpriteKit
import SwiftUI

struct GameContainerView: View {
    @ObservedObject var router: AppRouter
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
            ScreenContainer(scrollEnabled: false) {
                GeometryReader { geometry in
                    ViewThatFits(in: .vertical) {
                        gameContent(in: geometry.size, compact: false)
                        gameContent(in: geometry.size, compact: true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Game")
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
            sceneCoordinator.configureSwapHandler { from, to in
                viewModel.attemptSwap(from: from, to: to)
            }
            sceneCoordinator.render(board: viewModel.board)
            sceneCoordinator.setInteractionEnabled(
                viewModel.session.isActive && !viewModel.isPreparingBoard
            )
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
        .onChange(of: viewModel.session.isGameOver) { _, _ in
            sceneCoordinator.setInteractionEnabled(
                viewModel.session.isActive && !viewModel.isPreparingBoard
            )
        }
        .onChange(of: viewModel.isPreparingBoard) { _, _ in
            sceneCoordinator.setInteractionEnabled(
                viewModel.session.isActive && !viewModel.isPreparingBoard
            )
        }
        .onDisappear {
            sceneCoordinator.setInteractionEnabled(false)
        }
    }

    @ViewBuilder
    private func gameContent(in size: CGSize, compact: Bool) -> some View {
        let isLandscape = size.width > size.height
        let spacing = compact ? AppSpacing.small : AppSpacing.medium
        let boardHeightRatio: CGFloat = compact ? 0.40 : 0.50

        Group {
            if isLandscape {
                HStack(alignment: .top, spacing: spacing) {
                    VStack(alignment: .leading, spacing: spacing) {
                        gameHeader(compact: compact)
                        hudGrid
                        statusPanel
                        controlStack(isLandscape: true)
                        Spacer(minLength: 0)
                    }
                    .frame(width: max(min(size.width * 0.34, 360), 280), alignment: .topLeading)

                    boardSurface
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack(alignment: .leading, spacing: spacing) {
                    gameHeader(compact: compact)
                    hudGrid

                    boardSurface
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: size.height * boardHeightRatio)

                    statusPanel
                    controlStack(isLandscape: false)
                    Spacer(minLength: 0)
                }
            }
        }
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

    private func gameHeader(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            Text(difficulty.displayName)
                .font(compact ? AppTypography.bodyStrong : AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text("Focused board play with the HUD kept readable and tight.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var hudGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppSpacing.small),
                GridItem(.flexible(), spacing: AppSpacing.small)
            ],
            spacing: AppSpacing.small
        ) {
            GameHUDTile(
                title: "Score",
                value: "\(viewModel.session.score)",
                detail: "Goal \(viewModel.session.targetScore)"
            )

            GameHUDTile(
                title: "Moves",
                value: "\(viewModel.session.remainingMoves)"
            )

            GameHUDTile(
                title: "Time",
                value: timeText
            )

            SecondaryButton(title: viewModel.session.isPaused ? "Paused" : "Pause") {
                viewModel.pauseGame()
            }
            .disabled(viewModel.session.isPaused || viewModel.session.isGameOver || viewModel.isPreparingBoard)
        }
    }

    private var statusPanel: some View {
        GlassPanel {
            Text(viewModel.statusMessage)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
        }
    }

    private func controlStack(isLandscape: Bool) -> some View {
        Group {
            if isLandscape {
                VStack(spacing: AppSpacing.medium) {
                    SecondaryButton(title: "Restart") {
                        restartRound()
                    }
                    .disabled(viewModel.isPreparingBoard)

                    PrimaryButton(title: "Home") {
                        leaveGame()
                    }
                }
            } else {
                HStack(spacing: AppSpacing.medium) {
                    SecondaryButton(title: "Restart") {
                        restartRound()
                    }
                    .disabled(viewModel.isPreparingBoard)
                    .frame(maxWidth: .infinity)

                    PrimaryButton(title: "Home") {
                        leaveGame()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
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

private struct GameHUDTile: View {
    let title: String
    let value: String
    var detail: String? = nil

    var body: some View {
        ZStack {
            ArcadePanelSurface(cornerRadius: AppSpacing.cornerRadius)

            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(AppTypography.hudLabel)
                    .foregroundStyle(AppColors.textMuted)

                Text(value)
                    .font(AppTypography.hudValue)
                    .foregroundStyle(AppColors.textPrimary)

                if let detail {
                    Text(detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
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
