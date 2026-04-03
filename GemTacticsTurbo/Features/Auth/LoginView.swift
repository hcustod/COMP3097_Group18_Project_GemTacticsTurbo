import SwiftUI

struct LoginView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ScreenContainer(
            title: "Gem Tactics Turbo",
            subtitle: viewModel.isLocalOnlyMode
                ? "This local build is ready to play without backend setup. Continue as guest to use the full MVP flow."
                : "Sign in with email for a full account, or start an anonymous guest session for MVP play."
        ) {
            GlassPanel {
                VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                    Text(viewModel.isLocalOnlyMode ? "Local Play" : "Sign in")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColors.brandGradientText)

                    Text(viewModel.isLocalOnlyMode
                        ? "Firebase is not configured in this build, so the app uses a local guest path for gameplay, stats, and leaderboard testing."
                        : "Email sign-in and anonymous guest access both route through the live authentication service.")
                        .font(AppTypography.label)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text("MVP ACCESS")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textMuted)
                        Text(viewModel.isLocalOnlyMode ? "Local Guest Mode" : "Email + Guest")
                            .font(AppTypography.bodyStrong)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(viewModel.isLocalOnlyMode
                            ? "Gameplay, profile stats, and leaderboard testing can all run locally through the guest session."
                            : "Registered users sign in with email, and guests use anonymous authentication.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, AppSpacing.xSmall)

                    if let errorMessage = viewModel.errorMessage {
                        InlineStatusMessage(message: errorMessage)
                    }

                    VStack(spacing: AppSpacing.stackStandard) {
                        if !viewModel.isLocalOnlyMode {
                            InputFieldContainer(title: "Email") {
                                TextField("name@example.com", text: $viewModel.email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocorrectionDisabled(true)
                            }

                            InputFieldContainer(title: "Password") {
                                SecureField("Enter your password", text: $viewModel.password)
                                    .textContentType(.password)
                            }
                        }

                        VStack(spacing: AppSpacing.stackTight) {
                            if !viewModel.isLocalOnlyMode {
                                PrimaryButton(title: viewModel.isSubmitting ? "Signing In..." : "Sign In") {
                                    Task {
                                        _ = await viewModel.signIn()
                                    }
                                }
                                .disabled(viewModel.canSubmitLogin == false)
                            }

                            SecondaryButton(title: viewModel.isSubmitting ? "Starting Guest Session..." : (viewModel.isLocalOnlyMode ? "Enter App" : "Continue as Guest")) {
                                Task {
                                    _ = await viewModel.signInAsGuest()
                                }
                            }
                            .disabled(viewModel.canSubmitGuest == false)

                            if !viewModel.isLocalOnlyMode {
                                SecondaryButton(title: "Create Account") {
                                    router.showRegister()
                                }
                                .disabled(viewModel.isSubmitting)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
    }
}
