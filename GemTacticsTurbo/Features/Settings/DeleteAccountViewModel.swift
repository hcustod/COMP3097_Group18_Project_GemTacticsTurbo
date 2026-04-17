//
//  DeleteAccountViewModel.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//  Author: Tyson Ward-Dicks - 101501186
//  Changes: Updated delete-account flow for local accounts and local profile cleanup.
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
    private let profileService: ProfileService

    init(authService: AuthService, profileService: ProfileService) {
        self.authService = authService
        self.profileService = profileService
        refreshUserState()
    }

    convenience init() {
        self.init(authService: .shared, profileService: ProfileService())
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
            let deletedUID = authService.getCurrentUser()?.uid
            try await authService.deleteCurrentUser()
            if let deletedUID {
                profileService.deleteProfile(uid: deletedUID)
            }
            errorMessage = nil
            return true
        } catch {
            errorMessage = authService.errorMessage(for: error)
            return false
        }
    }
}
