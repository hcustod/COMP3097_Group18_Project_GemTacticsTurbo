//
//  GameViewModel.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import Foundation

@MainActor
final class GameViewModel: ObservableObject {
    struct SwapFeedback: Equatable {
        enum Outcome: Equatable {
            case ignored
            case invalid
            case valid
        }

        let swap: Swap
        let outcome: Outcome
        let swappedBoard: GameSession.Board?
        let cascadeSteps: [CascadeResolver.Step]
        let resultingBoard: GameSession.Board

        var wasProcessed: Bool {
            outcome != .ignored
        }

        var wasValid: Bool {
            outcome == .valid
        }
    }

    @Published private(set) var session: GameSession
    @Published private(set) var statusMessage: String
    @Published private(set) var isPreparingBoard: Bool
    @Published private(set) var loadingMessage: String?

    private let difficulty: Difficulty
    private let boardEngine: any BoardEngineing
    private let authService: AuthService
    private let profileService: ProfileService
    private let leaderboardService: LeaderboardService
    private var timer: Timer?
    private var totalMatchGroupsResolved = 0
    private var hasSubmittedCompletedGame = false
    private var hasPreparedInitialBoard = false
    private var boardPreparationRequestID = 0

    init(
        difficulty: Difficulty,
        boardEngine: (any BoardEngineing)? = nil,
        authService: AuthService? = nil,
        profileService: ProfileService? = nil,
        leaderboardService: LeaderboardService? = nil
    ) {
        self.difficulty = difficulty
        self.boardEngine = boardEngine ?? BoardEngine()
        self.authService = authService ?? .shared
        self.profileService = profileService ?? ProfileService()
        self.leaderboardService = leaderboardService ?? LeaderboardService()
        self.session = GameSession(difficulty: difficulty)
        self.statusMessage = "Preparing board..."
        self.isPreparingBoard = true
        self.loadingMessage = "Preparing board..."
    }

    deinit {
        timer?.invalidate()
    }

    var board: GameSession.Board {
        session.board
    }

    func prepareInitialBoardIfNeeded() async {
        guard !hasPreparedInitialBoard else {
            return
        }

        hasPreparedInitialBoard = true
        await prepareBoardForNewRound(loadingMessage: "Preparing board...")
    }

    func restartGame() async {
        guard !isPreparingBoard else {
            return
        }

        hasPreparedInitialBoard = true
        await prepareBoardForNewRound(loadingMessage: "Preparing new round...")
    }

    private func prepareBoardForNewRound(loadingMessage: String) async {
        stopTimer()
        boardPreparationRequestID += 1
        let requestID = boardPreparationRequestID

        isPreparingBoard = true
        self.loadingMessage = loadingMessage
        statusMessage = loadingMessage
        session.score = 0
        session.remainingMoves = difficulty.moveLimit
        session.remainingTime = difficulty.timeLimit
        session.comboChain = 0
        session.isPaused = false
        session.isGameOver = false
        session.isWin = false
        totalMatchGroupsResolved = 0
        hasSubmittedCompletedGame = false

        await Task.yield()
        let preparedBoard = boardEngine.makeInitialBoard()

        guard requestID == boardPreparationRequestID else {
            return
        }

        session = GameSession(
            difficulty: difficulty,
            board: preparedBoard
        )
        isPreparingBoard = false
        self.loadingMessage = nil
        statusMessage = "Reach \(session.targetScore) points."
        startTimer()
    }

    @discardableResult
    func attemptSwap(from: BoardPosition, to: BoardPosition) -> SwapFeedback {
        let swap = Swap(source: from, destination: to)

        guard session.isActive, !isPreparingBoard else {
            return SwapFeedback(
                swap: swap,
                outcome: .ignored,
                swappedBoard: nil,
                cascadeSteps: [],
                resultingBoard: session.board
            )
        }

        let result = boardEngine.resolveSwap(
            swap,
            on: session.board,
            difficulty: difficulty
        )

        guard result.wasValid else {
            session.comboChain = 0
            statusMessage = "No match."
            return SwapFeedback(
                swap: swap,
                outcome: .invalid,
                swappedBoard: nil,
                cascadeSteps: [],
                resultingBoard: session.board
            )
        }

        session.board = result.board
        session.remainingMoves = max(0, session.remainingMoves - 1)
        session.score += result.scoreGained
        session.comboChain = result.comboChain
        totalMatchGroupsResolved += result.totalMatchGroups

        if result.comboChain > 1 {
            statusMessage = "Combo x\(result.comboChain)  +\(result.scoreGained)"
        } else {
            statusMessage = "+\(result.scoreGained) points"
        }

        evaluateEndConditions()

        return SwapFeedback(
            swap: swap,
            outcome: .valid,
            swappedBoard: result.boardAfterSwap,
            cascadeSteps: result.cascadeSteps,
            resultingBoard: session.board
        )
    }

    func pauseGame() {
        guard session.isActive, !isPreparingBoard else {
            return
        }

        session.isPaused = true
        statusMessage = "Paused"
    }

    func resumeGame() {
        guard session.isPaused, !session.isGameOver, !isPreparingBoard else {
            return
        }

        session.isPaused = false
        statusMessage = "Go"
    }

    func processTimerTick() {
        guard session.isActive, !isPreparingBoard else {
            return
        }

        guard session.remainingTime > 0 else {
            endGame(isWin: false, message: "Time up")
            return
        }

        session.remainingTime -= 1

        if session.remainingTime <= 0 {
            endGame(isWin: false, message: "Time up")
        }
    }

    private func startTimer() {
        stopTimer()

        let timer = Timer(
            timeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            guard let self else {
                return
            }

            MainActor.assumeIsolated {
                self.processTimerTick()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func evaluateEndConditions() {
        if session.hasReachedTargetScore {
            endGame(
                isWin: true,
                message: "Target reached"
            )
            return
        }

        if session.remainingMoves <= 0 {
            endGame(
                isWin: false,
                message: "No moves left"
            )
        }
    }

    private func endGame(isWin: Bool, message: String) {
        guard !session.isGameOver else {
            return
        }

        session.isGameOver = true
        session.isWin = isWin
        session.isPaused = false
        statusMessage = message
        stopTimer()
        persistCompletedGameIfNeeded()
    }

    private func persistCompletedGameIfNeeded() {
        guard !hasSubmittedCompletedGame else {
            return
        }

        hasSubmittedCompletedGame = true

        guard let currentUser = authService.getCurrentUser() else {
            return
        }

        let finalScore = session.score
        let difficulty = session.difficulty
        let totalMatchGroupsResolved = totalMatchGroupsResolved
        let didWin = session.isWin
        let leaderboardEntry = LeaderboardEntry.make(
            for: currentUser,
            score: finalScore,
            difficulty: difficulty
        )

        Task {
            do {
                try await leaderboardService.submitScore(entry: leaderboardEntry)
            } catch {
                // Keep the end-of-game flow responsive even if leaderboard submission fails.
            }

            do {
                _ = try await profileService.recordCompletedGame(
                    for: currentUser,
                    difficulty: difficulty,
                    finalScore: finalScore,
                    totalMatchGroups: totalMatchGroupsResolved,
                    didWin: didWin
                )
            } catch {
                // Profile persistence failure should not block the player from finishing the round.
            }
        }
    }
}
