//
//  GameSceneCoordinator.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import Foundation

@MainActor
final class GameSceneCoordinator: ObservableObject {
    let scene: GameScene

    private var swapHandler: ((BoardPosition, BoardPosition) -> GameViewModel.SwapFeedback)?
    private var desiredInteractionState = true
    private var isAnimatingSwap = false
    private var pendingBoard: GameSession.Board?

    init(board: GameSession.Board? = nil) {
        let scene = GameScene(size: CGSize(width: 640, height: 640))
        self.scene = scene
        scene.render(board: board ?? GameSession.emptyBoard())
        scene.onSwapRequested = { [weak self] swap in
            Task { @MainActor [weak self] in
                self?.handleSwapRequest(swap)
            }
        }
    }

    func configureSwapHandler(
        _ swapHandler: @escaping (BoardPosition, BoardPosition) -> GameViewModel.SwapFeedback
    ) {
        self.swapHandler = swapHandler
    }

    func render(board: GameSession.Board) {
        if isAnimatingSwap {
            pendingBoard = board
            return
        }

        scene.render(board: board)
    }

    func setInteractionEnabled(_ isEnabled: Bool) {
        desiredInteractionState = isEnabled

        guard !isAnimatingSwap else {
            return
        }

        scene.isBoardInteractionEnabled = isEnabled
    }

    private func handleSwapRequest(_ swap: Swap) {
        guard let swapHandler else {
            return
        }

        let feedback = swapHandler(swap.source, swap.destination)

        guard feedback.wasProcessed else {
            scene.isBoardInteractionEnabled = desiredInteractionState
            return
        }

        isAnimatingSwap = true
        scene.isBoardInteractionEnabled = false

        if feedback.wasValid {
            scene.animateValidSwap(
                swap,
                updatedBoard: feedback.resultingBoard
            ) { [weak self] in
                Task { @MainActor [weak self] in
                    self?.finishSwapAnimation(currentBoard: feedback.resultingBoard)
                }
            }
            return
        }

        scene.animateInvalidSwap(swap) { [weak self] in
            Task { @MainActor [weak self] in
                self?.finishSwapAnimation(currentBoard: nil)
            }
        }
    }

    private func finishSwapAnimation(currentBoard: GameSession.Board?) {
        isAnimatingSwap = false

        if let pendingBoard, pendingBoard != currentBoard {
            scene.render(board: pendingBoard)
        }

        self.pendingBoard = nil
        scene.isBoardInteractionEnabled = desiredInteractionState
    }
}
