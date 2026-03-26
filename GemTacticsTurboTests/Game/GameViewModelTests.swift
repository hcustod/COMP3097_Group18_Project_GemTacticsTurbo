//
//  GameViewModelTests.swift
//  GemTacticsTurboTests
//
//  Created by Henrique Custodio on 3/26/26.
//

import XCTest
@testable import GemTacticsTurbo

@MainActor
final class GameViewModelTests: XCTestCase {
    func testStartGameUsesDifficultyValuesAndInitialBoard() {
        let engine = TestBoardEngine(
            initialBoard: makeBoard([
                [.ruby, .sapphire],
                [.emerald, .topaz]
            ])
        )

        let viewModel = GameViewModel(
            difficulty: .medium,
            boardEngine: engine
        )

        XCTAssertEqual(viewModel.session.board, engine.initialBoard)
        XCTAssertEqual(viewModel.session.remainingMoves, Difficulty.medium.moveLimit)
        XCTAssertEqual(viewModel.session.remainingTime, Difficulty.medium.timeLimit)
        XCTAssertEqual(viewModel.session.targetScore, Difficulty.medium.targetScore)
        XCTAssertFalse(viewModel.session.isGameOver)
    }

    func testValidSwapConsumesMoveAndAddsScore() {
        let initialBoard = makeBoard([
            [.ruby, .sapphire],
            [.emerald, .topaz]
        ])
        let resolvedBoard = makeBoard([
            [.sapphire, .ruby],
            [.emerald, .topaz]
        ])
        let engine = TestBoardEngine(
            initialBoard: initialBoard,
            moveResults: [
                BoardEngine.MoveResult(
                    board: resolvedBoard,
                    wasValid: true,
                    scoreGained: 450,
                    comboChain: 2,
                    totalMatchGroups: 3
                )
            ]
        )

        let viewModel = GameViewModel(
            difficulty: .easy,
            boardEngine: engine
        )
        let startingMoves = viewModel.session.remainingMoves

        viewModel.attemptSwap(
            from: BoardPosition(row: 0, column: 0),
            to: BoardPosition(row: 0, column: 1)
        )

        XCTAssertEqual(viewModel.session.board, resolvedBoard)
        XCTAssertEqual(viewModel.session.remainingMoves, startingMoves - 1)
        XCTAssertEqual(viewModel.session.score, 450)
        XCTAssertEqual(viewModel.session.comboChain, 2)
        XCTAssertEqual(engine.recordedSwaps.count, 1)
    }

    func testInvalidSwapDoesNotConsumeMove() {
        let initialBoard = makeBoard([
            [.ruby, .sapphire],
            [.emerald, .topaz]
        ])
        let engine = TestBoardEngine(
            initialBoard: initialBoard,
            moveResults: [
                BoardEngine.MoveResult(
                    board: initialBoard,
                    wasValid: false,
                    scoreGained: 0,
                    comboChain: 0,
                    totalMatchGroups: 0
                )
            ]
        )

        let viewModel = GameViewModel(
            difficulty: .easy,
            boardEngine: engine
        )
        let startingMoves = viewModel.session.remainingMoves

        viewModel.attemptSwap(
            from: BoardPosition(row: 0, column: 0),
            to: BoardPosition(row: 1, column: 1)
        )

        XCTAssertEqual(viewModel.session.board, initialBoard)
        XCTAssertEqual(viewModel.session.remainingMoves, startingMoves)
        XCTAssertEqual(viewModel.session.score, 0)
        XCTAssertEqual(viewModel.session.comboChain, 0)
    }

    func testPauseAndResumeControlTimerTick() {
        let engine = TestBoardEngine(
            initialBoard: makeBoard([
                [.ruby, .sapphire],
                [.emerald, .topaz]
            ])
        )

        let viewModel = GameViewModel(
            difficulty: .hard,
            boardEngine: engine
        )
        let startingTime = viewModel.session.remainingTime

        viewModel.pauseGame()
        viewModel.processTimerTick()
        XCTAssertEqual(viewModel.session.remainingTime, startingTime)

        viewModel.resumeGame()
        viewModel.processTimerTick()
        XCTAssertEqual(viewModel.session.remainingTime, startingTime - 1)
    }

    func testReachingTargetScoreEndsGameAsWin() {
        let initialBoard = makeBoard([
            [.ruby, .sapphire],
            [.emerald, .topaz]
        ])
        let engine = TestBoardEngine(
            initialBoard: initialBoard,
            moveResults: [
                BoardEngine.MoveResult(
                    board: initialBoard,
                    wasValid: true,
                    scoreGained: Difficulty.easy.targetScore,
                    comboChain: 1,
                    totalMatchGroups: 2
                )
            ]
        )

        let viewModel = GameViewModel(
            difficulty: .easy,
            boardEngine: engine
        )

        viewModel.attemptSwap(
            from: BoardPosition(row: 0, column: 0),
            to: BoardPosition(row: 0, column: 1)
        )

        XCTAssertTrue(viewModel.session.isGameOver)
        XCTAssertTrue(viewModel.session.isWin)
        XCTAssertEqual(viewModel.session.score, Difficulty.easy.targetScore)
    }

    func testTimerExpirationEndsGameAsLoss() {
        let engine = TestBoardEngine(
            initialBoard: makeBoard([
                [.ruby, .sapphire],
                [.emerald, .topaz]
            ])
        )

        let viewModel = GameViewModel(
            difficulty: .hard,
            boardEngine: engine
        )

        for _ in 0..<Difficulty.hard.timeLimit {
            viewModel.processTimerTick()
        }

        XCTAssertTrue(viewModel.session.isGameOver)
        XCTAssertFalse(viewModel.session.isWin)
        XCTAssertEqual(viewModel.session.remainingTime, 0)
    }

    private func makeBoard(_ rows: [[GemType]]) -> GameSession.Board {
        rows.map { row in
            row.map(Optional.some)
        }
    }
}

private final class TestBoardEngine: BoardEngineing {
    let initialBoard: GameSession.Board
    var moveResults: [BoardEngine.MoveResult]
    private(set) var recordedSwaps: [Swap] = []

    init(
        initialBoard: GameSession.Board,
        moveResults: [BoardEngine.MoveResult] = []
    ) {
        self.initialBoard = initialBoard
        self.moveResults = moveResults
    }

    func makeInitialBoard() -> GameSession.Board {
        initialBoard
    }

    func resolveSwap(
        _ swap: Swap,
        on board: GameSession.Board,
        difficulty: Difficulty
    ) -> BoardEngine.MoveResult {
        recordedSwaps.append(swap)

        if moveResults.isEmpty {
            return BoardEngine.MoveResult(
                board: board,
                wasValid: false,
                scoreGained: 0,
                comboChain: 0,
                totalMatchGroups: 0
            )
        }

        return moveResults.removeFirst()
    }
}
