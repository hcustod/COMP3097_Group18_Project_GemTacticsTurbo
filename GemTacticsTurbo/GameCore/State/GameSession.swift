//
//  GameSession.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

struct GameSession: Equatable, Sendable {
    typealias Board = [[GemType?]]
    static let defaultRowCount = 9
    static let defaultColumnCount = 5

    let difficulty: Difficulty
    var board: Board
    var score: Int
    var remainingMoves: Int
    var remainingTime: Int
    var comboChain: Int
    var isPaused: Bool
    var isGameOver: Bool
    var isWin: Bool

    init(
        difficulty: Difficulty,
        board: Board = GameSession.emptyBoard(),
        score: Int = 0,
        remainingMoves: Int? = nil,
        remainingTime: Int? = nil,
        comboChain: Int = 0,
        isPaused: Bool = false,
        isGameOver: Bool = false,
        isWin: Bool = false
    ) {
        self.difficulty = difficulty
        self.board = board
        self.score = score
        self.remainingMoves = remainingMoves ?? difficulty.moveLimit
        self.remainingTime = remainingTime ?? difficulty.timeLimit
        self.comboChain = comboChain
        self.isPaused = isPaused
        self.isGameOver = isGameOver
        self.isWin = isWin
    }

    var rowCount: Int {
        board.count
    }

    var columnCount: Int {
        board.first?.count ?? 0
    }

    var targetScore: Int {
        difficulty.targetScore
    }

    var hasReachedTargetScore: Bool {
        score >= targetScore
    }

    var isActive: Bool {
        !isPaused && !isGameOver
    }

    static func emptyBoard(
        rows: Int = defaultRowCount,
        columns: Int = defaultColumnCount
    ) -> Board {
        Array(
            repeating: Array(repeating: nil, count: columns),
            count: rows
        )
    }
}
