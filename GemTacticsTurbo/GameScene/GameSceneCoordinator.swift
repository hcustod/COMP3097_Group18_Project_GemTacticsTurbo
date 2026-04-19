//
//  GameSceneCoordinator.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import CoreGraphics
import Foundation
import UIKit

@MainActor
final class GameSceneCoordinator: ObservableObject {
    let scene: GameScene

    private var swapHandler: ((BoardPosition, BoardPosition) -> GameViewModel.SwapFeedback)?
    private var hapticsEnabled: () -> Bool = { true }
    private var soundEnabled: () -> Bool = { true }
    private var desiredInteractionState = true
    private var isAnimatingSwap = false
    private var pendingBoard: GameSession.Board?

    private enum PendingSwapHaptic {
        case none
        case validMatch
        case invalidSwap
    }

    private enum PendingSwapSound {
        case none
        case validMatch
        case invalidSwap
    }

    private var pendingSwapHaptic: PendingSwapHaptic = .none
    private var pendingSwapSound: PendingSwapSound = .none

    init(board: GameSession.Board? = nil) {
        let scene = GameScene(size: Self.sceneSize(for: board))
        self.scene = scene
        scene.render(board: board ?? GameSession.emptyBoard())
        // SpriteKit sends swap requests here, then SwiftUI/GameViewModel decides the result.
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

    func configureSoundEnabled(_ provider: @escaping () -> Bool) {
        soundEnabled = provider
    }

    func render(board: GameSession.Board) {
        // If an animation is mid-flight, wait and draw the newest board after it ends.
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

        // Ask the view model if the swap is valid before animating anything.
        let feedback = swapHandler(swap.source, swap.destination)

        guard feedback.wasProcessed else {
            scene.isBoardInteractionEnabled = desiredInteractionState
            return
        }

        isAnimatingSwap = true
        scene.isBoardInteractionEnabled = false

        if feedback.wasValid {
            AudioManager.shared.playEffect(.swap, enabled: soundEnabled())
            pendingSwapHaptic = .validMatch
            pendingSwapSound = .validMatch
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
        pendingSwapSound = .invalidSwap
        scene.animateInvalidSwap(swap) { [weak self] in
            Task { @MainActor [weak self] in
                self?.finishSwapAnimation(currentBoard: nil)
            }
        }
    }

    private func finishSwapAnimation(currentBoard: GameSession.Board?) {
        isAnimatingSwap = false

        // Haptic style depends on whether the attempted swap actually matched.
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

        switch pendingSwapSound {
        case .validMatch:
            AudioManager.shared.playEffect(.match, enabled: soundEnabled())
        case .invalidSwap:
            AudioManager.shared.playEffect(.invalid, enabled: soundEnabled())
        case .none:
            break
        }

        pendingSwapHaptic = .none
        pendingSwapSound = .none

        if let pendingBoard, pendingBoard != currentBoard {
            scene.render(board: pendingBoard)
        }

        self.pendingBoard = nil
        scene.isBoardInteractionEnabled = desiredInteractionState
    }

    private static func sceneSize(for board: GameSession.Board?) -> CGSize {
        // Scene scales with board dimensions so tile spacing stays predictable.
        let rowCount = max(board?.count ?? GameSession.defaultRowCount, 1)
        let columnCount = max(board?.first?.count ?? GameSession.defaultColumnCount, 1)
        let baseCell: CGFloat = 140
        return CGSize(
            width: CGFloat(columnCount) * baseCell,
            height: CGFloat(rowCount) * baseCell
        )
    }
}
