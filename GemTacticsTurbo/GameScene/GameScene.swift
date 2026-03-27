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
        static let tileInset: CGFloat = 6
        static let gemInset: CGFloat = 16
        static let boardCornerRadius: CGFloat = 28
        static let selectedStrokeWidth: CGFloat = 3
        static let swapDuration: TimeInterval = 0.14
        static let swapBackDuration: TimeInterval = 0.12
        static let clearDuration: TimeInterval = 0.10
        static let refillDuration: TimeInterval = 0.18
        static let refillDropDistance: CGFloat = 26
    }

    private let boardNode = SKNode()
    private let tileLayer = SKNode()
    private let gemLayer = SKNode()
    private var boardBackgroundNode: SKShapeNode?
    private var currentBoard: GameSession.Board = GameSession.emptyBoard()
    private var tileNodes: [BoardPosition: SKShapeNode] = [:]
    private var gemNodes: [BoardPosition: SKNode] = [:]
    private var selectedPosition: BoardPosition?
    private var cellSize: CGFloat = 0
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
            let sourceNode = gemNodes[swap.source],
            let destinationNode = gemNodes[swap.destination]
        else {
            completion()
            return
        }

        isAnimatingBoard = true
        clearSelection()

        let sourcePoint = pointForPosition(swap.source)
        let destinationPoint = pointForPosition(swap.destination)
        let moveOut = SKAction.move(to: destinationPoint, duration: Layout.swapDuration)
        let moveBack = SKAction.move(to: sourcePoint, duration: Layout.swapBackDuration)
        let destinationMoveOut = SKAction.move(to: sourcePoint, duration: Layout.swapDuration)
        let destinationMoveBack = SKAction.move(to: destinationPoint, duration: Layout.swapBackDuration)

        flashInvalidSelection(positions: [swap.source, swap.destination])

        sourceNode.run(.sequence([moveOut, moveBack]))
        destinationNode.run(.sequence([destinationMoveOut, destinationMoveBack]))

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
        updatedBoard: GameSession.Board,
        completion: @escaping () -> Void
    ) {
        guard
            let sourceNode = gemNodes[swap.source],
            let destinationNode = gemNodes[swap.destination]
        else {
            render(board: updatedBoard)
            animateBoardReveal(completion: completion)
            return
        }

        isAnimatingBoard = true
        clearSelection()

        let sourcePoint = pointForPosition(swap.source)
        let destinationPoint = pointForPosition(swap.destination)
        let sourceMove = SKAction.move(to: destinationPoint, duration: Layout.swapDuration)
        let destinationMove = SKAction.move(to: sourcePoint, duration: Layout.swapDuration)

        sourceNode.run(sourceMove)
        destinationNode.run(destinationMove)

        run(
            .sequence([
                .wait(forDuration: Layout.swapDuration),
                .run { [weak self] in
                    self?.animateBoardRefresh(to: updatedBoard, completion: completion)
                }
            ])
        )
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
            gemNodes[position] != nil
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
        gemNodes = [:]

        let rows = currentBoard.count
        let columns = currentBoard.first?.count ?? 0

        guard rows > 0, columns > 0 else {
            return
        }

        let availableWidth = max(size.width - (Layout.boardPadding * 2), 1)
        let availableHeight = max(size.height - (Layout.boardPadding * 2), 1)
        cellSize = min(
            availableWidth / CGFloat(columns),
            availableHeight / CGFloat(rows)
        )
        boardWidth = cellSize * CGFloat(columns)
        boardHeight = cellSize * CGFloat(rows)
        boardRows = rows
        boardColumns = columns

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
                let position = pointForPosition(boardPosition)

                let tileNode = makeTileNode()
                tileNode.position = position
                tileLayer.addChild(tileNode)
                tileNodes[boardPosition] = tileNode

                if let gem = currentBoard[row][column] {
                    let gemNode = makeGemNode(for: gem)
                    gemNode.position = position
                    gemLayer.addChild(gemNode)
                    gemNodes[boardPosition] = gemNode
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

    private func pointForPosition(_ position: BoardPosition) -> CGPoint {
        let x = (-boardWidth / 2) + (CGFloat(position.column) * cellSize) + (cellSize / 2)
        let y = (boardHeight / 2) - (CGFloat(position.row) * cellSize) - (cellSize / 2)
        return CGPoint(x: x, y: y)
    }

    private func boardPosition(for location: CGPoint) -> BoardPosition? {
        guard boardRows > 0, boardColumns > 0, cellSize > 0 else {
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

        let column = Int((location.x - minX) / cellSize)
        let row = Int((maxY - location.y) / cellSize)

        guard row >= 0, row < boardRows, column >= 0, column < boardColumns else {
            return nil
        }

        return BoardPosition(row: row, column: column)
    }

    private func makeTileNode() -> SKShapeNode {
        let tileNode = SKShapeNode(
            rectOf: CGSize(
                width: max(cellSize - Layout.tileInset, 1),
                height: max(cellSize - Layout.tileInset, 1)
            ),
            cornerRadius: max(cellSize * 0.18, 8)
        )
        tileNode.fillColor = UIColor(red: 0.12, green: 0.10, blue: 0.24, alpha: 0.92)
        tileNode.strokeColor = UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.10)
        tileNode.lineWidth = 1
        return tileNode
    }

    private func makeGemNode(for gem: GemType) -> SKNode {
        let gemNode = SKNode()
        gemNode.name = gem.assetName
        gemNode.zPosition = 2

        let gemShape = SKShapeNode(
            path: diamondPath(sideLength: max(cellSize - Layout.gemInset, 10))
        )
        gemShape.fillColor = color(for: gem)
        gemShape.strokeColor = UIColor.white.withAlphaComponent(0.35)
        gemShape.lineWidth = 1.5
        gemShape.glowWidth = 1
        gemNode.addChild(gemShape)

        let shineShape = SKShapeNode(circleOfRadius: max((cellSize - Layout.gemInset) * 0.12, 3))
        shineShape.fillColor = UIColor.white.withAlphaComponent(0.30)
        shineShape.strokeColor = .clear
        shineShape.position = CGPoint(
            x: max((cellSize - Layout.gemInset) * -0.16, -8),
            y: max((cellSize - Layout.gemInset) * 0.18, 8)
        )
        gemNode.addChild(shineShape)

        let labelNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
        labelNode.text = String(gem.displayName.prefix(1))
        labelNode.fontSize = max(cellSize * 0.22, 10)
        labelNode.verticalAlignmentMode = .center
        labelNode.fontColor = UIColor.white.withAlphaComponent(0.92)
        labelNode.position = CGPoint(x: 0, y: -labelNode.fontSize * 0.08)
        gemNode.addChild(labelNode)

        return gemNode
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

            if let gemNode = gemNodes[position] {
                gemNode.removeAction(forKey: "selectionScale")
                let targetScale: CGFloat = isSelected ? 1.07 : 1
                gemNode.run(
                    .scale(to: targetScale, duration: 0.10),
                    withKey: "selectionScale"
                )
            }
        }
    }

    private func pulseGem(at position: BoardPosition) {
        guard let gemNode = gemNodes[position] else {
            return
        }

        gemNode.removeAction(forKey: "selectionPulse")
        gemNode.run(
            .sequence([
                .scale(to: 1.10, duration: 0.08),
                .scale(to: 1.07, duration: 0.08)
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

    private func animateBoardRefresh(
        to updatedBoard: GameSession.Board,
        completion: @escaping () -> Void
    ) {
        let currentGemNodes = Array(gemNodes.values)

        guard !currentGemNodes.isEmpty else {
            render(board: updatedBoard)
            animateBoardReveal(completion: completion)
            return
        }

        for node in currentGemNodes {
            node.run(
                .group([
                    .fadeAlpha(to: 0.18, duration: Layout.clearDuration),
                    .scale(to: 0.76, duration: Layout.clearDuration)
                ])
            )
        }

        run(
            .sequence([
                .wait(forDuration: Layout.clearDuration),
                .run { [weak self] in
                    guard let self else {
                        completion()
                        return
                    }

                    self.render(board: updatedBoard)
                    self.animateBoardReveal(completion: completion)
                }
            ])
        )
    }

    private func animateBoardReveal(completion: @escaping () -> Void) {
        if gemNodes.isEmpty {
            isAnimatingBoard = false
            completion()
            return
        }

        for (position, node) in gemNodes {
            let finalPosition = node.position
            let delay = Double(position.row) * 0.018
            node.alpha = 0
            node.setScale(0.72)
            node.position = CGPoint(x: finalPosition.x, y: finalPosition.y + Layout.refillDropDistance)

            node.run(
                .sequence([
                    .wait(forDuration: delay),
                    .group([
                        .fadeIn(withDuration: Layout.refillDuration),
                        .move(to: finalPosition, duration: Layout.refillDuration),
                        .scale(to: 1, duration: Layout.refillDuration)
                    ])
                ])
            )
        }

        let totalDuration = Layout.refillDuration + (Double(boardRows) * 0.018)
        run(
            .sequence([
                .wait(forDuration: totalDuration),
                .run { [weak self] in
                    self?.isAnimatingBoard = false
                    completion()
                }
            ])
        )
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
