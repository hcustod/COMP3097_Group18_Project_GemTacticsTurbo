//
//  DeleteAccountViewModel.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import Foundation

@MainActor
final class DeleteAccountViewModel: ObservableObject {
    @Published var confirmationText = "" {
        didSet {
            if confirmationText != oldValue {
                errorMessage = nil
            }
        }
    }

    @Published private(set) var isDeleting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isGuest = false

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
        refreshUserState()
    }

    convenience init() {
        self.init(authService: .shared)
    }

    var canDelete: Bool {
        !isDeleting && confirmationText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "DELETE"
    }

    func refreshUserState() {
        isGuest = authService.getCurrentUser()?.isGuest ?? false
    }

    func deleteAccount() async -> Bool {
        guard !isDeleting else {
            return false
        }

        refreshUserState()

        guard !isGuest else {
            errorMessage = "Guest sessions do not have a permanent account to delete."
            return false
        }

        guard canDelete else {
            errorMessage = "Type DELETE to confirm the account removal."
            return false
        }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await authService.deleteCurrentUser()
            errorMessage = nil
            return true
        } catch {
            errorMessage = authService.errorMessage(for: error)
            return false
        }
    }
}
