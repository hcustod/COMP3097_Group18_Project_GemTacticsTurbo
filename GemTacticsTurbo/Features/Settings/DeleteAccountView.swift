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
        ScreenContainer(title: "Delete Account") {
            SectionHeader(title: router.isGuest ? "Guest Session" : "Type DELETE")

            if router.isGuest {
                StatCard(
                    title: "Guest",
                    value: "No Account"
                )
            } else {
                StatCard(
                    title: "Confirm",
                    value: "DELETE"
                )

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Enter DELETE")
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
