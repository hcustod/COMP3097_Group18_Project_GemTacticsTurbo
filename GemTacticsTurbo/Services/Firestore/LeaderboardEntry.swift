//
//  LeaderboardEntry.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Foundation

struct LeaderboardEntry: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let uid: String?
    let displayName: String
    let score: Int
    let difficulty: Difficulty
    let timestamp: Date

    static func make(
        for user: AuthUser,
        score: Int,
        difficulty: Difficulty,
        timestamp: Date = Date()
    ) -> LeaderboardEntry {
        LeaderboardEntry(
            id: UUID().uuidString,
            uid: user.uid,
            displayName: UserProfile.resolvedDisplayName(for: user),
            score: score,
            difficulty: difficulty,
            timestamp: timestamp
        )
    }
}
