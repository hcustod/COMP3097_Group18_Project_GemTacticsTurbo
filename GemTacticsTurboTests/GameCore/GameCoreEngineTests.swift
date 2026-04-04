//
//  GameCoreEngineTests.swift
//  GemTacticsTurboTests
//
//  Created by Henrique Custodio on 3/26/26.
//

import XCTest
@testable import GemTacticsTurbo

@MainActor
final class GameCoreEngineTests: XCTestCase {
    func testBoardGeneratorProducesBoardWithoutInitialMatches() {
        var gemSource = SequenceGemSource([
            .ruby,
            .ruby,
            .ruby,
            .sapphire,
            .emerald,
            .topaz,
            .amethyst
        ])

        let board = BoardGenerator.generate(rows: 8, columns: 8, using: &gemSource)

        XCTAssertEqual(board.count, 8)
        XCTAssertEqual(board.first?.count, 8)
        XCTAssertTrue(MatchDetector.findMatches(on: board).isEmpty)
        XCTAssertFalse(board.flatMap(\.self).contains(where: { $0 == nil }))
        XCTAssertGreaterThanOrEqual(
            BoardMoveAnalyzer.countValidSwaps(on: board),
            BoardGenerator.minimumPlayableSwaps
        )
    }

    func testAdjacencyValidationUsesOrthogonalNeighborsOnly() {
        XCTAssertTrue(
            SwapValidator.areAdjacent(
                BoardPosition(row: 2, column: 2),
                BoardPosition(row: 2, column: 3)
            )
        )
        XCTAssertTrue(
            SwapValidator.areAdjacent(
                BoardPosition(row: 2, column: 2),
                BoardPosition(row: 3, column: 2)
            )
        )
        XCTAssertFalse(
            SwapValidator.areAdjacent(
                BoardPosition(row: 2, column: 2),
                BoardPosition(row: 3, column: 3)
            )
        )
        XCTAssertFalse(
            SwapValidator.areAdjacent(
                BoardPosition(row: 2, column: 2),
                BoardPosition(row: 2, column: 2)
            )
        )
    }

    func testInvalidSwapIsRejectedWhenItCreatesNoMatch() {
        let board = makeBoard([
            [.ruby, .sapphire, .emerald],
            [.emerald, .topaz, .amethyst],
            [.sapphire, .ruby, .topaz]
        ])
        let swap = Swap(
            source: BoardPosition(row: 0, column: 0),
            destination: BoardPosition(row: 0, column: 1)
        )

        XCTAssertFalse(SwapValidator.isValid(swap, on: board))
    }

