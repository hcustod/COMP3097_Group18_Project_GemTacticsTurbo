//
//  RegisterView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = RegisterViewModel()

    var body: some View {
        ScreenContainer(
            title: "Create Account",
            subtitle: "Create an email-based account for the MVP and start with a ready-to-use profile record."
        ) {
            SectionHeader(
                title: "Register",
                subtitle: "The account flow is now live with basic client-side validation and Firebase registration."
            )

            StatCard(
                title: "Account Setup",
                value: "Email Only",
                detail: "Display name, email, password, and confirmation are required for MVP registration."
            )

            if let errorMessage = viewModel.errorMessage {
                InlineStatusMessage(message: errorMessage)
            }

            VStack(spacing: AppSpacing.large) {
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

                VStack(spacing: AppSpacing.medium) {
                    PrimaryButton(title: viewModel.isSubmitting ? "Creating Account..." : "Create Account") {
                        Task {
                            _ = await viewModel.register()
                        }
                    }
                    .disabled(viewModel.canSubmit == false)

                    SecondaryButton(title: "Back to Login") {
                        router.showLogin()
                    }
                    .disabled(viewModel.isSubmitting)
                }
            }
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
}
