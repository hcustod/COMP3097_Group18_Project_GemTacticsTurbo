//
//  UserProfile.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Foundation

struct UserProfile: Codable, Equatable, Sendable {
    /// Wins on Easy (used to unlock Medium after `winsRequiredToUnlockMedium`).
    let winsOnEasy: Int
    /// Wins on Medium (used to unlock Hard after `winsRequiredToUnlockHard`).
    let winsOnMedium: Int

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

    static let winsRequiredToUnlockMedium = 3
    static let winsRequiredToUnlockHard = 5

    init(
        winsOnEasy: Int,
        winsOnMedium: Int,
        uid: String,
        displayName: String,
        email: String?,
        avatarName: String,
        gamesPlayed: Int,
        highestScore: Int,
        totalScore: Int,
        totalMatches: Int,
        unlockedDifficulty: String,
        isGuest: Bool,
        createdAt: Date
    ) {
        self.winsOnEasy = winsOnEasy
        self.winsOnMedium = winsOnMedium
        self.uid = uid
        self.displayName = displayName
        self.email = email
        self.avatarName = avatarName
        self.gamesPlayed = gamesPlayed
        self.highestScore = highestScore
        self.totalScore = totalScore
        self.totalMatches = totalMatches
        self.unlockedDifficulty = unlockedDifficulty
        self.isGuest = isGuest
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case winsOnEasy
        case winsOnMedium
        case uid
        case displayName
        case email
        case avatarName
        case gamesPlayed
        case highestScore
        case totalScore
        case totalMatches
        case unlockedDifficulty
        case isGuest
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        winsOnEasy = try container.decodeIfPresent(Int.self, forKey: .winsOnEasy) ?? 0
        winsOnMedium = try container.decodeIfPresent(Int.self, forKey: .winsOnMedium) ?? 0
        uid = try container.decode(String.self, forKey: .uid)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        avatarName = try container.decode(String.self, forKey: .avatarName)
        gamesPlayed = try container.decode(Int.self, forKey: .gamesPlayed)
        highestScore = try container.decode(Int.self, forKey: .highestScore)
        totalScore = try container.decode(Int.self, forKey: .totalScore)
        totalMatches = try container.decode(Int.self, forKey: .totalMatches)
        unlockedDifficulty = try container.decode(String.self, forKey: .unlockedDifficulty)
        isGuest = try container.decode(Bool.self, forKey: .isGuest)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(winsOnEasy, forKey: .winsOnEasy)
        try container.encode(winsOnMedium, forKey: .winsOnMedium)
        try container.encode(uid, forKey: .uid)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(avatarName, forKey: .avatarName)
        try container.encode(gamesPlayed, forKey: .gamesPlayed)
        try container.encode(highestScore, forKey: .highestScore)
        try container.encode(totalScore, forKey: .totalScore)
        try container.encode(totalMatches, forKey: .totalMatches)
        try container.encode(unlockedDifficulty, forKey: .unlockedDifficulty)
        try container.encode(isGuest, forKey: .isGuest)
        try container.encode(createdAt, forKey: .createdAt)
    }

    var averageScore: Int {
        guard gamesPlayed > 0 else {
            return 0
        }

        return totalScore / gamesPlayed
    }

    static func initial(for user: AuthUser) -> UserProfile {
        UserProfile(
            winsOnEasy: 0,
            winsOnMedium: 0,
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
        var newWinsOnEasy = winsOnEasy
        var newWinsOnMedium = winsOnMedium

        if didWin {
            switch difficulty {
            case .easy:
                newWinsOnEasy += 1
            case .medium:
                newWinsOnMedium += 1
            case .hard:
                break
            }
        }

        var nextUnlockedDifficulty = Difficulty(rawValue: unlockedDifficulty) ?? .easy

        if newWinsOnEasy >= Self.winsRequiredToUnlockMedium {
            nextUnlockedDifficulty = Self.higherRank(nextUnlockedDifficulty, .medium)
        }
        if newWinsOnMedium >= Self.winsRequiredToUnlockHard {
            nextUnlockedDifficulty = Self.higherRank(nextUnlockedDifficulty, .hard)
        }

        return UserProfile(
            winsOnEasy: newWinsOnEasy,
            winsOnMedium: newWinsOnMedium,
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

    private static func higherRank(_ a: Difficulty, _ b: Difficulty) -> Difficulty {
        a.rank >= b.rank ? a : b
    }
}
