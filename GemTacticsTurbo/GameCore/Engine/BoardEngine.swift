//
//  BoardEngine.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

protocol BoardEngineing {
    func makeInitialBoard() -> GameSession.Board
    func resolveSwap(
        _ swap: Swap,
        on board: GameSession.Board,
        difficulty: Difficulty
    ) -> BoardEngine.MoveResult
}

struct BoardEngine: BoardEngineing, Sendable {
    struct MoveResult: Equatable, Sendable {
        let board: GameSession.Board
        let wasValid: Bool
        let scoreGained: Int
        let comboChain: Int
        let totalMatchGroups: Int
        let availableSwapCount: Int
        let boardWasRepaired: Bool
        let metPlayabilityThreshold: Bool
        let boardAfterSwap: GameSession.Board?
        let cascadeSteps: [CascadeResolver.Step]

        init(
            board: GameSession.Board,
            wasValid: Bool,
            scoreGained: Int,
            comboChain: Int,
            totalMatchGroups: Int,
            availableSwapCount: Int = 0,
            boardWasRepaired: Bool = false,
            metPlayabilityThreshold: Bool = true,
            boardAfterSwap: GameSession.Board? = nil,
            cascadeSteps: [CascadeResolver.Step] = []
        ) {
            self.board = board
            self.wasValid = wasValid
            self.scoreGained = scoreGained
            self.comboChain = comboChain
            self.totalMatchGroups = totalMatchGroups
            self.availableSwapCount = availableSwapCount
            self.boardWasRepaired = boardWasRepaired
            self.metPlayabilityThreshold = metPlayabilityThreshold
            self.boardAfterSwap = boardAfterSwap
            self.cascadeSteps = cascadeSteps
        }
    }

    let rows: Int
    let columns: Int

    init(
        rows: Int = GameSession.defaultRowCount,
        columns: Int = GameSession.defaultColumnCount
    ) {
        self.rows = rows
        self.columns = columns
    }

    func makeInitialBoard() -> GameSession.Board {
        BoardGenerator.generate(rows: rows, columns: columns)
    }

    func resolveSwap(
        _ swap: Swap,
        on board: GameSession.Board,
        difficulty: Difficulty
    ) -> MoveResult {
        guard SwapValidator.isValid(swap, on: board) else {
            return MoveResult(
                board: board,
                wasValid: false,
                scoreGained: 0,
                comboChain: 0,
                totalMatchGroups: 0
            )
        }

        let swappedBoard = SwapValidator.applying(swap, to: board)
        let cascadeResult = CascadeResolver.resolve(
            board: swappedBoard,
            difficulty: difficulty
        )
        let playabilityRepair = BoardGenerator.repairPlayability(
            for: cascadeResult.board
        )

        return MoveResult(
            board: playabilityRepair.board,
            wasValid: true,
            scoreGained: cascadeResult.totalScore,
            comboChain: cascadeResult.comboChain,
            totalMatchGroups: cascadeResult.totalMatchGroups,
            availableSwapCount: playabilityRepair.availableSwapCount,
            boardWasRepaired: playabilityRepair.wasRepaired,
            metPlayabilityThreshold: playabilityRepair.metMinimumSwapRequirement,
            boardAfterSwap: swappedBoard,
            cascadeSteps: cascadeResult.steps
        )
    }
}
