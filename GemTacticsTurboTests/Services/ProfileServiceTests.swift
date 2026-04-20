import XCTest
@testable import GemTacticsTurbo

final class ProfileServiceTests: XCTestCase {
    func testDeleteProfileRemovesStoredLocalProfile() async throws {
        let defaults = makeDefaults(testName: #function)
        let service = ProfileService(database: nil, defaults: defaults)
        let user = AuthUser(
            uid: "profile-user",
            email: "profile@example.com",
            displayName: "Profile User",
            isGuest: false
        )
        let profile = UserProfile.initial(for: user)

        try await service.updateProfile(profile)
        XCTAssertNotNil(defaults.data(forKey: "profile.local.\(user.uid)"))

        await service.deleteProfile(uid: user.uid)

        XCTAssertNil(defaults.data(forKey: "profile.local.\(user.uid)"))
    }

    private func makeDefaults(testName: String) -> UserDefaults {
        let suiteName = "ProfileServiceTests.\(testName)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
