// Author: Tyson Ward-Dicks - 101501186
// Changes: Adjusted local sign-in flow and auth validation behavior.

import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = "" {
        didSet { clearError() }
    }

    @Published var password = "" {
        didSet { clearError() }
    }

    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    convenience init() {
        self.init(authService: .shared)
    }

    var canSubmitLogin: Bool {
        !isSubmitting
    }

    var canSubmitGuest: Bool {
        !isSubmitting
    }

    func signIn() async -> Bool {
        guard !isSubmitting else {
            return false
        }

        guard let validationError = validateLogin() else {
            isSubmitting = true
            defer { isSubmitting = false }

            do {
                _ = try await authService.signIn(email: email, password: password)
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

    private func validateLogin() -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty || password.isEmpty {
            return "Enter both your email and password."
        }

        if !Self.isValidEmail(trimmedEmail) {
            return "Enter a valid email address."
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
