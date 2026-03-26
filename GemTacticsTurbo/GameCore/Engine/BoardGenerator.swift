//
//  BoardGenerator.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

enum BoardGenerator {
    static func generate(rows: Int = 8, columns: Int = 8) -> GameSession.Board {
        var gemSource = SystemRandomGemSource()
        return generate(rows: rows, columns: columns, using: &gemSource)
    }

    static func generate<Source: GemSource>(
        rows: Int = 8,
        columns: Int = 8,
        using gemSource: inout Source
    ) -> GameSession.Board {
        guard rows > 0, columns > 0 else {
            return []
        }

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

