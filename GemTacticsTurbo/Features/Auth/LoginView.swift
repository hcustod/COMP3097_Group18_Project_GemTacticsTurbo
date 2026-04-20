// Author: Tyson Ward-Dicks - 101501186
// Changes: Updated sign-in screen flow, wording, and inline auth action styling.

import SwiftUI

struct LoginView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ScreenContainer(
            title: router.isGuest ? "Account Access" : "Gem Tactics Turbo",
            subtitle: "Sign in to continue, or keep playing as a guest."
        ) {
            VStack(spacing: AppSpacing.sectionSpacing) {
                GlassPanel(elevated: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        AuthScreenHeader(
                            eyebrow: "Player",
                            title: "Sign In",
                            detail: "Use your account to load your player identity and jump back into the cabinet."
                        )

                        if let errorMessage = viewModel.errorMessage {
                            InlineStatusMessage(message: errorMessage)
                        }

                        VStack(spacing: AppSpacing.stackStandard) {
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
                            PrimaryButton(title: viewModel.isSubmitting ? "Signing In..." : "Sign In") {
                                Task {
                                    _ = await viewModel.signIn()
                                }
                            }
                            .disabled(viewModel.canSubmitLogin == false)

                            SecondaryButton(
                                title: viewModel.isSubmitting
                                    ? "Starting..."
                                    : "Continue as Guest"
                            ) {
                                Task {
                                    _ = await viewModel.signInAsGuest()
                                }
                            }
                            .disabled(viewModel.canSubmitGuest == false)

                            AuthInlineActionButton(
                                leadingText: "Don't have an account? ",
                                actionText: "Create One Here"
                            ) {
                                router.showRegister()
                            }
                            .disabled(viewModel.isSubmitting)
                        }
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                        Text("What Guest Mode Keeps")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        AuthBulletRow(text: "Quick local play without account setup.")
                        AuthBulletRow(text: "On-device progress for guest sessions in this build.")
                        AuthBulletRow(text: "A clean path to create an account later from Settings or Profile.")
                    }
                }
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AuthScreenHeader: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(eyebrow.uppercased())
                .font(AppTypography.hudLabel)
                .foregroundStyle(AppColors.arcadeWarmEdge)
                .kerning(0.8)

            Text(title)
                .font(AppTypography.heroTitle)
                .foregroundStyle(AppColors.brandGradientText)

            Text(detail)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AuthBulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Circle()
                .fill(AppColors.arcadePanelGlow)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AuthInlineActionButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let leadingText: String
    let actionText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(leadingText)
                    .foregroundStyle(isEnabled ? AppColors.textSecondary : AppColors.textMuted)

                Text(actionText)
                    .foregroundStyle(isEnabled ? AppColors.arcadePanelGlow : AppColors.textMuted)
                    .underline(true, color: isEnabled ? AppColors.arcadePanelGlow : AppColors.textMuted)
            }
                .font(AppTypography.label)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppSpacing.xSmall)
        }
        .buttonStyle(.plain)
    }
}
