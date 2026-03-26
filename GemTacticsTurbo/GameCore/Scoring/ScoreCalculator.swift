//
//  ScoreCalculator.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

enum ScoreCalculator {
    static let basePointsPerGem = 100
    static let extraMatchBonusPerGem = 50
    static let comboStepMultiplier = 0.25

    static func score(
        for matches: [Match],
        cascadeDepth: Int,
        difficulty: Difficulty
    ) -> Int {
        let baseScore = matches.reduce(0) { partialResult, match in
            partialResult + score(for: match)
        }

        let comboMultiplier = 1.0 + (Double(max(0, cascadeDepth - 1)) * comboStepMultiplier)
        let scaledScore = Double(baseScore) * comboMultiplier * difficulty.scoreMultiplier
        return Int(scaledScore.rounded())
    }

    static func score(for match: Match) -> Int {
        let bonusGems = max(0, match.length - 3)
        return (match.length * basePointsPerGem) + (bonusGems * extraMatchBonusPerGem)
    }
}
