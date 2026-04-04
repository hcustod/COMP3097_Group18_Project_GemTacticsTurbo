//
//  LeaderboardViewModel.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import Foundation

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var selectedDifficulty: Difficulty = .easy
    @Published private(set) var entries: [LeaderboardEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let leaderboardService: LeaderboardService
    private var activeLoadRequestID = 0

    init(leaderboardService: LeaderboardService) {
        self.leaderboardService = leaderboardService
    }

    convenience init() {
        self.init(leaderboardService: LeaderboardService())
    }

    var isUsingLocalLeaderboard: Bool {
        !leaderboardService.isRemoteStoreAvailable
    }

    func loadScores() async {
        activeLoadRequestID += 1
        let requestID = activeLoadRequestID
        let difficulty = selectedDifficulty
        isLoading = true
        errorMessage = nil
        defer {
            if requestID == activeLoadRequestID {
                isLoading = false
            }
        }

        do {
            let fetchedEntries = try await leaderboardService.fetchTopScores(for: difficulty)
            guard requestID == activeLoadRequestID else {
                return
            }

            entries = fetchedEntries
        } catch {
            guard requestID == activeLoadRequestID else {
                return
            }

            entries = []
            errorMessage = error.localizedDescription
        }
    }
}
