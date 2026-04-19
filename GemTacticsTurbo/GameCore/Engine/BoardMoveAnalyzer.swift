//
//  BoardMoveAnalyzer.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 4/1/26.
//

enum BoardMoveAnalyzer {
    static func validSwaps(on board: GameSession.Board) -> [Swap] {
        let rowCount = board.count
        let columnCount = board.first?.count ?? 0
        guard rowCount > 0, columnCount > 0 else {
            return []
        }

        var swaps: [Swap] = []

        for row in 0..<rowCount {
            for column in 0..<columnCount {
                let source = BoardPosition(row: row, column: column)

                guard board[row][column] != nil else {
                    continue
                }

                for destination in adjacentDestinations(for: source, rowCount: rowCount, columnCount: columnCount) {
                    let swap = Swap(source: source, destination: destination)

                    if SwapValidator.isValid(swap, on: board) {
                        swaps.append(swap)
                    }
                }
            }
        }

        return swaps
    }

    static func countValidSwaps(
        on board: GameSession.Board,
        upTo limit: Int? = nil
    ) -> Int {
        let rowCount = board.count
        let columnCount = board.first?.count ?? 0
        guard rowCount > 0, columnCount > 0 else {
            return 0
        }

        let cappedLimit = limit.map { max($0, 0) }
        var count = 0

        for row in 0..<rowCount {
            for column in 0..<columnCount {
                let source = BoardPosition(row: row, column: column)

                guard board[row][column] != nil else {
                    continue
                }

                for destination in adjacentDestinations(for: source, rowCount: rowCount, columnCount: columnCount) {
                    let swap = Swap(source: source, destination: destination)

                    if SwapValidator.isValid(swap, on: board) {
                        count += 1

                        if let cappedLimit, count >= cappedLimit {
                            return count
                        }
                    }
                }
            }
        }

        return count
    }

    static func hasAtLeastValidSwaps(
        _ minimum: Int,
        on board: GameSession.Board
    ) -> Bool {
        guard minimum > 0 else {
            return true
        }

        return countValidSwaps(on: board, upTo: minimum) >= minimum
    }

    private static func adjacentDestinations(
        for source: BoardPosition,
        rowCount: Int,
        columnCount: Int
    ) -> [BoardPosition] {
        var destinations: [BoardPosition] = []

        if source.column + 1 < columnCount {
            destinations.append(BoardPosition(row: source.row, column: source.column + 1))
        }

        if source.row + 1 < rowCount {
            destinations.append(BoardPosition(row: source.row + 1, column: source.column))
        }

        return destinations
    }
}
