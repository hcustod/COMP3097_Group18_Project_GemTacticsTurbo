//
//  BoardGenerator.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

enum BoardGenerator {
    struct RepairResult: Equatable, Sendable {
        let board: GameSession.Board
        let availableSwapCount: Int
        let wasRepaired: Bool
        let metMinimumSwapRequirement: Bool
    }

    static let minimumPlayableSwaps = 2
    static let maximumPlayableBoardAttempts = 256

    static func generate(
        rows: Int = GameSession.defaultRowCount,
        columns: Int = GameSession.defaultColumnCount
    ) -> GameSession.Board {
        var gemSource = SystemRandomGemSource()
        return generate(
            rows: rows,
            columns: columns,
            minimumValidSwaps: minimumPlayableSwaps,
            using: &gemSource
        )
    }

    static func generate<Source: GemSource>(
        rows: Int = GameSession.defaultRowCount,
        columns: Int = GameSession.defaultColumnCount,
        minimumValidSwaps: Int = minimumPlayableSwaps,
        maximumAttempts: Int = maximumPlayableBoardAttempts,
        using gemSource: inout Source
    ) -> GameSession.Board {
        guard rows > 0, columns > 0 else {
            return []
        }

        let requiredSwaps = max(1, minimumValidSwaps)
        let generationAttempts = max(1, maximumAttempts)
        var fallbackBoard = generateCandidateBoard(
            rows: rows,
            columns: columns,
            using: &gemSource
        )
        var fallbackSwapCount = BoardMoveAnalyzer.countValidSwaps(
            on: fallbackBoard,
            upTo: requiredSwaps
        )

        if fallbackSwapCount >= requiredSwaps {
            return fallbackBoard
        }

        for _ in 1..<generationAttempts {
            let candidateBoard = generateCandidateBoard(
                rows: rows,
                columns: columns,
                using: &gemSource
            )
            let candidateSwapCount = BoardMoveAnalyzer.countValidSwaps(
                on: candidateBoard,
                upTo: requiredSwaps
            )

            if candidateSwapCount >= requiredSwaps {
                return candidateBoard
            }

            if candidateSwapCount > fallbackSwapCount {
                fallbackBoard = candidateBoard
                fallbackSwapCount = candidateSwapCount
            }
        }

        return fallbackBoard
    }

    static func repairPlayability(
        for board: GameSession.Board
    ) -> RepairResult {
        var gemSource = SystemRandomGemSource()
        return repairPlayability(for: board, using: &gemSource)
    }

    static func repairPlayability<Source: GemSource>(
        for board: GameSession.Board,
        minimumValidSwaps: Int = minimumPlayableSwaps,
        maximumAttempts: Int = maximumPlayableBoardAttempts,
        using gemSource: inout Source
    ) -> RepairResult {
        let requiredSwaps = max(1, minimumValidSwaps)
        let currentSwapCount = BoardMoveAnalyzer.countValidSwaps(
            on: board,
            upTo: requiredSwaps
        )

        if currentSwapCount >= requiredSwaps {
            return RepairResult(
                board: board,
                availableSwapCount: currentSwapCount,
                wasRepaired: false,
                metMinimumSwapRequirement: true
            )
        }

        let rowCount = board.count
        let columnCount = board.first?.count ?? 0
        guard rowCount > 0, columnCount > 0 else {
            return RepairResult(
                board: board,
                availableSwapCount: 0,
                wasRepaired: false,
                metMinimumSwapRequirement: false
            )
        }

        let repairedBoard = generate(
            rows: rowCount,
            columns: columnCount,
            minimumValidSwaps: requiredSwaps,
            maximumAttempts: maximumAttempts,
            using: &gemSource
        )
        let repairedSwapCount = BoardMoveAnalyzer.countValidSwaps(
            on: repairedBoard,
            upTo: requiredSwaps
        )

        return RepairResult(
            board: repairedBoard,
            availableSwapCount: repairedSwapCount,
            wasRepaired: repairedBoard != board,
            metMinimumSwapRequirement: repairedSwapCount >= requiredSwaps
        )
    }

    private static func generateCandidateBoard<Source: GemSource>(
        rows: Int,
        columns: Int,
        using gemSource: inout Source
    ) -> GameSession.Board {
        var board = GameSession.emptyBoard(rows: rows, columns: columns)

        for row in 0..<rows {
            for column in 0..<columns {
                board[row][column] = nextGem(
                    for: BoardPosition(row: row, column: column),
                    on: board,
                    using: &gemSource
                )
            }
        }

        return board
    }

    private static func nextGem<Source: GemSource>(
        for position: BoardPosition,
        on board: GameSession.Board,
        using gemSource: inout Source
    ) -> GemType {
        let maximumAttempts = GemType.allCases.count * 4

        for _ in 0..<maximumAttempts {
            let candidate = gemSource.nextGem()

            if !createsImmediateMatch(candidate, at: position, on: board) {
                return candidate
            }
        }

        return GemType.allCases.first {
            !createsImmediateMatch($0, at: position, on: board)
        } ?? .ruby
    }

    private static func createsImmediateMatch(
        _ gemType: GemType,
        at position: BoardPosition,
        on board: GameSession.Board
    ) -> Bool {
        let row = position.row
        let column = position.column

        if column >= 2,
           board[row][column - 1] == gemType,
           board[row][column - 2] == gemType {
            return true
        }

        if row >= 2,
           board[row - 1][column] == gemType,
           board[row - 2][column] == gemType {
            return true
        }

        return false
    }
}
