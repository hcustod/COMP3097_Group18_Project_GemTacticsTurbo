//
//  UserProfile.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Foundation

struct UserProfile: Codable, Equatable, Sendable {
    let uid: String
    let displayName: String
    let email: String?
    let avatarName: String
    let gamesPlayed: Int
    let highestScore: Int
    let totalScore: Int
    let totalMatches: Int
    let unlockedDifficulty: String
    let isGuest: Bool
    let createdAt: Date

    var averageScore: Int {
        guard gamesPlayed > 0 else {
            return 0
        }

        return totalScore / gamesPlayed
    }

    static func initial(for user: AuthUser) -> UserProfile {
        UserProfile(
            uid: user.uid,
            displayName: resolvedDisplayName(for: user),
            email: user.email,
            avatarName: user.isGuest ? "Guest Gem" : "Starter Gem",
            gamesPlayed: 0,
            highestScore: 0,
            totalScore: 0,
            totalMatches: 0,
            unlockedDifficulty: "easy",
            isGuest: user.isGuest,
            createdAt: Date()
        )
    }

    static func guestFallback(for user: AuthUser) -> UserProfile {
        initial(for: user)
    }

    static func resolvedDisplayName(for user: AuthUser) -> String {
        let trimmedDisplayName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedDisplayName.isEmpty {
            return trimmedDisplayName
        }

        if let email = user.email, let localPart = email.split(separator: "@").first, !localPart.isEmpty {
            return String(localPart)
        }

        return user.isGuest ? "Guest Player" : "Player"
    }

    func recordingCompletedGame(
        score: Int,
        difficulty: Difficulty,
        totalMatchGroups: Int,
        didWin: Bool
    ) -> UserProfile {
        let currentUnlockedDifficulty = Difficulty(rawValue: unlockedDifficulty) ?? .easy
        let nextUnlockedDifficulty: Difficulty

        if didWin, difficulty.rank > currentUnlockedDifficulty.rank {
            nextUnlockedDifficulty = difficulty
        } else {
            nextUnlockedDifficulty = currentUnlockedDifficulty
        }

        return UserProfile(
            uid: uid,
            displayName: displayName,
            email: email,
            avatarName: avatarName,
            gamesPlayed: gamesPlayed + 1,
            highestScore: max(highestScore, score),
            totalScore: totalScore + score,
            // MVP metric: totalMatches counts the number of distinct match groups
            // resolved across every cascade step in a finished round.
            totalMatches: totalMatches + max(0, totalMatchGroups),
            unlockedDifficulty: nextUnlockedDifficulty.rawValue,
            isGuest: isGuest,
            createdAt: createdAt
        )
    }
}