    func testHorizontalMatchDetectionFindsThreeInARow() {
        let board = makeBoard([
            [.ruby, .ruby, .ruby, .sapphire],
            [.emerald, .topaz, .amethyst, .emerald],
            [.sapphire, .emerald, .topaz, .amethyst]
        ])

        let matches = MatchDetector.findMatches(on: board)

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].gemType, .ruby)
        XCTAssertEqual(matches[0].length, 3)
        XCTAssertEqual(
            matches[0].positions,
            [
                BoardPosition(row: 0, column: 0),
                BoardPosition(row: 0, column: 1),
                BoardPosition(row: 0, column: 2)
            ]
        )
    }

    func testVerticalMatchDetectionFindsThreeInAColumn() {
        let board = makeBoard([
            [.ruby, .sapphire, .emerald],
            [.topaz, .sapphire, .amethyst],
            [.emerald, .sapphire, .ruby],
            [.amethyst, .ruby, .topaz]
        ])

        let matches = MatchDetector.findMatches(on: board)

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].gemType, .sapphire)
        XCTAssertEqual(matches[0].length, 3)
        XCTAssertEqual(
            matches[0].positions,
            [
                BoardPosition(row: 0, column: 1),
                BoardPosition(row: 1, column: 1),
                BoardPosition(row: 2, column: 1)
            ]
        )
    }

    func testClearingLogicEmptiesAllUniqueMatchedPositions() {
        let board = makeBoard([
            [.sapphire, .ruby, .topaz],
            [.ruby, .ruby, .ruby],
            [.amethyst, .ruby, .emerald]
        ])

        let matches = MatchDetector.findMatches(on: board)
        let clearedBoard = CascadeResolver.clear(matches: matches, on: board)

        XCTAssertNil(clearedBoard[0][1])
        XCTAssertNil(clearedBoard[1][0])
        XCTAssertNil(clearedBoard[1][1])
        XCTAssertNil(clearedBoard[1][2])
        XCTAssertNil(clearedBoard[2][1])
        XCTAssertEqual(clearedBoard[0][0], .sapphire)
        XCTAssertEqual(clearedBoard[2][2], .emerald)
    }

    func testGravityMovesGemsDownWithinEachColumn() {
        let board: Board = [
            [.ruby, nil, .topaz],
            [.sapphire, .emerald, nil],
            [nil, .amethyst, .emerald],
            [.topaz, nil, .ruby]
        ]

        let gravityBoard = CascadeResolver.applyGravity(to: board)

        XCTAssertEqual(
            gravityBoard,
            [
                [nil, nil, nil],
                [.ruby, nil, .topaz],
                [.sapphire, .emerald, .emerald],
                [.topaz, .amethyst, .ruby]
            ]
        )
    }

    func testRefillFillsEmptySpacesAtTheTop() {
        let board: Board = [
            [nil, nil, nil],
            [.ruby, nil, .topaz],
            [.sapphire, .emerald, .emerald],
            [.topaz, .amethyst, .ruby]
        ]
        var gemSource = SequenceGemSource([
            .emerald,
            .topaz,
            .ruby,
            .sapphire
        ])

        let refilledBoard = CascadeResolver.refill(board, using: &gemSource)

        XCTAssertEqual(
            refilledBoard,
            [
                [.emerald, .topaz, .sapphire],
                [.ruby, .ruby, .topaz],
                [.sapphire, .emerald, .emerald],
                [.topaz, .amethyst, .ruby]
            ]
        )
    }

    func testCascadeResolutionResolvesUntilTheBoardIsStable() {
        let board = makeBoard([
            [.topaz, .emerald, .topaz, .amethyst, .sapphire],
            [.emerald, .sapphire, .amethyst, .topaz, .ruby],
            [.ruby, .ruby, .ruby, .emerald, .topaz],
            [.amethyst, .sapphire, .topaz, .ruby, .emerald],
            [.sapphire, .sapphire, .emerald, .amethyst, .ruby]
        ])
        var gemSource = SequenceGemSource([
            .emerald,
            .topaz,
            .ruby,
            .topaz,
            .ruby,
            .ruby
        ])

        let result = CascadeResolver.resolve(
            board: board,
            difficulty: .easy,
            using: &gemSource
        )

        XCTAssertEqual(result.steps.count, 2)
        XCTAssertEqual(result.steps[0].depth, 1)
        XCTAssertEqual(result.steps[0].matches.count, 1)
        XCTAssertEqual(result.steps[0].matches[0].gemType, .ruby)
        XCTAssertEqual(result.steps[1].depth, 2)
        XCTAssertEqual(result.steps[1].matches.count, 1)
        XCTAssertEqual(result.steps[1].matches[0].gemType, .sapphire)
        XCTAssertEqual(result.totalScore, 675)
        XCTAssertTrue(MatchDetector.findMatches(on: result.board).isEmpty)
        XCTAssertEqual(
            result.board,
            makeBoard([
                [.emerald, .topaz, .ruby, .amethyst, .sapphire],
                [.topaz, .ruby, .topaz, .topaz, .ruby],
                [.emerald, .ruby, .amethyst, .emerald, .topaz],
                [.amethyst, .topaz, .topaz, .ruby, .emerald],
                [.sapphire, .emerald, .emerald, .amethyst, .ruby]
            ])
        )
    }

    func testScoreCalculationUsesMatchBonusComboAndDifficultyMultiplier() {
        let match = Match(
            positions: [
                BoardPosition(row: 0, column: 0),
                BoardPosition(row: 0, column: 1),
                BoardPosition(row: 0, column: 2),
                BoardPosition(row: 0, column: 3)
            ],
            gemType: .ruby
        )

        let score = ScoreCalculator.score(
            for: [match],
            cascadeDepth: 3,
            difficulty: .hard
        )

        XCTAssertEqual(score, 1_350)
    }

    func testBoardMoveAnalyzerDetectsDeadBoard() {
        let board = makeBoard([
            [.sapphire, .topaz, .ruby, .emerald, .ruby],
            [.amethyst, .ruby, .ruby, .amethyst, .emerald],
            [.emerald, .emerald, .amethyst, .topaz, .sapphire],
            [.amethyst, .sapphire, .topaz, .topaz, .amethyst],
            [.sapphire, .amethyst, .emerald, .emerald, .amethyst]
        ])

        XCTAssertTrue(MatchDetector.findMatches(on: board).isEmpty)
        XCTAssertEqual(BoardMoveAnalyzer.countValidSwaps(on: board), 0)
        XCTAssertFalse(
            BoardMoveAnalyzer.hasAtLeastValidSwaps(
                BoardGenerator.minimumPlayableSwaps,
                on: board
            )
        )
    }

    func testRepairPlayabilityRebuildsDeadBoardWithAtLeastTwoLiveMoves() {
        let deadBoard = makeBoard([
            [.sapphire, .topaz, .ruby, .emerald, .ruby],
            [.amethyst, .ruby, .ruby, .amethyst, .emerald],
            [.emerald, .emerald, .amethyst, .topaz, .sapphire],
            [.amethyst, .sapphire, .topaz, .topaz, .amethyst],
            [.sapphire, .amethyst, .emerald, .emerald, .amethyst]
        ])
        var gemSource = SequenceGemSource([
            .ruby,
            .ruby,
            .ruby,
            .sapphire,
            .emerald,
            .topaz,
            .amethyst
        ])

        let repaired = BoardGenerator.repairPlayability(
            for: deadBoard,
            using: &gemSource
        )

        XCTAssertTrue(repaired.wasRepaired)
        XCTAssertTrue(repaired.metMinimumSwapRequirement)
        XCTAssertTrue(MatchDetector.findMatches(on: repaired.board).isEmpty)
        XCTAssertGreaterThanOrEqual(
            BoardMoveAnalyzer.countValidSwaps(on: repaired.board),
            BoardGenerator.minimumPlayableSwaps
        )
    }

    func testDefaultBoardEngineProducesPortraitBoardWithMoveChoices() {
        let engine = BoardEngine()

        let board = engine.makeInitialBoard()

        XCTAssertEqual(board.count, GameSession.defaultRowCount)
        XCTAssertEqual(board.first?.count, GameSession.defaultColumnCount)
        XCTAssertTrue(MatchDetector.findMatches(on: board).isEmpty)
        XCTAssertGreaterThanOrEqual(
            BoardMoveAnalyzer.countValidSwaps(on: board),
            BoardGenerator.minimumPlayableSwaps
        )
    }

    private typealias Board = GameSession.Board

    private func makeBoard(_ rows: [[GemType]]) -> Board {
        rows.map { row in
            row.map(Optional.some)
        }
    }
}

private struct SequenceGemSource: GemSource {
    private let gems: [GemType]
    private var index = 0

    init(_ gems: [GemType]) {
        precondition(!gems.isEmpty)
        self.gems = gems
    }

    mutating func nextGem() -> GemType {
        let gem = gems[index % gems.count]
        index += 1
        return gem
    }
}
