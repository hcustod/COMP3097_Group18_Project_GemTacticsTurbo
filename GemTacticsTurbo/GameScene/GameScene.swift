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
        static let boardPadding: CGFloat = 5
        static let boardBackgroundOutset: CGFloat = 6
        static let tileSpacingRatio: CGFloat = 0.045
        static let minimumTileSpacing: CGFloat = 2
        static let maximumTileSpacing: CGFloat = 5
        static let gemInset: CGFloat = 6
        static let boardCornerRadius: CGFloat = 18
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

    private enum GemSilhouette {
        case rubyOctagon
        case sapphireRound
        case emeraldCut
        case topazTrillion
        case amethystShard
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
            rectOf: CGSize(
                width: boardWidth + Layout.boardBackgroundOutset,
                height: boardHeight + Layout.boardBackgroundOutset
            ),
            cornerRadius: Layout.boardCornerRadius
        )
        boardBackground.fillColor = UIColor(red: 0.04, green: 0.05, blue: 0.15, alpha: 0.96)
        boardBackground.strokeColor = UIColor(red: 0.52, green: 0.96, blue: 1.00, alpha: 0.42)
        boardBackground.lineWidth = 2
        boardBackground.glowWidth = 2.2
        boardBackground.zPosition = -1

        let boardInnerGlow = SKShapeNode(
            rectOf: CGSize(
                width: max(boardWidth - tileSpacing, 1),
                height: max(boardHeight - tileSpacing, 1)
            ),
            cornerRadius: max(Layout.boardCornerRadius - 4, 1)
        )
        boardInnerGlow.fillColor = .clear
        boardInnerGlow.strokeColor = UIColor(red: 1.00, green: 0.62, blue: 0.16, alpha: 0.12)
        boardInnerGlow.lineWidth = 2
        boardInnerGlow.zPosition = 1
        boardBackground.addChild(boardInnerGlow)

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
        let cornerRadius = max(tileSize * 0.14, 6)
        let tileNode = SKShapeNode(
            rectOf: CGSize(width: tileSize, height: tileSize),
            cornerRadius: cornerRadius
        )
        tileNode.fillColor = UIColor(red: 0.05, green: 0.09, blue: 0.25, alpha: 0.96)
        tileNode.strokeColor = UIColor(red: 0.38, green: 0.92, blue: 1.00, alpha: 0.20)
        tileNode.lineWidth = 1.2

        let inset = max(tileSize * 0.10, 4)
        let innerRim = SKShapeNode(
            rectOf: CGSize(
                width: max(tileSize - inset, 1),
                height: max(tileSize - inset, 1)
            ),
            cornerRadius: max(cornerRadius - 3, 1)
        )
        innerRim.fillColor = .clear
        innerRim.strokeColor = UIColor(red: 0.46, green: 1.00, blue: 0.96, alpha: 0.13)
        innerRim.lineWidth = 1
        innerRim.zPosition = 1
        tileNode.addChild(innerRim)

        let topHighlight = SKShapeNode(
            rectOf: CGSize(
                width: max(tileSize * 0.62, 1),
                height: max(tileSize * 0.045, 2)
            ),
            cornerRadius: 1
        )
        topHighlight.fillColor = UIColor.white.withAlphaComponent(0.15)
        topHighlight.strokeColor = .clear
        topHighlight.position = CGPoint(x: 0, y: tileSize * 0.32)
        topHighlight.zPosition = 2
        tileNode.addChild(topHighlight)

        let lowerShade = SKShapeNode(
            rectOf: CGSize(
                width: max(tileSize * 0.70, 1),
                height: max(tileSize * 0.10, 3)
            ),
            cornerRadius: 2
        )
        lowerShade.fillColor = UIColor.black.withAlphaComponent(0.20)
        lowerShade.strokeColor = .clear
        lowerShade.position = CGPoint(x: 0, y: -tileSize * 0.31)
        lowerShade.zPosition = 2
        tileNode.addChild(lowerShade)

        return tileNode
    }

    private func makeGemNode(for gem: GemType) -> GemSpriteNode {
        let gemNode = GemSpriteNode(gemType: gem)
        let gemSideLength = max(tileSize - Layout.gemInset, 10)
        let silhouette = gemSilhouette(for: gem)
        let gemPath = gemPath(for: silhouette, sideLength: gemSideLength)

        let dropShadow = SKShapeNode(path: gemPath)
        dropShadow.fillColor = shadowColor(for: gem).withAlphaComponent(0.92)
        dropShadow.strokeColor = UIColor.black.withAlphaComponent(0.55)
        dropShadow.lineWidth = max(gemSideLength * 0.05, 2)
        dropShadow.position = CGPoint(
            x: max(gemSideLength * 0.055, 2),
            y: -max(gemSideLength * 0.065, 2)
        )
        dropShadow.zPosition = -2
        gemNode.addChild(dropShadow)

        let darkRim = SKShapeNode(path: gemPath)
        darkRim.fillColor = shadowColor(for: gem)
        darkRim.strokeColor = UIColor.black.withAlphaComponent(0.72)
        darkRim.lineWidth = max(gemSideLength * 0.08, 2.5)
        darkRim.zPosition = -1
        gemNode.addChild(darkRim)

        let gemShape = SKShapeNode(path: gemPath)
        gemShape.fillColor = color(for: gem)
        gemShape.strokeColor = UIColor.white.withAlphaComponent(0.38)
        gemShape.lineWidth = max(gemSideLength * 0.025, 1.25)
        gemShape.glowWidth = max(gemSideLength * 0.02, 0.8)
        gemShape.zPosition = 0
        gemNode.addChild(gemShape)

        let lowerShade = SKShapeNode(
            path: shadePath(for: silhouette, sideLength: gemSideLength)
        )
        lowerShade.fillColor = shadowColor(for: gem).withAlphaComponent(0.34)
        lowerShade.strokeColor = .clear
        lowerShade.zPosition = 1
        gemNode.addChild(lowerShade)

        let facets = SKShapeNode(
            path: facetPath(for: silhouette, sideLength: gemSideLength)
        )
        facets.fillColor = .clear
        facets.strokeColor = UIColor.white.withAlphaComponent(0.30)
        facets.lineWidth = max(gemSideLength * 0.022, 1)
        facets.zPosition = 2
        gemNode.addChild(facets)

        let highlight = SKShapeNode(
            path: highlightPath(sideLength: gemSideLength)
        )
        highlight.fillColor = UIColor.white.withAlphaComponent(0.34)
        highlight.strokeColor = UIColor.white.withAlphaComponent(0.20)
        highlight.lineWidth = 1
        highlight.zPosition = 3
        gemNode.addChild(highlight)

        addPixelSparkle(to: gemNode, sideLength: gemSideLength)

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
                ? UIColor(red: 1.00, green: 0.74, blue: 0.20, alpha: 0.96)
                : UIColor(red: 0.38, green: 0.92, blue: 1.00, alpha: 0.20)
            tileNode.lineWidth = isSelected ? Layout.selectedStrokeWidth : 1.2
            tileNode.fillColor = isSelected
                ? UIColor(red: 0.16, green: 0.12, blue: 0.30, alpha: 0.98)
                : UIColor(red: 0.05, green: 0.09, blue: 0.25, alpha: 0.96)

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

    private func gemSilhouette(for gem: GemType) -> GemSilhouette {
        switch gem {
        case .ruby:
            return .rubyOctagon
        case .sapphire:
            return .sapphireRound
        case .emerald:
            return .emeraldCut
        case .topaz:
            return .topazTrillion
        case .amethyst:
            return .amethystShard
        }
    }

    private func gemPath(
        for silhouette: GemSilhouette,
        sideLength: CGFloat
    ) -> CGPath {
        switch silhouette {
        case .rubyOctagon:
            return octagonPath(sideLength: sideLength)
        case .sapphireRound:
            return polygonPath(sides: 10, radius: sideLength / 2)
        case .emeraldCut:
            return emeraldCutPath(sideLength: sideLength)
        case .topazTrillion:
            return trillionPath(sideLength: sideLength)
        case .amethystShard:
            return shardPath(sideLength: sideLength)
        }
    }

    private func octagonPath(sideLength: CGFloat) -> CGPath {
        let half = sideLength / 2
        let cut = sideLength * 0.17

        return path(from: [
            CGPoint(x: -half + cut, y: half),
            CGPoint(x: half - cut, y: half),
            CGPoint(x: half, y: half - cut),
            CGPoint(x: half, y: -half + cut),
            CGPoint(x: half - cut, y: -half),
            CGPoint(x: -half + cut, y: -half),
            CGPoint(x: -half, y: -half + cut),
            CGPoint(x: -half, y: half - cut)
        ])
    }

    private func emeraldCutPath(sideLength: CGFloat) -> CGPath {
        let halfWidth = sideLength * 0.42
        let halfHeight = sideLength / 2
        let cutX = sideLength * 0.13
        let cutY = sideLength * 0.10

        return path(from: [
            CGPoint(x: -halfWidth + cutX, y: halfHeight),
            CGPoint(x: halfWidth - cutX, y: halfHeight),
            CGPoint(x: halfWidth, y: halfHeight - cutY),
            CGPoint(x: halfWidth, y: -halfHeight + cutY),
            CGPoint(x: halfWidth - cutX, y: -halfHeight),
            CGPoint(x: -halfWidth + cutX, y: -halfHeight),
            CGPoint(x: -halfWidth, y: -halfHeight + cutY),
            CGPoint(x: -halfWidth, y: halfHeight - cutY)
        ])
    }

    private func trillionPath(sideLength: CGFloat) -> CGPath {
        let half = sideLength / 2

        return path(from: [
            CGPoint(x: 0, y: half),
            CGPoint(x: half, y: -half * 0.24),
            CGPoint(x: half * 0.22, y: -half),
            CGPoint(x: -half * 0.22, y: -half),
            CGPoint(x: -half, y: -half * 0.24)
        ])
    }

    private func shardPath(sideLength: CGFloat) -> CGPath {
        let half = sideLength / 2

        return path(from: [
            CGPoint(x: 0, y: half),
            CGPoint(x: half * 0.48, y: half * 0.14),
            CGPoint(x: half * 0.34, y: -half * 0.72),
            CGPoint(x: 0, y: -half),
            CGPoint(x: -half * 0.38, y: -half * 0.62),
            CGPoint(x: -half * 0.50, y: half * 0.08)
        ])
    }

    private func polygonPath(
        sides: Int,
        radius: CGFloat,
        yScale: CGFloat = 1,
        rotation: CGFloat = -CGFloat.pi / 2
    ) -> CGPath {
        let angleStep = (CGFloat.pi * 2) / CGFloat(max(sides, 3))
        let points = (0..<max(sides, 3)).map { index -> CGPoint in
            let angle = rotation + (CGFloat(index) * angleStep)

            return CGPoint(
                x: CGFloat(cos(Double(angle))) * radius,
                y: CGFloat(sin(Double(angle))) * radius * yScale
            )
        }

        return path(from: points)
    }

    private func path(from points: [CGPoint]) -> CGPath {
        let path = UIBezierPath()

        guard let firstPoint = points.first else {
            return path.cgPath
        }

        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        path.close()
        return path.cgPath
    }

    private func facetPath(
        for silhouette: GemSilhouette,
        sideLength: CGFloat
    ) -> CGPath {
        let half = sideLength / 2
        let path = UIBezierPath()

        switch silhouette {
        case .rubyOctagon:
            addLine(to: path, from: .zero, to: CGPoint(x: 0, y: half * 0.82))
            addLine(to: path, from: .zero, to: CGPoint(x: half * 0.82, y: 0))
            addLine(to: path, from: .zero, to: CGPoint(x: 0, y: -half * 0.82))
            addLine(to: path, from: .zero, to: CGPoint(x: -half * 0.82, y: 0))
            addLine(
                to: path,
                from: CGPoint(x: -half * 0.42, y: half * 0.42),
                to: CGPoint(x: half * 0.42, y: -half * 0.42)
            )

        case .sapphireRound:
            for index in 0..<8 {
                let angle = (-CGFloat.pi / 2) + (CGFloat(index) * CGFloat.pi / 4)
                addLine(
                    to: path,
                    from: .zero,
                    to: CGPoint(
                        x: CGFloat(cos(Double(angle))) * half * 0.80,
                        y: CGFloat(sin(Double(angle))) * half * 0.80
                    )
                )
            }

        case .emeraldCut:
            let width = sideLength * 0.34
            let height = sideLength * 0.38
            path.append(
                UIBezierPath(
                    rect: CGRect(
                        x: -width,
                        y: -height,
                        width: width * 2,
                        height: height * 2
                    )
                )
            )
            addLine(to: path, from: CGPoint(x: -half * 0.42, y: 0), to: CGPoint(x: half * 0.42, y: 0))
            addLine(to: path, from: CGPoint(x: 0, y: -half * 0.46), to: CGPoint(x: 0, y: half * 0.46))

        case .topazTrillion:
            addLine(to: path, from: CGPoint(x: 0, y: half * 0.82), to: CGPoint(x: 0, y: -half * 0.70))
            addLine(to: path, from: CGPoint(x: 0, y: half * 0.82), to: CGPoint(x: half * 0.42, y: -half * 0.22))
            addLine(to: path, from: CGPoint(x: 0, y: half * 0.82), to: CGPoint(x: -half * 0.42, y: -half * 0.22))
            addLine(to: path, from: CGPoint(x: -half * 0.62, y: -half * 0.18), to: CGPoint(x: half * 0.62, y: -half * 0.18))

        case .amethystShard:
            addLine(to: path, from: CGPoint(x: 0, y: half * 0.82), to: CGPoint(x: 0, y: -half * 0.82))
            addLine(to: path, from: CGPoint(x: -half * 0.42, y: half * 0.08), to: CGPoint(x: 0, y: half * 0.82))
            addLine(to: path, from: CGPoint(x: half * 0.38, y: half * 0.10), to: CGPoint(x: 0, y: -half * 0.82))
            addLine(to: path, from: CGPoint(x: -half * 0.30, y: -half * 0.58), to: CGPoint(x: half * 0.30, y: -half * 0.54))
        }

        return path.cgPath
    }

    private func shadePath(
        for silhouette: GemSilhouette,
        sideLength: CGFloat
    ) -> CGPath {
        let half = sideLength / 2

        switch silhouette {
        case .rubyOctagon:
            return path(from: [
                CGPoint(x: -half * 0.70, y: -half * 0.10),
                CGPoint(x: half * 0.70, y: -half * 0.10),
                CGPoint(x: half * 0.48, y: -half * 0.78),
                CGPoint(x: -half * 0.48, y: -half * 0.78)
            ])

        case .sapphireRound:
            return path(from: [
                CGPoint(x: -half * 0.64, y: -half * 0.08),
                CGPoint(x: half * 0.64, y: -half * 0.08),
                CGPoint(x: half * 0.36, y: -half * 0.70),
                CGPoint(x: 0, y: -half * 0.82),
                CGPoint(x: -half * 0.36, y: -half * 0.70)
            ])

        case .emeraldCut:
            return path(from: [
                CGPoint(x: -half * 0.34, y: -half * 0.08),
                CGPoint(x: half * 0.34, y: -half * 0.08),
                CGPoint(x: half * 0.32, y: -half * 0.74),
                CGPoint(x: -half * 0.32, y: -half * 0.74)
            ])

        case .topazTrillion:
            return path(from: [
                CGPoint(x: -half * 0.62, y: -half * 0.18),
                CGPoint(x: half * 0.62, y: -half * 0.18),
                CGPoint(x: half * 0.20, y: -half * 0.82),
                CGPoint(x: -half * 0.20, y: -half * 0.82)
            ])

        case .amethystShard:
            return path(from: [
                CGPoint(x: -half * 0.34, y: -half * 0.22),
                CGPoint(x: half * 0.28, y: -half * 0.18),
                CGPoint(x: half * 0.18, y: -half * 0.70),
                CGPoint(x: 0, y: -half * 0.86),
                CGPoint(x: -half * 0.28, y: -half * 0.56)
            ])
        }
    }

    private func highlightPath(sideLength: CGFloat) -> CGPath {
        let half = sideLength / 2
        let size = max(sideLength * 0.11, 3)
        let origin = CGPoint(x: -half * 0.32, y: half * 0.26)

        return path(from: [
            CGPoint(x: origin.x, y: origin.y + size),
            CGPoint(x: origin.x + size * 0.70, y: origin.y + size * 0.42),
            CGPoint(x: origin.x + size * 0.36, y: origin.y - size * 0.45),
            CGPoint(x: origin.x - size * 0.48, y: origin.y - size * 0.16)
        ])
    }

    private func addPixelSparkle(
        to gemNode: GemSpriteNode,
        sideLength: CGFloat
    ) {
        let arm = max(sideLength * 0.045, 2)
        let sparklePath = UIBezierPath()
        addLine(
            to: sparklePath,
            from: CGPoint(x: 0, y: -arm),
            to: CGPoint(x: 0, y: arm)
        )
        addLine(
            to: sparklePath,
            from: CGPoint(x: -arm, y: 0),
            to: CGPoint(x: arm, y: 0)
        )

        let sparkle = SKShapeNode(path: sparklePath.cgPath)
        sparkle.strokeColor = UIColor.white.withAlphaComponent(0.58)
        sparkle.lineWidth = max(sideLength * 0.018, 1)
        sparkle.position = CGPoint(x: sideLength * 0.24, y: sideLength * 0.25)
        sparkle.zPosition = 4
        gemNode.addChild(sparkle)
    }

    private func addLine(
        to path: UIBezierPath,
        from startPoint: CGPoint,
        to endPoint: CGPoint
    ) {
        path.move(to: startPoint)
        path.addLine(to: endPoint)
    }

    private func color(for gem: GemType) -> UIColor {
        switch gem {
        case .ruby:
            return UIColor(red: 1.00, green: 0.16, blue: 0.27, alpha: 1)
        case .sapphire:
            return UIColor(red: 0.20, green: 0.52, blue: 1.00, alpha: 1)
        case .emerald:
            return UIColor(red: 0.08, green: 0.88, blue: 0.48, alpha: 1)
        case .topaz:
            return UIColor(red: 1.00, green: 0.72, blue: 0.10, alpha: 1)
        case .amethyst:
            return UIColor(red: 0.70, green: 0.28, blue: 1.00, alpha: 1)
        }
    }

    private func shadowColor(for gem: GemType) -> UIColor {
        switch gem {
        case .ruby:
            return UIColor(red: 0.45, green: 0.02, blue: 0.12, alpha: 1)
        case .sapphire:
            return UIColor(red: 0.04, green: 0.14, blue: 0.55, alpha: 1)
        case .emerald:
            return UIColor(red: 0.02, green: 0.34, blue: 0.20, alpha: 1)
        case .topaz:
            return UIColor(red: 0.58, green: 0.30, blue: 0.02, alpha: 1)
        case .amethyst:
            return UIColor(red: 0.32, green: 0.05, blue: 0.56, alpha: 1)
        }
    }
}
