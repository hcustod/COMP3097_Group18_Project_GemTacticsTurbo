import Foundation

struct AuthSessionPresentation {
    let homeSubtitle: String
    let sessionStatusTitle: String
    let sessionDetail: String
    let settingsAccountSubtitle: String
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
                sessionDetail: "This session was created locally so the app can run without Firebase setup.",
                settingsAccountSubtitle: "Guest sessions can sign out, but they do not expose permanent account deletion.",
                settingsDeletionMessage: "Guest sessions do not offer account deletion. Sign out to end the current session.",
                signOutButtonTitle: signOutButtonTitle
            )
        }

        if isGuest {
            return Self(
                homeSubtitle: "Guest access is active through anonymous authentication. You can play, save scores, and keep local guest stats from here.",
                sessionStatusTitle: "Guest Session",
                sessionDetail: "This session was created with Firebase anonymous authentication.",
                settingsAccountSubtitle: "Guest sessions can sign out, but they do not expose permanent account deletion.",
                settingsDeletionMessage: "Guest sessions do not offer account deletion. Sign out to end the current session.",
                signOutButtonTitle: signOutButtonTitle
            )
        }

        return Self(
            homeSubtitle: "Authenticated access is active through email sign-in. Use Home as the main hub for gameplay, profile, leaderboard, and settings.",
            sessionStatusTitle: "Registered Session",
            sessionDetail: "This session was created through the email authentication flow.",
            settingsAccountSubtitle: "Registered accounts can sign out or permanently delete the current account.",
            settingsDeletionMessage: nil,
            signOutButtonTitle: signOutButtonTitle
        )
    }
}
