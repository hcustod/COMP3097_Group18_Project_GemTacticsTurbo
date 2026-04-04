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
    private var activeLoadRequestID = 0

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
        activeLoadRequestID += 1
        let requestID = activeLoadRequestID
        isLoading = true
        errorMessage = nil
        defer {
            if requestID == activeLoadRequestID {
                isLoading = false
            }
        }

        guard let currentUser = authService.getCurrentUser() else {
            profile = nil
            errorMessage = "No signed-in user is available."
            return
        }

        do {
            if let fetchedProfile = try await profileService.fetchProfile(for: currentUser) {
                guard requestID == activeLoadRequestID else {
                    return
                }

                profile = fetchedProfile
                return
            }

            let fallbackProfile = UserProfile.initial(for: currentUser)
            try await profileService.updateProfile(fallbackProfile)
            guard requestID == activeLoadRequestID else {
                return
            }

            profile = fallbackProfile
        } catch {
            guard requestID == activeLoadRequestID else {
                return
            }

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
