//
//  ProfileViewModel.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let authService: AuthService
    private let profileService: ProfileService
    private var cancellables: Set<AnyCancellable> = []

    init(
        authService: AuthService,
        profileService: ProfileService
    ) {
        self.authService = authService
        self.profileService = profileService
        observeProfileUpdates()
    }

    convenience init() {
        self.init(
            authService: .shared,
            profileService: ProfileService()
        )
    }

    func loadProfile() async {
        guard let currentUser = authService.getCurrentUser() else {
            profile = nil
            errorMessage = "No signed-in user is available."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let fetchedProfile = try await profileService.fetchProfile(for: currentUser) {
                profile = fetchedProfile
                return
            }

            let fallbackProfile = UserProfile.initial(for: currentUser)
            try await profileService.updateProfile(fallbackProfile)
            profile = fallbackProfile
        } catch {
            profile = nil
            errorMessage = "Unable to load your profile right now. Try again."
        }
    }

    private func observeProfileUpdates() {
        NotificationCenter.default.publisher(for: ProfileService.didUpdateProfileNotification)
            .sink { [weak self] notification in
                guard
                    let self,
                    let currentUser = self.authService.getCurrentUser(),
                    let updatedUID = notification.object as? String,
                    updatedUID == currentUser.uid
                else {
                    return
                }

                Task { @MainActor [weak self] in
                    await self?.loadProfile()
                }
            }
            .store(in: &cancellables)
    }
}
