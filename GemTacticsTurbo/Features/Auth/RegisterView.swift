import SwiftUI

struct RegisterView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = RegisterViewModel()

    var body: some View {
        ScreenContainer(title: "Create Account") {
            GlassPanel {
                VStack(alignment: .leading, spacing: AppSpacing.stackStandard) {
                    Text("Create Account")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColors.brandGradientText)

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

                        VStack(spacing: AppSpacing.stackTight) {
                            PrimaryButton(title: viewModel.isSubmitting ? "Creating Account..." : "Create Account") {
                                Task {
                                    _ = await viewModel.register()
                                }
                            }
                            .disabled(viewModel.canSubmit == false)

                            SecondaryButton(title: "Sign In") {
                                router.showLogin()
                            }
                            .disabled(viewModel.isSubmitting)
                        }
                    }
                }
            }
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}
