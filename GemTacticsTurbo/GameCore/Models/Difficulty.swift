//
//  Difficulty.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

enum Difficulty: String, CaseIterable, Hashable, Sendable, Codable {
    case easy
    case medium
    case hard

    var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .hard:
            return "Hard"
        }
    }

    var moveLimit: Int {
        switch self {
        case .easy:
            return 30
        case .medium:
            return 25
        case .hard:
            return 20
        }
    }

    var timeLimit: Int {
        switch self {
        case .easy:
            return 120
        case .medium:
            return 90
        case .hard:
            return 60
        }
    }

    var targetScore: Int {
        switch self {
        case .easy:
            return 4_000
        case .medium:
            return 8_000
        case .hard:
            return 12_000
        }
    }

    var scoreMultiplier: Double {
        switch self {
        case .easy:
            return 1.0
        case .medium:
            return 1.5
        case .hard:
            return 2.0
        }
    }

    var rank: Int {
        switch self {
        case .easy:
            return 0
        case .medium:
            return 1
        case .hard:
            return 2
        }
    }
}
