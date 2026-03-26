//
//  MatchDetector.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

enum MatchDetector {
    static func findMatches(on board: GameSession.Board) -> [Match] {
        guard !board.isEmpty else {
            return []
        }

        let horizontalMatches = findHorizontalMatches(on: board)
        let verticalMatches = findVerticalMatches(on: board)
        return horizontalMatches + verticalMatches
    }

    private static func findHorizontalMatches(on board: GameSession.Board) -> [Match] {
        let rowCount = board.count
        let columnCount = board.first?.count ?? 0
        var matches: [Match] = []

        for row in 0..<rowCount {
            var column = 0

            while column < columnCount {
                guard let gemType = board[row][column] else {
                    column += 1
                    continue
                }

                var endColumn = column + 1

                while endColumn < columnCount, board[row][endColumn] == gemType {
                    endColumn += 1
                }

                if endColumn - column >= 3 {
                    let positions = (column..<endColumn).map {
                        BoardPosition(row: row, column: $0)
                    }
                    matches.append(Match(positions: positions, gemType: gemType))
                }

                column = endColumn
            }
        }

        return matches
    }

    private static func findVerticalMatches(on board: GameSession.Board) -> [Match] {
        let rowCount = board.count
        let columnCount = board.first?.count ?? 0
        var matches: [Match] = []

        for column in 0..<columnCount {
            var row = 0

            while row < rowCount {
                guard let gemType = board[row][column] else {
                    row += 1
                    continue
                }

                var endRow = row + 1

                while endRow < rowCount, board[endRow][column] == gemType {
                    endRow += 1
                }

                if endRow - row >= 3 {
                    let positions = (row..<endRow).map {
                        BoardPosition(row: $0, column: column)
                    }
                    matches.append(Match(positions: positions, gemType: gemType))
                }

                row = endRow
            }
        }

        return matches
    }
}

