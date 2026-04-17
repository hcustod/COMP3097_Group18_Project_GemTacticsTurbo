import SwiftUI

struct RegisterView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = RegisterViewModel()

    var body: some View {
        ScreenContainer(
            title: "Create Account",
            subtitle: "Create your account first, or keep going as a guest."
        ) {
            VStack(spacing: AppSpacing.sectionSpacing) {
                GlassPanel(elevated: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                        AuthScreenHeader(
                            eyebrow: "New Player",
                            title: "Create Account",
                            detail: "Pick a display name, set your login, and we’ll send you to the sign-in screen once your account is ready."
                        )

                        if let errorMessage = viewModel.errorMessage {
                            InlineStatusMessage(message: errorMessage)
                        }

                        VStack(spacing: AppSpacing.stackStandard) {
                            InputFieldContainer(title: "Display Name") {
                                TextField("Enter a display name", text: $viewModel.displayName)
                                    .textInputAutocapitalization(.words)
                                    .textContentType(.nickname)
                            }

                            InputFieldContainer(title: "Email") {
                                TextField("name@example.com", text: $viewModel.email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocorrectionDisabled(true)
                            }

                            InputFieldContainer(title: "Password", detail: "Minimum 6 characters") {
                                SecureField("Create a password", text: $viewModel.password)
                                    .textContentType(.newPassword)
                            }

                            InputFieldContainer(title: "Confirm Password") {
                                SecureField("Re-enter your password", text: $viewModel.confirmPassword)
                                    .textContentType(.newPassword)
                            }
                        }

                        VStack(spacing: AppSpacing.stackTight) {
                            PrimaryButton(title: viewModel.isSubmitting ? "Creating Account..." : "Create Account") {
                                Task {
                                    let wasRegistered = await viewModel.register()
                                    if wasRegistered {
                                        router.showLogin()
                                    }
                                }
                            }
                            .disabled(viewModel.canSubmit == false)

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
                                leadingText: "Already have an account? ",
                                actionText: "Sign In Here"
                            ) {
                                router.showLogin()
                            }
                            .disabled(viewModel.isSubmitting)
                        }
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: AppSpacing.stackTight) {
                        Text("Account Benefits")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.brandGradientText)

                        AuthBulletRow(text: "Return with the same account and sign back in later.")
                        AuthBulletRow(text: "Keep your player identity tied to your profile.")
                        AuthBulletRow(text: "Still use guest mode any time you want a quick session.")
                    }
                }
            }
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}
