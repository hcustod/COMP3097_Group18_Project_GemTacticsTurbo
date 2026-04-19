//
//  CascadeResolver.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

enum CascadeResolver {
    struct Step: Equatable, Sendable {
        let depth: Int
        let matches: [Match]
        let clearedPositions: Set<BoardPosition>
        let scoreGained: Int
        let boardAfterClear: GameSession.Board
        let boardAfterGravity: GameSession.Board
        let boardAfterRefill: GameSession.Board
    }

    struct Result: Equatable, Sendable {
        let board: GameSession.Board
        let steps: [Step]
        let totalScore: Int

        var comboChain: Int {
            steps.count
        }

        var totalClearedGems: Int {
            steps.reduce(0) { partialResult, step in
                partialResult + step.clearedPositions.count
            }
        }

        var totalMatchGroups: Int {
            steps.reduce(0) { partialResult, step in
                partialResult + step.matches.count
            }
        }
    }

    static func resolve(
        board: GameSession.Board,
        difficulty: Difficulty
    ) -> Result {
        var gemSource = SystemRandomGemSource()
        return resolve(board: board, difficulty: difficulty, using: &gemSource)
    }

    static func resolve<Source: GemSource>(
        board: GameSession.Board,
        difficulty: Difficulty,
        using gemSource: inout Source
    ) -> Result {
        var workingBoard = board
        var steps: [Step] = []
        var cascadeDepth = 1

        while true {
            let matches = MatchDetector.findMatches(on: workingBoard)

            guard !matches.isEmpty else {
                break
            }

            let clearedPositions = Set(matches.flatMap(\.positions))
            let boardAfterClear = clear(matches: matches, on: workingBoard)
            let boardAfterGravity = applyGravity(to: boardAfterClear)
            let boardAfterRefill = refill(boardAfterGravity, using: &gemSource)
            let scoreGained = ScoreCalculator.score(
                for: matches,
                cascadeDepth: cascadeDepth,
                difficulty: difficulty
            )

            steps.append(
                Step(
                    depth: cascadeDepth,
                    matches: matches,
                    clearedPositions: clearedPositions,
                    scoreGained: scoreGained,
                    boardAfterClear: boardAfterClear,
                    boardAfterGravity: boardAfterGravity,
                    boardAfterRefill: boardAfterRefill
                )
            )

            workingBoard = boardAfterRefill
            cascadeDepth += 1
        }

        let totalScore = steps.reduce(0) { partialResult, step in
            partialResult + step.scoreGained
        }

        return Result(board: workingBoard, steps: steps, totalScore: totalScore)
    }

    static func clear(matches: [Match], on board: GameSession.Board) -> GameSession.Board {
        var clearedBoard = board
        let clearedPositions = Set(matches.flatMap(\.positions))

        for position in clearedPositions {
            guard position.row < clearedBoard.count,
                  position.column < (clearedBoard.first?.count ?? 0) else {
                continue
            }

            clearedBoard[position.row][position.column] = nil
        }

        return clearedBoard
    }

    static func applyGravity(to board: GameSession.Board) -> GameSession.Board {
        guard !board.isEmpty else {
            return board
        }

        let rowCount = board.count
        let columnCount = board.first?.count ?? 0
        var updatedBoard = board

        for column in 0..<columnCount {
            var writeRow = rowCount - 1

            for row in stride(from: rowCount - 1, through: 0, by: -1) {
                if let gemType = board[row][column] {
                    updatedBoard[writeRow][column] = gemType

                    if writeRow != row {
                        updatedBoard[row][column] = nil
                    }

                    writeRow -= 1
                }
            }

            if writeRow >= 0 {
                for row in 0...writeRow {
                    updatedBoard[row][column] = nil
                }
            }
        }

        return updatedBoard
    }

    static func refill<Source: GemSource>(
        _ board: GameSession.Board,
        using gemSource: inout Source
    ) -> GameSession.Board {
        guard !board.isEmpty else {
            return board
        }

        let rowCount = board.count
        let columnCount = board.first?.count ?? 0
        var updatedBoard = board

        for column in 0..<columnCount {
            for row in 0..<rowCount where updatedBoard[row][column] == nil {
                updatedBoard[row][column] = gemSource.nextGem()
            }
        }

        return updatedBoard
    }
}
