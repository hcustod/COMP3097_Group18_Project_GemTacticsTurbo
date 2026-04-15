//
//  GameScene.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SpriteKit
import UIKit

final class GameScene: SKScene {
    private enum Layout {
        static let boardPadding: CGFloat = 28
        static let tileSpacingRatio: CGFloat = 0.08
        static let minimumTileSpacing: CGFloat = 4
        static let maximumTileSpacing: CGFloat = 8
        static let gemInset: CGFloat = 16
        static let boardCornerRadius: CGFloat = 28
        static let selectedStrokeWidth: CGFloat = 3
        static let swapDuration: TimeInterval = 0.14
        static let swapBackDuration: TimeInterval = 0.12
        static let clearDuration: TimeInterval = 0.12
        static let clearScale: CGFloat = 0.22
        static let fallBaseDuration: TimeInterval = 0.10
        static let fallPerRowDuration: TimeInterval = 0.04
        static let spawnBaseDuration: TimeInterval = 0.12
        static let spawnPerRowDuration: TimeInterval = 0.04
        static let spawnScale: CGFloat = 0.88
    }

    private final class GemSpriteNode: SKNode {
        let gemID = UUID()
        let gemType: GemType

        init(gemType: GemType) {
            self.gemType = gemType
            super.init()
            name = gemType.assetName
            zPosition = 2
        }

        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            nil
        }
    }

    private struct ColumnAssignment {
        let source: BoardPosition
        let destination: BoardPosition
    }

    private struct SpawnSpec {
        let position: BoardPosition
        let gem: GemType
        let startRow: CGFloat
    }

    private let boardNode = SKNode()
    private let tileLayer = SKNode()
    private let gemLayer = SKNode()
    private var boardBackgroundNode: SKShapeNode?
    private var currentBoard: GameSession.Board = GameSession.emptyBoard()
    private var tileNodes: [BoardPosition: SKShapeNode] = [:]
    private var gemNodesByID: [UUID: GemSpriteNode] = [:]
    private var gemNodeIDsByPosition: [BoardPosition: UUID] = [:]
    private var selectedPosition: BoardPosition?
    private var tileStride: CGFloat = 0
    private var tileSize: CGFloat = 0
    private var tileSpacing: CGFloat = 0
    private var boardWidth: CGFloat = 0
    private var boardHeight: CGFloat = 0
    private var boardRows: Int = 0
    private var boardColumns: Int = 0
    private var isAnimatingBoard = false

    var onSwapRequested: ((Swap) -> Void)?
    var isBoardInteractionEnabled = true {
        didSet {
            if !isBoardInteractionEnabled {
                clearSelection()
            }
        }
    }

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        tileLayer.zPosition = 0
        gemLayer.zPosition = 1
        configureSceneGraph()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func render(board: GameSession.Board) {
        currentBoard = board
        selectedPosition = nil
        rebuildBoard()
    }

    func animateInvalidSwap(
        _ swap: Swap,
        completion: @escaping () -> Void
    ) {
        guard
            let sourceNode = gemNode(at: swap.source),
            let destinationNode = gemNode(at: swap.destination)
        else {
            completion()
            return
        }

        isAnimatingBoard = true
        clearSelection()

        let sourcePoint = pointForPosition(swap.source)
        let destinationPoint = pointForPosition(swap.destination)

        flashInvalidSelection(positions: [swap.source, swap.destination])

        sourceNode.run(
            .sequence([
                moveAction(to: destinationPoint, duration: Layout.swapDuration),
                moveAction(to: sourcePoint, duration: Layout.swapBackDuration)
            ])
        )
        destinationNode.run(
            .sequence([
                moveAction(to: sourcePoint, duration: Layout.swapDuration),
                moveAction(to: destinationPoint, duration: Layout.swapBackDuration)
            ])
        )

        run(
            .sequence([
                .wait(forDuration: Layout.swapDuration + Layout.swapBackDuration),
                .run { [weak self] in
                    self?.isAnimatingBoard = false
                    completion()
                }
            ])
        )
    }

    func animateValidSwap(
        _ swap: Swap,
        swappedBoard: GameSession.Board,
        cascadeSteps: [CascadeResolver.Step],
        finalBoard: GameSession.Board,
        completion: @escaping () -> Void
    ) {
        guard
            gemNode(at: swap.source) != nil,
            gemNode(at: swap.destination) != nil
        else {
            render(board: finalBoard)
            completion()
            return
        }

        isAnimatingBoard = true
        clearSelection()

        animateSwap(swap) { [weak self] in
            guard let self else {
                completion()
                return
            }

            self.applySwapMapping(for: swap)
            self.currentBoard = swappedBoard
            self.animateCascadeSteps(
                cascadeSteps,
                index: 0,
                finalBoard: finalBoard,
                completion: completion
            )
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildBoard()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            isBoardInteractionEnabled,
            !isAnimatingBoard,
            let touch = touches.first
        else {
            return
        }

        let location = touch.location(in: boardNode)

        guard
            let position = boardPosition(for: location),
            gemNode(at: position) != nil
        else {
            return
        }

        handleSelection(at: position)
    }

    private func rebuildBoard() {
        configureSceneGraph()
        tileLayer.removeAllChildren()
        gemLayer.removeAllChildren()
        boardBackgroundNode?.removeFromParent()
        boardBackgroundNode = nil
        tileNodes = [:]
        gemNodesByID = [:]
        gemNodeIDsByPosition = [:]

        let rows = currentBoard.count
        let columns = currentBoard.first?.count ?? 0

        guard rows > 0, columns > 0 else {
            return
        }

        updateBoardMetrics(rows: rows, columns: columns)

        let boardBackground = SKShapeNode(
            rectOf: CGSize(width: boardWidth + 18, height: boardHeight + 18),
            cornerRadius: Layout.boardCornerRadius
        )
        boardBackground.fillColor = UIColor(red: 0.08, green: 0.07, blue: 0.16, alpha: 0.94)
        boardBackground.strokeColor = UIColor(red: 0.50, green: 0.90, blue: 0.98, alpha: 0.30)
        boardBackground.lineWidth = 2
        boardBackground.glowWidth = 1.5
        boardBackground.zPosition = -1
        boardBackgroundNode = boardBackground
        boardNode.addChild(boardBackground)

        for row in 0..<rows {
            for column in 0..<columns {
                let boardPosition = BoardPosition(row: row, column: column)
                let tileNode = makeTileNode()
                tileNode.position = pointForPosition(boardPosition)
                tileLayer.addChild(tileNode)
                tileNodes[boardPosition] = tileNode

                if let gem = currentBoard[row][column] {
                    let gemNode = makeGemNode(for: gem)
                    addGemNode(gemNode, at: boardPosition)
                }
            }
        }

        updateSelectionAppearance()
    }

    private func configureSceneGraph() {
        if boardNode.parent == nil {
            addChild(boardNode)
        }

        if tileLayer.parent !== boardNode {
            tileLayer.removeFromParent()
            boardNode.addChild(tileLayer)
        }

        if gemLayer.parent !== boardNode {
            gemLayer.removeFromParent()
            boardNode.addChild(gemLayer)
        }
    }

    private func updateBoardMetrics(rows: Int, columns: Int) {
        let availableWidth = max(size.width - (Layout.boardPadding * 2), 1)
        let availableHeight = max(size.height - (Layout.boardPadding * 2), 1)
        tileStride = min(
            availableWidth / CGFloat(columns),
            availableHeight / CGFloat(rows)
        )
        tileSpacing = min(
            max(tileStride * Layout.tileSpacingRatio, Layout.minimumTileSpacing),
            Layout.maximumTileSpacing
        )
        tileSize = max(tileStride - tileSpacing, 1)
        boardWidth = (tileStride * CGFloat(columns)) - tileSpacing
        boardHeight = (tileStride * CGFloat(rows)) - tileSpacing
        boardRows = rows
        boardColumns = columns
    }

    private func pointForPosition(_ position: BoardPosition) -> CGPoint {
        pointFor(column: position.column, visualRow: CGFloat(position.row))
    }

    private func pointFor(column: Int, visualRow: CGFloat) -> CGPoint {
        let x = (-boardWidth / 2) + (CGFloat(column) * tileStride) + (tileSize / 2)
        let y = (boardHeight / 2) - (visualRow * tileStride) - (tileSize / 2)
        return CGPoint(x: x, y: y)
    }

    private func boardPosition(for location: CGPoint) -> BoardPosition? {
        guard boardRows > 0, boardColumns > 0, tileStride > 0 else {
            return nil
        }

        let minX = -boardWidth / 2
        let maxX = boardWidth / 2
        let minY = -boardHeight / 2
        let maxY = boardHeight / 2

        guard
            location.x >= minX,
            location.x <= maxX,
            location.y >= minY,
            location.y <= maxY
        else {
            return nil
        }

        let normalizedX = location.x - minX
        let normalizedY = maxY - location.y
        let column = Int(normalizedX / tileStride)
        let row = Int(normalizedY / tileStride)

        guard row >= 0, row < boardRows, column >= 0, column < boardColumns else {
            return nil
        }

        let tileOriginX = minX + (CGFloat(column) * tileStride)
        let tileOriginY = maxY - (CGFloat(row) * tileStride)
        let isInsideTileBounds = location.x >= tileOriginX &&
            location.x <= tileOriginX + tileSize &&
            location.y <= tileOriginY &&
            location.y >= tileOriginY - tileSize

        guard isInsideTileBounds else {
            return nil
        }

        return BoardPosition(row: row, column: column)
    }

    private func makeTileNode() -> SKShapeNode {
        let tileNode = SKShapeNode(
            rectOf: CGSize(width: tileSize, height: tileSize),
            cornerRadius: max(tileSize * 0.18, 8)
        )
        tileNode.fillColor = UIColor(red: 0.12, green: 0.10, blue: 0.24, alpha: 0.92)
        tileNode.strokeColor = UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.10)
        tileNode.lineWidth = 1
        return tileNode
    }

    private func makeGemNode(for gem: GemType) -> GemSpriteNode {
        let gemNode = GemSpriteNode(gemType: gem)
        let gemSideLength = max(tileSize - Layout.gemInset, 10)

        let gemShape = SKShapeNode(
            path: diamondPath(sideLength: gemSideLength)
        )
        gemShape.fillColor = color(for: gem)
        gemShape.strokeColor = UIColor.white.withAlphaComponent(0.35)
        gemShape.lineWidth = 1.5
        gemShape.glowWidth = 1
        gemNode.addChild(gemShape)

        let shineShape = SKShapeNode(circleOfRadius: max(gemSideLength * 0.12, 3))
        shineShape.fillColor = UIColor.white.withAlphaComponent(0.30)
        shineShape.strokeColor = .clear
        shineShape.position = CGPoint(
            x: max(gemSideLength * -0.16, -8),
            y: max(gemSideLength * 0.18, 8)
        )
        gemNode.addChild(shineShape)

        let labelNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        labelNode.text = String(gem.displayName.prefix(1))
        labelNode.fontSize = max(tileSize * 0.22, 10)
        labelNode.verticalAlignmentMode = .center
        labelNode.fontColor = UIColor.white.withAlphaComponent(0.92)
        labelNode.position = CGPoint(x: 0, y: -labelNode.fontSize * 0.08)
        gemNode.addChild(labelNode)

        return gemNode
    }

    private func addGemNode(_ gemNode: GemSpriteNode, at position: BoardPosition) {
        addGemNode(gemNode, at: position, startingPoint: pointForPosition(position))
    }

    private func addGemNode(
        _ gemNode: GemSpriteNode,
        at position: BoardPosition,
        startingPoint: CGPoint
    ) {
        gemNode.position = startingPoint
        gemLayer.addChild(gemNode)
        gemNodesByID[gemNode.gemID] = gemNode
        gemNodeIDsByPosition[position] = gemNode.gemID
    }

    private func gemNode(at position: BoardPosition) -> GemSpriteNode? {
        guard let gemID = gemNodeIDsByPosition[position] else {
            return nil
        }

        return gemNodesByID[gemID]
    }

    private func handleSelection(at position: BoardPosition) {
        if selectedPosition == position {
            clearSelection()
            return
        }

        guard let selectedPosition else {
            self.selectedPosition = position
            updateSelectionAppearance()
            pulseGem(at: position)
            return
        }

        guard isAdjacent(selectedPosition, position) else {
            self.selectedPosition = position
            updateSelectionAppearance()
            pulseGem(at: position)
            return
        }

        clearSelection()
        onSwapRequested?(Swap(source: selectedPosition, destination: position))
    }

    private func isAdjacent(_ lhs: BoardPosition, _ rhs: BoardPosition) -> Bool {
        abs(lhs.row - rhs.row) + abs(lhs.column - rhs.column) == 1
    }

    private func clearSelection() {
        selectedPosition = nil
        updateSelectionAppearance()
    }

    private func updateSelectionAppearance() {
        for (position, tileNode) in tileNodes {
            let isSelected = position == selectedPosition
            tileNode.strokeColor = isSelected
                ? UIColor(red: 0.32, green: 0.88, blue: 0.96, alpha: 0.95)
                : UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.10)
            tileNode.lineWidth = isSelected ? Layout.selectedStrokeWidth : 1
            tileNode.fillColor = isSelected
                ? UIColor(red: 0.18, green: 0.16, blue: 0.34, alpha: 0.96)
                : UIColor(red: 0.12, green: 0.10, blue: 0.24, alpha: 0.92)

            if let gemNode = gemNode(at: position) {
                gemNode.removeAction(forKey: "selectionScale")
                gemNode.run(
                    scaleAction(to: isSelected ? 1.07 : 1, duration: 0.10),
                    withKey: "selectionScale"
                )
            }
        }
    }

    private func pulseGem(at position: BoardPosition) {
        guard let gemNode = gemNode(at: position) else {
            return
        }

        gemNode.removeAction(forKey: "selectionPulse")
        gemNode.run(
            .sequence([
                scaleAction(to: 1.10, duration: 0.08),
                scaleAction(to: 1.07, duration: 0.08)
            ]),
            withKey: "selectionPulse"
        )
    }

    private func flashInvalidSelection(positions: [BoardPosition]) {
        for position in positions {
            guard let tileNode = tileNodes[position] else {
                continue
            }

            let originalStrokeColor = tileNode.strokeColor
            let originalLineWidth = tileNode.lineWidth
            tileNode.strokeColor = UIColor(red: 1.00, green: 0.42, blue: 0.48, alpha: 1)
            tileNode.lineWidth = Layout.selectedStrokeWidth

            tileNode.run(
                .sequence([
                    .wait(forDuration: Layout.swapDuration + Layout.swapBackDuration),
                    .run {
                        tileNode.strokeColor = originalStrokeColor
                        tileNode.lineWidth = originalLineWidth
                    }
                ])
            )
        }
    }

    private func animateSwap(
        _ swap: Swap,
        completion: @escaping () -> Void
    ) {
        guard
            let sourceNode = gemNode(at: swap.source),
            let destinationNode = gemNode(at: swap.destination)
        else {
            completion()
            return
        }

        sourceNode.run(
            moveAction(
                to: pointForPosition(swap.destination),
                duration: Layout.swapDuration
            )
        )
        destinationNode.run(
            moveAction(
                to: pointForPosition(swap.source),
                duration: Layout.swapDuration
            )
        )

        run(
            .sequence([
                .wait(forDuration: Layout.swapDuration),
                .run(completion)
            ])
        )
    }

    private func applySwapMapping(for swap: Swap) {
        guard
            let sourceID = gemNodeIDsByPosition[swap.source],
            let destinationID = gemNodeIDsByPosition[swap.destination]
        else {
            return
        }

        gemNodeIDsByPosition[swap.source] = destinationID
        gemNodeIDsByPosition[swap.destination] = sourceID
    }

    private func animateCascadeSteps(
        _ cascadeSteps: [CascadeResolver.Step],
        index: Int,
        finalBoard: GameSession.Board,
        completion: @escaping () -> Void
    ) {
        guard index < cascadeSteps.count else {
            finishAnimatedBoardTransition(to: finalBoard, completion: completion)
            return
        }

        let step = cascadeSteps[index]

        animateMatchedRemovals(step.clearedPositions) { [weak self] in
            guard let self else {
                completion()
                return
            }

            self.currentBoard = step.boardAfterClear
            self.animateFalls(from: step.boardAfterClear, to: step.boardAfterGravity) { [weak self] in
                guard let self else {
                    completion()
                    return
                }

                self.currentBoard = step.boardAfterGravity
                self.animateSpawns(from: step.boardAfterGravity, to: step.boardAfterRefill) { [weak self] in
                    guard let self else {
                        completion()
                        return
                    }

                    self.currentBoard = step.boardAfterRefill
                    self.animateCascadeSteps(
                        cascadeSteps,
                        index: index + 1,
                        finalBoard: finalBoard,
                        completion: completion
                    )
                }
            }
        }
    }

    private func animateMatchedRemovals(
        _ positions: Set<BoardPosition>,
        completion: @escaping () -> Void
    ) {
        typealias RemovalTarget = (
            position: BoardPosition,
            gemID: UUID,
            gemNode: GemSpriteNode
        )
        let removalTargets: [RemovalTarget] = positions.compactMap { position -> RemovalTarget? in
            guard let gemID = gemNodeIDsByPosition[position],
                  let gemNode = gemNodesByID[gemID] else {
                return nil
            }

            return (position, gemID, gemNode)
        }

        guard !removalTargets.isEmpty else {
            completion()
            return
        }

        let clearAction = SKAction.group([
            fadeAction(to: 0, duration: Layout.clearDuration),
            scaleAction(to: Layout.clearScale, duration: Layout.clearDuration)
        ])

        for (_, _, gemNode) in removalTargets {
            gemNode.run(clearAction)
        }

        run(
            .sequence([
                .wait(forDuration: Layout.clearDuration),
                .run { [weak self] in
                    guard let self else {
                        completion()
                        return
                    }

                    for (position, gemID, gemNode) in removalTargets {
                        self.gemNodeIDsByPosition.removeValue(forKey: position)
                        self.gemNodesByID.removeValue(forKey: gemID)
                        gemNode.removeFromParent()
                    }

                    completion()
                }
            ])
        )
    }

    private func animateFalls(
        from sourceBoard: GameSession.Board,
        to destinationBoard: GameSession.Board,
        completion: @escaping () -> Void
    ) {
        let assignments = makeGravityAssignments(
            from: sourceBoard,
            to: destinationBoard
        )

        guard !assignments.isEmpty else {
            completion()
            return
        }

        var updatedPositions = gemNodeIDsByPosition
        var longestDuration: TimeInterval = 0

        for assignment in assignments {
            guard let gemID = gemNodeIDsByPosition[assignment.source],
                  let gemNode = gemNodesByID[gemID] else {
                continue
            }

            updatedPositions.removeValue(forKey: assignment.source)
            updatedPositions[assignment.destination] = gemID

            guard assignment.source != assignment.destination else {
                continue
            }

            let duration = fallDuration(
                fromRow: assignment.source.row,
                toRow: assignment.destination.row
            )
            longestDuration = max(longestDuration, duration)
            gemNode.run(
                moveAction(
                    to: pointForPosition(assignment.destination),
                    duration: duration,
                    timingMode: .easeIn
                )
            )
        }

        if longestDuration == 0 {
            gemNodeIDsByPosition = updatedPositions
            completion()
            return
        }

        run(
            .sequence([
                .wait(forDuration: longestDuration),
                .run { [weak self] in
                    self?.gemNodeIDsByPosition = updatedPositions
                    completion()
                }
            ])
        )
    }

    private func animateSpawns(
        from sourceBoard: GameSession.Board,
        to destinationBoard: GameSession.Board,
        completion: @escaping () -> Void
    ) {
        let spawnSpecs = makeSpawnSpecs(
            from: sourceBoard,
            to: destinationBoard
        )

        guard !spawnSpecs.isEmpty else {
            completion()
            return
        }

        var longestDuration: TimeInterval = 0

        for spawnSpec in spawnSpecs {
            let gemNode = makeGemNode(for: spawnSpec.gem)
            let startPoint = pointFor(
                column: spawnSpec.position.column,
                visualRow: spawnSpec.startRow
            )
            let finalPoint = pointForPosition(spawnSpec.position)
            let duration = spawnDuration(
                fromRow: spawnSpec.startRow,
                toRow: spawnSpec.position.row
            )

            longestDuration = max(longestDuration, duration)
            gemNode.alpha = 0
            gemNode.setScale(Layout.spawnScale)
            addGemNode(gemNode, at: spawnSpec.position, startingPoint: startPoint)
            gemNode.run(
                .group([
                    fadeAction(to: 1, duration: duration),
                    scaleAction(to: 1, duration: duration),
                    moveAction(
                        to: finalPoint,
                        duration: duration,
                        timingMode: .easeIn
                    )
                ])
            )
        }

        run(
            .sequence([
                .wait(forDuration: longestDuration),
                .run(completion)
            ])
        )
    }

    private func finishAnimatedBoardTransition(
        to finalBoard: GameSession.Board,
        completion: @escaping () -> Void
    ) {
        if currentBoard != finalBoard {
            render(board: finalBoard)
        }

        isAnimatingBoard = false
        completion()
    }

    private func makeGravityAssignments(
        from sourceBoard: GameSession.Board,
        to destinationBoard: GameSession.Board
    ) -> [ColumnAssignment] {
        let rowCount = sourceBoard.count
        let columnCount = sourceBoard.first?.count ?? 0
        guard rowCount == destinationBoard.count,
              columnCount == (destinationBoard.first?.count ?? 0) else {
            return []
        }

        var assignments: [ColumnAssignment] = []

        for column in 0..<columnCount {
            let sourcePositions = (0..<rowCount).compactMap { row -> BoardPosition? in
                sourceBoard[row][column] != nil ? BoardPosition(row: row, column: column) : nil
            }
            let destinationPositions = (0..<rowCount).compactMap { row -> BoardPosition? in
                destinationBoard[row][column] != nil ? BoardPosition(row: row, column: column) : nil
            }

            guard sourcePositions.count == destinationPositions.count else {
                return []
            }

            for (source, destination) in zip(
                sourcePositions.reversed(),
                destinationPositions.reversed()
            ) {
                assignments.append(
                    ColumnAssignment(
                        source: source,
                        destination: destination
                    )
                )
            }
        }

        return assignments
    }

    private func makeSpawnSpecs(
        from sourceBoard: GameSession.Board,
        to destinationBoard: GameSession.Board
    ) -> [SpawnSpec] {
        let rowCount = sourceBoard.count
        let columnCount = sourceBoard.first?.count ?? 0
        guard rowCount == destinationBoard.count,
              columnCount == (destinationBoard.first?.count ?? 0) else {
            return []
        }

        var spawnSpecs: [SpawnSpec] = []

        for column in 0..<columnCount {
            let spawnPositions = (0..<rowCount).compactMap { row -> BoardPosition? in
                guard sourceBoard[row][column] == nil,
                      destinationBoard[row][column] != nil else {
                    return nil
                }

                return BoardPosition(row: row, column: column)
            }

            let spawnCount = spawnPositions.count

            for (index, position) in spawnPositions.enumerated() {
                guard let gem = destinationBoard[position.row][position.column] else {
                    continue
                }

                spawnSpecs.append(
                    SpawnSpec(
                        position: position,
                        gem: gem,
                        startRow: -CGFloat(spawnCount - index)
                    )
                )
            }
        }

        return spawnSpecs
    }

    private func fallDuration(fromRow: Int, toRow: Int) -> TimeInterval {
        Layout.fallBaseDuration +
            (Double(abs(toRow - fromRow)) * Layout.fallPerRowDuration)
    }

    private func spawnDuration(fromRow: CGFloat, toRow: Int) -> TimeInterval {
        Layout.spawnBaseDuration +
            (Double(abs(CGFloat(toRow) - fromRow)) * Layout.spawnPerRowDuration)
    }

    private func moveAction(
        to point: CGPoint,
        duration: TimeInterval,
        timingMode: SKActionTimingMode = .easeInEaseOut
    ) -> SKAction {
        let action = SKAction.move(to: point, duration: duration)
        action.timingMode = timingMode
        return action
    }

    private func fadeAction(
        to alpha: CGFloat,
        duration: TimeInterval,
        timingMode: SKActionTimingMode = .easeInEaseOut
    ) -> SKAction {
        let action = SKAction.fadeAlpha(to: alpha, duration: duration)
        action.timingMode = timingMode
        return action
    }

    private func scaleAction(
        to scale: CGFloat,
        duration: TimeInterval,
        timingMode: SKActionTimingMode = .easeInEaseOut
    ) -> SKAction {
        let action = SKAction.scale(to: scale, duration: duration)
        action.timingMode = timingMode
        return action
    }

    private func diamondPath(sideLength: CGFloat) -> CGPath {
        let half = sideLength / 2
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: half))
        path.addLine(to: CGPoint(x: half, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -half))
        path.addLine(to: CGPoint(x: -half, y: 0))
        path.close()
        return path.cgPath
    }

    private func color(for gem: GemType) -> UIColor {
        switch gem {
        case .ruby:
            return UIColor(red: 1.00, green: 0.34, blue: 0.40, alpha: 1)
        case .sapphire:
            return UIColor(red: 0.28, green: 0.58, blue: 1.00, alpha: 1)
        case .emerald:
            return UIColor(red: 0.22, green: 0.86, blue: 0.55, alpha: 1)
        case .topaz:
            return UIColor(red: 1.00, green: 0.76, blue: 0.28, alpha: 1)
        case .amethyst:
            return UIColor(red: 0.72, green: 0.42, blue: 1.00, alpha: 1)
        }
    }
}
