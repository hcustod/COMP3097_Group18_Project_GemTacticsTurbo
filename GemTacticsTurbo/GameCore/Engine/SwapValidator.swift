//
//  SwapValidator.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

enum SwapValidator {
    static func areAdjacent(_ first: BoardPosition, _ second: BoardPosition) -> Bool {
        let rowDistance = abs(first.row - second.row)
        let columnDistance = abs(first.column - second.column)

        return rowDistance + columnDistance == 1
    }

    static func isValid(_ swap: Swap, on board: GameSession.Board) -> Bool {
        guard areAdjacent(swap.source, swap.destination) else {
            return false
        }

        guard contains(swap.source, in: board), contains(swap.destination, in: board) else {
            return false
        }

        guard board[swap.source.row][swap.source.column] != nil,
              board[swap.destination.row][swap.destination.column] != nil else {
            return false
        }

        let swappedBoard = applying(swap, to: board)
        return !MatchDetector.findMatches(on: swappedBoard).isEmpty
    }

    static func applying(_ swap: Swap, to board: GameSession.Board) -> GameSession.Board {
        guard contains(swap.source, in: board), contains(swap.destination, in: board) else {
            return board
        }

        var updatedBoard = board
        let sourceGem = updatedBoard[swap.source.row][swap.source.column]
        updatedBoard[swap.source.row][swap.source.column] = updatedBoard[swap.destination.row][swap.destination.column]
        updatedBoard[swap.destination.row][swap.destination.column] = sourceGem
        return updatedBoard
    }

    private static func contains(_ position: BoardPosition, in board: GameSession.Board) -> Bool {
        guard position.row >= 0, position.column >= 0 else {
            return false
        }

        guard position.row < board.count else {
            return false
        }

        return position.column < (board.first?.count ?? 0)
    }
}

