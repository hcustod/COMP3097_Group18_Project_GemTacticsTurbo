//
//  GameModeView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct GameModeView: View {
    @ObservedObject var router: AppRouter

    @State private var maximumUnlockedDifficulty: Difficulty = .easy
    @State private var winsOnEasy = 0
    @State private var winsOnMedium = 0

    private let authService = AuthService.shared
    private let profileService = ProfileService()

    var body: some View {
        ScreenContainer(title: "Play") {
            VStack(spacing: AppSpacing.medium) {
                Text(
                    "Unlock Medium with \(UserProfile.winsRequiredToUnlockMedium) wins on Easy, and Hard with \(UserProfile.winsRequiredToUnlockHard) wins on Medium."
                )
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    let isUnlocked = difficulty.rank <= maximumUnlockedDifficulty.rank
                    DifficultyCard(
                        difficulty: difficulty,
                        isUnlocked: isUnlocked,
                        lockHint: lockHint(for: difficulty, isUnlocked: isUnlocked)
                    ) {
                        guard isUnlocked else {
                            return
                        }
                        router.show(.game(difficulty))
                    }
                }

                SecondaryButton(title: "Home") {
                    router.show(.home)
                }
            }
        }
        .navigationTitle("Game Mode")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshMaximumUnlockedDifficulty()
        }
        .onReceive(NotificationCenter.default.publisher(for: ProfileService.didUpdateProfileNotification)) { notification in
            guard
                let updatedUID = notification.object as? String,
                let currentUser = authService.getCurrentUser(),
                updatedUID == currentUser.uid
            else {
                return
            }

            Task {
                await refreshMaximumUnlockedDifficulty()
            }
        }
    }

    private func refreshMaximumUnlockedDifficulty() async {
        guard let currentUser = authService.getCurrentUser() else {
            maximumUnlockedDifficulty = .easy
            winsOnEasy = 0
            winsOnMedium = 0
            return
        }

        do {
            if let profile = try await profileService.fetchProfile(for: currentUser) {
                maximumUnlockedDifficulty = Difficulty(rawValue: profile.unlockedDifficulty) ?? .easy
                winsOnEasy = profile.winsOnEasy
                winsOnMedium = profile.winsOnMedium
            } else {
                maximumUnlockedDifficulty = .easy
                winsOnEasy = 0
                winsOnMedium = 0
            }
        } catch {
            maximumUnlockedDifficulty = .easy
            winsOnEasy = 0
            winsOnMedium = 0
        }
    }

    private func lockHint(for difficulty: Difficulty, isUnlocked: Bool) -> String? {
        guard !isUnlocked else {
            return nil
        }

        switch difficulty {
        case .easy:
            return nil
        case .medium:
            let required = UserProfile.winsRequiredToUnlockMedium
            return "Easy wins: \(winsOnEasy)/\(required)"
        case .hard:
            let required = UserProfile.winsRequiredToUnlockHard
            return "Medium wins: \(winsOnMedium)/\(required)"
        }
    }
}

private struct DifficultyCard: View {
    let difficulty: Difficulty
    let isUnlocked: Bool
    let lockHint: String?
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ArcadePanelSurface(elevated: true, cornerRadius: AppSpacing.cornerRadius)

            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text(difficulty.displayName)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: AppSpacing.medium) {
                    difficultyDetail(title: "Moves", value: "\(difficulty.moveLimit)")
                    difficultyDetail(title: "Time", value: "\(difficulty.timeLimit)s")
                    difficultyDetail(title: "Target", value: "\(difficulty.targetScore)")
                }

                if let lockHint {
                    Text(lockHint)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                PrimaryButton(title: isUnlocked ? "Play" : "Locked") {
                    action()
                }
                .disabled(!isUnlocked)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.cardPadding)
            .opacity(isUnlocked ? 1.0 : 0.55)

            if !isUnlocked {
                Text("Locked")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, AppSpacing.xSmall)
                    .padding(.vertical, 4)
                    .background(AppColors.glassBorder.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(AppSpacing.cardPadding)
            }
        }
        .allowsHitTesting(isUnlocked)
    }

    private func difficultyDetail(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(title.uppercased())
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)

            Text(value)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
