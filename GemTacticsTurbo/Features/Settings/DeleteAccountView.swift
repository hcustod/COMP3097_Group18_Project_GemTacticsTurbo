//
//  DeleteAccountView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct DeleteAccountView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = DeleteAccountViewModel()

    var body: some View {
        ScreenContainer(
            title: "Delete Account",
            subtitle: router.isGuest
                ? "Guest sessions do not have a permanent account to delete."
                : "This action permanently removes the current Firebase-authenticated account."
        ) {
            SectionHeader(
                title: "Warning",
                subtitle: router.isGuest
                    ? "You can leave guest mode by signing out."
                    : "For safety, type DELETE before continuing. Firebase may require you to sign in again if the session is too old."
            )

            if router.isGuest {
                StatCard(
                    title: "Guest Session",
                    value: "No Deletion Needed",
                    detail: "Anonymous sessions can simply sign out from Settings."
                )
            } else {
                StatCard(
                    title: "Confirmation",
                    value: "Type DELETE",
                    detail: "Account deletion removes the authentication account and returns you to the login flow."
                )

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Confirmation Text")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)

                    TextField("DELETE", text: $viewModel.confirmationText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(AppSpacing.medium)
                        .background(AppColors.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.cornerRadius, style: .continuous)
                                .stroke(AppColors.stroke, lineWidth: 1)
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppSpacing.cornerRadius,
                                style: .continuous
                            )
                        )
                }

                if let errorMessage = viewModel.errorMessage {
                    InlineStatusMessage(message: errorMessage)
                }
            }

            VStack(spacing: AppSpacing.medium) {
                if !router.isGuest {
                    PrimaryButton(title: viewModel.isDeleting ? "Deleting..." : "Delete My Account") {
                        Task {
                            let wasDeleted = await viewModel.deleteAccount()
                            if wasDeleted {
                                router.showLogin()
                            }
                        }
                    }
                    .disabled(!viewModel.canDelete)
                }

                SecondaryButton(title: "Back to Settings") {
                    router.show(.settings)
                }

                SecondaryButton(title: "Return Home") {
                    router.show(.home)
                }
            }
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refreshUserState()
        }
    }
}
