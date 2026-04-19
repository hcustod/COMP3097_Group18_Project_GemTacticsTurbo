import Foundation

struct AuthSessionPresentation {
    let sessionStatusTitle: String
    let settingsDeletionMessage: String?
    let signOutButtonTitle: String

    static func make(
        isGuest: Bool,
        isSigningOut: Bool
    ) -> Self {
        let signOutButtonTitle: String
        if isSigningOut {
            signOutButtonTitle = isGuest ? "Ending Session..." : "Signing Out..."
        } else {
            signOutButtonTitle = isGuest ? "End Session" : "Sign Out"
        }

        if isGuest {
            return Self(
                sessionStatusTitle: "Guest",
                settingsDeletionMessage: "Not available for guests.",
                signOutButtonTitle: signOutButtonTitle
            )
        }

        return Self(
            sessionStatusTitle: "Signed In",
            settingsDeletionMessage: nil,
            signOutButtonTitle: signOutButtonTitle
        )
    }
}
