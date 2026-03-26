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

    private var gameSubtitle: String {
        "SpriteKit now renders the board and handles tile selection, while the view model remains responsible for validating swaps and updating the round."
    }

    private var scoreMultiplierText: String {
        String(format: "%.1f", difficulty.scoreMultiplier)
    }

    private var timeText: String {
        let minutes = viewModel.session.remainingTime / 60
        let seconds = viewModel.session.remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
                title: "\(difficulty.displayName) Match",
                subtitle: gameSubtitle
            ) {
                SectionHeader(
                    title: "HUD",
                    subtitle: "Pause, timer, score, and move state stay in SwiftUI while the scene handles gem selection and swap attempts."
                )

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: AppSpacing.medium),
                        GridItem(.flexible(), spacing: AppSpacing.medium)
                    ],
                    spacing: AppSpacing.medium
                ) {
                    StatCard(
                        title: "Score",
                        value: "\(viewModel.session.score)",
                        detail: "Target: \(viewModel.session.targetScore)"
                    )

                    StatCard(
                        title: "Moves",
                        value: "\(viewModel.session.remainingMoves)",
                        detail: "Multiplier: \(scoreMultiplierText)x"
                    )

                    StatCard(
                        title: "Timer",
                        value: timeText,
                        detail: "Combo Chain: \(viewModel.session.comboChain)"
                    )

                    hudButton
                }

                SectionHeader(
                    title: "Board",
                    subtitle: "Tap one gem, then tap an adjacent gem to swap. Tap the same gem again to cancel the selection."
                )

                SpriteView(
                    scene: sceneCoordinator.scene,
                    options: [.allowsTransparency]
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(AppColors.surface)
                .overlay(
                    RoundedRectangle(
                        cornerRadius: AppSpacing.cornerRadius,
                        style: .continuous
                    )
                    .stroke(AppColors.stroke, lineWidth: 1)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppSpacing.cornerRadius,
                        style: .continuous
                    )
                )

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(viewModel.statusMessage)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)

                    Text("Current board: \(viewModel.session.rowCount)x\(viewModel.session.columnCount) grid with SpriteKit touch mapping enabled.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                HStack(spacing: AppSpacing.medium) {
                    SecondaryButton(title: "Restart") {
                        viewModel.restartGame()
                    }
                }

                PrimaryButton(title: "Back to Home") {
                    router.show(.home)
                }
            }
            .navigationTitle("Game")
            .navigationBarTitleDisplayMode(.inline)

            if viewModel.session.isPaused && !viewModel.session.isGameOver {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                PauseOverlayView(
                    onResume: {
                        viewModel.resumeGame()
                    },
                    onRestart: {
                        viewModel.restartGame()
                    },
                    onQuit: {
                        router.show(.home)
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
                        viewModel.restartGame()
                    },
                    onHome: {
                        router.show(.home)
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
            sceneCoordinator.setInteractionEnabled(viewModel.session.isActive)
        }
        .onChange(of: viewModel.session.board) { _, board in
            sceneCoordinator.render(board: board)
        }
        .onChange(of: viewModel.session.isPaused) { _, _ in
            sceneCoordinator.setInteractionEnabled(viewModel.session.isActive)
        }
        .onChange(of: viewModel.session.isGameOver) { _, _ in
            sceneCoordinator.setInteractionEnabled(viewModel.session.isActive)
        }
    }

    @ViewBuilder
    private var hudButton: some View {
        Group {
            SecondaryButton(title: viewModel.session.isPaused ? "Paused" : "Pause") {
                viewModel.pauseGame()
            }
            .disabled(viewModel.session.isPaused || viewModel.session.isGameOver)
        }
    }
}
