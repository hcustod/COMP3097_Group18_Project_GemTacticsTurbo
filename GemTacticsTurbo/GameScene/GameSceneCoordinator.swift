//
//  GameSceneCoordinator.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import CoreGraphics
import Foundation

@MainActor
final class GameSceneCoordinator: ObservableObject {
    let scene: GameScene

    private var swapHandler: ((BoardPosition, BoardPosition) -> GameViewModel.SwapFeedback)?
    private var hapticsEnabled: () -> Bool = { true }
    private var desiredInteractionState = true
    private var isAnimatingSwap = false
    private var pendingBoard: GameSession.Board?

    private enum PendingSwapHaptic {
        case none
        case validMatch
        case invalidSwap
    }

    private var pendingSwapHaptic: PendingSwapHaptic = .none

    init(board: GameSession.Board? = nil) {
        let scene = GameScene(size: Self.sceneSize(for: board))
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

    func configureHapticsEnabled(_ provider: @escaping () -> Bool) {
        hapticsEnabled = provider
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
            pendingSwapHaptic = .validMatch
            scene.animateValidSwap(
                swap,
                swappedBoard: feedback.swappedBoard ?? feedback.resultingBoard,
                cascadeSteps: feedback.cascadeSteps,
                finalBoard: feedback.resultingBoard
            ) { [weak self] in
                Task { @MainActor [weak self] in
                    self?.finishSwapAnimation(currentBoard: feedback.resultingBoard)
                }
            }
            return
        }

        pendingSwapHaptic = .invalidSwap
        scene.animateInvalidSwap(swap) { [weak self] in
            Task { @MainActor [weak self] in
                self?.finishSwapAnimation(currentBoard: nil)
            }
        }
    }

    private func finishSwapAnimation(currentBoard: GameSession.Board?) {
        isAnimatingSwap = false

        if hapticsEnabled() {
            switch pendingSwapHaptic {
            case .validMatch:
                HapticsManager.impact(.medium)
            case .invalidSwap:
                HapticsManager.impact(.light)
            case .none:
                break
            }
        }
        pendingSwapHaptic = .none

        if let pendingBoard, pendingBoard != currentBoard {
            scene.render(board: pendingBoard)
        }

        self.pendingBoard = nil
        scene.isBoardInteractionEnabled = desiredInteractionState
    }

    private static func sceneSize(for board: GameSession.Board?) -> CGSize {
        let rowCount = max(board?.count ?? GameSession.defaultRowCount, 1)
        let columnCount = max(board?.first?.count ?? GameSession.defaultColumnCount, 1)
        let baseCell: CGFloat = 140
        return CGSize(
            width: CGFloat(columnCount) * baseCell,
            height: CGFloat(rowCount) * baseCell
        )
    }
}
