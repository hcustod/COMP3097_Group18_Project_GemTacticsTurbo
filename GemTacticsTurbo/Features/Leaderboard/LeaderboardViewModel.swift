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
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            entries = try await leaderboardService.fetchTopScores(for: selectedDifficulty)
        } catch {
            entries = []
            errorMessage = error.localizedDescription
        }
    }
}
