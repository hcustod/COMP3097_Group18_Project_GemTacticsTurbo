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
    }

    let rows: Int
    let columns: Int

    init(rows: Int = 8, columns: Int = 8) {
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

        return MoveResult(
            board: cascadeResult.board,
            wasValid: true,
            scoreGained: cascadeResult.totalScore,
            comboChain: cascadeResult.comboChain,
            totalMatchGroups: cascadeResult.totalMatchGroups
        )
    }
}
