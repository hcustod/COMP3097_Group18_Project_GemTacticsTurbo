//
//  RegisterViewModel.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import Foundation

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var displayName = "" {
        didSet { clearError() }
    }

    @Published var email = "" {
        didSet { clearError() }
    }

    @Published var password = "" {
        didSet { clearError() }
    }

    @Published var confirmPassword = "" {
        didSet { clearError() }
    }

    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?

    private let authService: AuthService
    private let profileService: ProfileService
    private let minimumPasswordLength = 6

    init(
        authService: AuthService,
        profileService: ProfileService
    ) {
        self.authService = authService
        self.profileService = profileService
    }

    convenience init() {
        self.init(
            authService: .shared,
            profileService: ProfileService()
        )
    }

    var canSubmit: Bool {
        !isSubmitting
    }

    var canSubmitGuest: Bool {
        !isSubmitting
    }

    func register() async -> Bool {
        guard !isSubmitting else {
            return false
        }

        guard let validationError = validateRegistration() else {
            isSubmitting = true
            defer { isSubmitting = false }

            do {
                let user = try await authService.register(
                    email: email,
                    password: password,
                    displayName: displayName
                )
                do {
                    try await profileService.createInitialProfile(for: user)
                } catch {
                    try? authService.signOut()
                    errorMessage = "Your account was created, but the initial profile setup failed. Please try again."
                    return false
                }

                try? authService.signOut()
                errorMessage = nil
                return true
            } catch {
                errorMessage = authService.errorMessage(for: error)
                return false
            }
        }

        errorMessage = validationError
        return false
    }

    func signInAsGuest() async -> Bool {
        guard !isSubmitting else {
            return false
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await authService.signInAnonymously()
            errorMessage = nil
            return true
        } catch {
            errorMessage = authService.errorMessage(for: error)
            return false
        }
    }

    private func validateRegistration() -> String? {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedDisplayName.isEmpty || trimmedEmail.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            return "Fill in every field before creating an account."
        }

        if !Self.isValidEmail(trimmedEmail) {
            return "Enter a valid email address."
        }

        if password.count < minimumPasswordLength {
            return "Password must be at least \(minimumPasswordLength) characters."
        }

        if password != confirmPassword {
            return "Passwords do not match."
        }

        return nil
    }

    private func clearError() {
        errorMessage = nil
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else {
            return false
        }

        let domain = parts[1]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }
}
