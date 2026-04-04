//
//  LoginView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ScreenContainer(title: "Gem Tactics Turbo") {
            SectionHeader(title: viewModel.isLocalOnlyMode ? "Tap To Start" : "Login")

            if let errorMessage = viewModel.errorMessage {
                InlineStatusMessage(message: errorMessage)
            }

            VStack(spacing: AppSpacing.large) {
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

                VStack(spacing: AppSpacing.medium) {
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
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
    }
}
