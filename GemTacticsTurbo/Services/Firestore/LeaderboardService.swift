//
//  LeaderboardService.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import FirebaseFirestore
import Foundation

final class LeaderboardService {
    private enum LocalKey {
        static let scores = "leaderboard.localScores"
    }

    private let database: Firestore?
    private let defaults: UserDefaults
    private let collectionName = "scores"

    init(
        database: Firestore? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.database = database ?? (FirebaseRuntime.isConfigured ? Firestore.firestore() : nil)
        self.defaults = defaults
    }

    var isRemoteStoreAvailable: Bool {
        database != nil
    }

    func submitScore(entry: LeaderboardEntry) async throws {
        guard let database else {
            saveLocalScore(entry)
            return
        }

        let payload: [String: Any?] = [
            "uid": entry.uid,
            "displayName": entry.displayName,
            "score": entry.score,
            "difficulty": entry.difficulty.rawValue,
            "timestamp": Timestamp(date: entry.timestamp),
        ]
        let cleanedPayload = payload.compactMapValues { $0 }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.collection(collectionName).document(entry.id).setData(cleanedPayload) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
    }

    func submitScore(_ entry: LeaderboardEntry) async throws {
        try await submitScore(entry: entry)
    }

    func fetchTopScores(
        for difficulty: Difficulty,
        limit: Int = 25
    ) async throws -> [LeaderboardEntry] {
        guard let database else {
            return loadLocalScores()
                .filter { $0.difficulty == difficulty }
                .sorted { lhs, rhs in
                    sortEntries(lhs, rhs)
                }
                .prefix(limit)
                .map { $0 }
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[LeaderboardEntry], Error>) in
            database.collection(collectionName)
                .whereField("difficulty", isEqualTo: difficulty.rawValue)
                .order(by: "score", descending: true)
                .limit(to: limit)
                .getDocuments { snapshot, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let scores: [LeaderboardEntry] = snapshot?.documents.map { document in
                        let data = document.data()
                        let timestamp: Date
                        if let storedTimestamp = data["timestamp"] as? Timestamp {
                            timestamp = storedTimestamp.dateValue()
                        } else {
                            timestamp = Date()
                        }

                        return LeaderboardEntry(
                            id: document.documentID,
                            uid: data["uid"] as? String,
                            displayName: data["displayName"] as? String ?? "Unknown",
                            score: data["score"] as? Int ?? 0,
                            difficulty: Difficulty(rawValue: data["difficulty"] as? String ?? difficulty.rawValue) ?? difficulty,
                            timestamp: timestamp
                        )
                    } ?? []

                    continuation.resume(returning: scores)
                }
        }
    }

    private func saveLocalScore(_ entry: LeaderboardEntry) {
        var scores = loadLocalScores()
        scores.removeAll { $0.id == entry.id }
        scores.append(entry)

        guard let data = try? JSONEncoder().encode(scores) else {
            return
        }

        defaults.set(data, forKey: LocalKey.scores)
    }

    private func loadLocalScores() -> [LeaderboardEntry] {
        guard let data = defaults.data(forKey: LocalKey.scores) else {
            return []
        }

        return (try? JSONDecoder().decode([LeaderboardEntry].self, from: data)) ?? []
    }

    private func sortEntries(_ lhs: LeaderboardEntry, _ rhs: LeaderboardEntry) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score > rhs.score
        }

        return lhs.timestamp > rhs.timestamp
    }
}
