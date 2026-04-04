//
//  ProfileView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = ProfileViewModel()
    private let statColumns = [
        GridItem(.flexible(), spacing: AppSpacing.medium),
        GridItem(.flexible(), spacing: AppSpacing.medium)
    ]

    var body: some View {
        ScreenContainer(title: "Profile") {
            profileContent

            SecondaryButton(title: "Back to Home") {
                router.show(.home)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile()
        }
    }

    @ViewBuilder
    private var profileContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(AppColors.accentPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let errorMessage = viewModel.errorMessage {
            InlineStatusMessage(message: errorMessage)
        } else if let profile = viewModel.profile {
            VStack(spacing: AppSpacing.medium) {
                StatCard(
                    title: "Player",
                    value: profile.displayName,
                    detail: profile.email ?? (profile.isGuest ? "Guest" : nil)
                )

                LazyVGrid(columns: statColumns, spacing: AppSpacing.medium) {
                    StatCard(title: "Games", value: "\(profile.gamesPlayed)")
                    StatCard(title: "Best", value: "\(profile.highestScore)")
                    StatCard(title: "Average", value: profile.averageScore.formatted())
                    StatCard(title: "Total", value: profile.totalScore.formatted())
                    StatCard(title: "Matches", value: "\(profile.totalMatches)")
                    StatCard(title: "Unlocked", value: profile.unlockedDifficulty.capitalized)
                }

                SecondaryButton(title: "Refresh Stats") {
                    Task {
                        await viewModel.loadProfile()
                    }
                }
            }
        } else {
            InlineStatusMessage(message: "No profile data is available for the current user.")
        }
    }
}
