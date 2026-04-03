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
            VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text("Warning")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.destructiveText)

                        Text(
                            router.isGuest
                                ? "You can leave guest mode by signing out."
                                : "For safety, type DELETE before continuing. Firebase may require you to sign in again if the session is too old."
                        )
                        .font(AppTypography.label)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if router.isGuest {
                            VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                                Text("GUEST SESSION")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textMuted)
                                Text("No Deletion Needed")
                                    .font(AppTypography.bodyStrong)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("Anonymous sessions can simply sign out from Settings.")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textTertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, AppSpacing.xSmall)
                        } else {
                            VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                                Text("CONFIRMATION")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.destructiveText.opacity(0.9))
                                Text("Type DELETE")
                                    .font(AppTypography.bodyStrong)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("Account deletion removes the authentication account and returns you to the login flow.")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textTertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, AppSpacing.xSmall)

                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text("Confirmation Text")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textMuted)

                                TextField("DELETE", text: $viewModel.confirmationText)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .font(AppTypography.bodyStrong)
                                    .foregroundStyle(AppColors.textPrimary)
                                    .padding(AppSpacing.medium)
                                    .background {
                                        RoundedRectangle(cornerRadius: AppSpacing.radiusInput, style: .continuous)
                                            .fill(AppColors.destructiveBackground)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppSpacing.radiusInput, style: .continuous)
                                            .stroke(AppColors.destructiveBorder, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusInput, style: .continuous))
                            }

                            if let errorMessage = viewModel.errorMessage {
                                InlineStatusMessage(message: errorMessage)
                            }
                        }
                    }
                }

                VStack(spacing: AppSpacing.stackTight) {
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
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refreshUserState()
        }
    }
}
