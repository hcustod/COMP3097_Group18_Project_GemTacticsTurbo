import SwiftUI

struct DeleteAccountView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = DeleteAccountViewModel()

    var body: some View {
        ScreenContainer(title: "Delete Account") {
            VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        Text(router.isGuest ? "Unavailable" : "Type DELETE")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.destructiveText)

                        Text(
                            router.isGuest
                                ? guestWarningText
                                : "This can't be undone."
                        )
                        .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if router.isGuest {
                            EmptyView()
                        } else {
                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text("DELETE")
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
                        .disabled(viewModel.isDeleting)
                    }

                    SecondaryButton(title: "Settings") {
                        router.show(.settings)
                    }

                    SecondaryButton(title: "Home") {
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

    private var guestWarningText: String {
        "Not available for guests."
    }
}
