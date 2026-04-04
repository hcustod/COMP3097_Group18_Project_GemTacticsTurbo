import Foundation

struct AuthSessionPresentation {
    let homeSubtitle: String
    let sessionStatusTitle: String
    let homeSessionDetail: String
    let settingsAccountSubtitle: String
    let settingsSessionDetail: String
    let settingsDeletionMessage: String?
    let signOutButtonTitle: String

    static func make(
        isGuest: Bool,
        isRemoteAuthAvailable: Bool,
        isSigningOut: Bool
    ) -> Self {
        let signOutButtonTitle: String
        if isSigningOut {
            signOutButtonTitle = isRemoteAuthAvailable ? "Signing Out..." : "Ending Session..."
        } else {
            signOutButtonTitle = isRemoteAuthAvailable ? "Sign Out" : "End Local Session"
        }

        if isGuest && !isRemoteAuthAvailable {
            return Self(
                homeSubtitle: "Local guest mode is active. You can play rounds, store guest stats, and review an on-device leaderboard from here.",
                sessionStatusTitle: "Local Guest Session",
                homeSessionDetail: "This session was created locally so the app can run without Firebase setup.",
                settingsAccountSubtitle: "Local guest sessions can end the current session, but they do not expose permanent account deletion.",
                settingsSessionDetail: "This on-device guest session keeps local profile stats and leaderboard testing available without Firebase setup.",
                settingsDeletionMessage: "Guest sessions do not offer account deletion. Sign out to end the current session.",
                signOutButtonTitle: signOutButtonTitle
            )
        }

        if isGuest {
            return Self(
                homeSubtitle: "Guest access is active through anonymous authentication. You can play, save scores, and keep local guest stats from here.",
                sessionStatusTitle: "Guest Session",
                homeSessionDetail: "This session was created with Firebase anonymous authentication.",
                settingsAccountSubtitle: "Guest sessions can sign out, but they do not expose permanent account deletion.",
                settingsSessionDetail: "Anonymous authentication keeps leaderboard access simple without a permanent profile.",
                settingsDeletionMessage: "Guest sessions do not offer account deletion. Sign out to end the current session.",
                signOutButtonTitle: signOutButtonTitle
            )
        }

        return Self(
            homeSubtitle: "Authenticated access is active through email sign-in. Use Home as the main hub for gameplay, profile, leaderboard, and settings.",
            sessionStatusTitle: "Registered Session",
            homeSessionDetail: "This session was created through the email authentication flow.",
            settingsAccountSubtitle: "Registered accounts can sign out or permanently delete the current account.",
            settingsSessionDetail: "This account can load profile stats, save scores, and be deleted from Firebase Auth.",
            settingsDeletionMessage: nil,
            signOutButtonTitle: signOutButtonTitle
        )
    }
}
