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

    var body: some View {
        ScreenContainer(
            title: "Profile",
            subtitle: router.isGuest
                ? "Guest stats are stored locally for the current anonymous session."
                : "Completed games now update your Firestore-backed profile stats automatically."
        ) {
            SectionHeader(
                title: "Overview",
                subtitle: sectionSubtitle
            )

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
            StatCard(
                title: "Status",
                value: "Loading",
                detail: "Fetching the current profile data."
            )

            ProgressView()
                .tint(AppColors.accentPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let errorMessage = viewModel.errorMessage {
            InlineStatusMessage(message: errorMessage)
        } else if let profile = viewModel.profile {
            VStack(spacing: AppSpacing.medium) {
                StatCard(
                    title: "Display Name",
                    value: profile.displayName,
                    detail: profile.email ?? (profile.isGuest ? "Guest sessions do not store an email address." : "No email address is available.")
                )

                StatCard(
                    title: "Avatar",
                    value: profile.avatarName,
                    detail: profile.isGuest
                        ? "Guest sessions use the local guest avatar style for this MVP build."
                        : "Avatar selection is static in the MVP build."
                )

                StatCard(
                    title: "Games Played",
                    value: "\(profile.gamesPlayed)",
                    detail: "Average score: \(profile.averageScore.formatted())"
                )

                StatCard(
                    title: "Highest Score",
                    value: "\(profile.highestScore)",
                    detail: "Unlocked difficulty: \(profile.unlockedDifficulty.capitalized)"
                )

                StatCard(
                    title: "Total Score",
                    value: profile.totalScore.formatted(),
                    detail: "Cumulative score across all completed rounds."
                )

                StatCard(
                    title: "Match Groups",
                    value: "\(profile.totalMatches)",
                    detail: "MVP total matches count every resolved match group across cascade steps."
                )

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

    private var sectionSubtitle: String {
        if viewModel.isLoading {
            return "Loading the current profile snapshot."
        }

        if viewModel.errorMessage != nil {
            return "A profile error occurred."
        }

        if router.isGuest {
            return "Guest mode uses local stats for the active anonymous session."
        }

        return "Registered accounts show the latest saved stats from Firestore."
    }
}
