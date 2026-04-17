//
//  ProfileService.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//  Author: Tyson Ward-Dicks - 101501186
//  Changes: Added local profile storage support for locally registered and guest users.
//

import FirebaseFirestore
import Foundation

final class ProfileService {
    static let didUpdateProfileNotification = Notification.Name("ProfileService.didUpdateProfile")

    private let database: Firestore?
    private let defaults: UserDefaults
    private let collectionName = "users"
    private let localProfileKeyPrefix = "profile.local"

    init(
        database: Firestore? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.database = database ?? (FirebaseRuntime.isConfigured ? Firestore.firestore() : nil)
        self.defaults = defaults
    }

    func createInitialProfile(for user: AuthUser) async throws {
        let profile = UserProfile.initial(for: user)
        try await updateProfile(profile)
    }

    func fetchProfile(for user: AuthUser) async throws -> UserProfile? {
        // Local builds read profiles from UserDefaults, backend builds read Firestore.
        if database == nil {
            return loadLocalProfile(uid: user.uid) ?? fallbackProfile(for: user)
        }

        return try await fetchProfile(uid: user.uid)
    }

    func fetchProfile(uid: String) async throws -> UserProfile? {
        guard let database else {
            throw FirestoreServiceError.firebaseUnavailable
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UserProfile?, Error>) in
            database.collection(collectionName).document(uid).getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data = snapshot?.data() else {
                    continuation.resume(returning: nil)
                    return
                }

                let createdAt: Date
                if let timestamp = data["createdAt"] as? Timestamp {
                    createdAt = timestamp.dateValue()
                } else {
                    createdAt = Date()
                }

                let profile = UserProfile(
                    winsOnEasy: data["winsOnEasy"] as? Int ?? 0,
                    winsOnMedium: data["winsOnMedium"] as? Int ?? 0,
                    uid: data["uid"] as? String ?? uid,
                    displayName: data["displayName"] as? String ?? "Player",
                    email: data["email"] as? String,
                    avatarName: data["avatarName"] as? String ?? "Starter Gem",
                    gamesPlayed: data["gamesPlayed"] as? Int ?? 0,
                    highestScore: data["highestScore"] as? Int ?? 0,
                    totalScore: data["totalScore"] as? Int ?? 0,
                    totalMatches: data["totalMatches"] as? Int ?? 0,
                    unlockedDifficulty: data["unlockedDifficulty"] as? String ?? "easy",
                    isGuest: data["isGuest"] as? Bool ?? false,
                    createdAt: createdAt
                )

                continuation.resume(returning: profile)
            }
        }
    }

    func updateProfile(_ profile: UserProfile) async throws {
        if database == nil {
            // Save locally first so auth/profile flow works without cloud setup.
            saveLocalProfile(profile)
            notifyProfileDidUpdate(uid: profile.uid)
            return
        }

        try await writeProfile(profile, merge: true)
        notifyProfileDidUpdate(uid: profile.uid)
    }

    func recordCompletedGame(
        for user: AuthUser,
        difficulty: Difficulty,
        finalScore: Int,
        totalMatchGroups: Int,
        didWin: Bool
    ) async throws -> UserProfile {
        let existingProfile = try await fetchProfile(for: user) ?? UserProfile.initial(for: user)
        let updatedProfile = existingProfile.recordingCompletedGame(
            score: finalScore,
            difficulty: difficulty,
            totalMatchGroups: totalMatchGroups,
            didWin: didWin
        )

        try await updateProfile(updatedProfile)
        return updatedProfile
    }

    private func writeProfile(_ profile: UserProfile, merge: Bool) async throws {
        guard let database else {
            throw FirestoreServiceError.firebaseUnavailable
        }

        let payload: [String: Any?] = [
            "uid": profile.uid,
            "displayName": profile.displayName,
            "email": profile.email,
            "avatarName": profile.avatarName,
            "gamesPlayed": profile.gamesPlayed,
            "highestScore": profile.highestScore,
            "totalScore": profile.totalScore,
            "totalMatches": profile.totalMatches,
            "winsOnEasy": profile.winsOnEasy,
            "winsOnMedium": profile.winsOnMedium,
            "unlockedDifficulty": profile.unlockedDifficulty,
            "isGuest": profile.isGuest,
            "createdAt": Timestamp(date: profile.createdAt),
        ]
        let cleanedPayload = payload.compactMapValues { $0 }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.collection(collectionName).document(profile.uid).setData(cleanedPayload, merge: merge) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
    }

    func deleteProfile(uid: String) {
        defaults.removeObject(forKey: localProfileKey(for: uid))
    }

    private func loadLocalProfile(uid: String) -> UserProfile? {
        guard let data = defaults.data(forKey: localProfileKey(for: uid)) else {
            return nil
        }

        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    private func saveLocalProfile(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else {
            return
        }

        defaults.set(data, forKey: localProfileKey(for: profile.uid))
    }

    private func localProfileKey(for uid: String) -> String {
        "\(localProfileKeyPrefix).\(uid)"
    }

    private func fallbackProfile(for user: AuthUser) -> UserProfile {
        user.isGuest ? UserProfile.guestFallback(for: user) : UserProfile.initial(for: user)
    }

    private func notifyProfileDidUpdate(uid: String) {
        // Views use this to refresh after score/profile changes.
        NotificationCenter.default.post(
            name: Self.didUpdateProfileNotification,
            object: uid
        )
    }
}
