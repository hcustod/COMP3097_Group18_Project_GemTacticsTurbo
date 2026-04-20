import XCTest
@testable import GemTacticsTurbo

final class AuthServiceTests: XCTestCase {
    func testGuestSessionPersistsAcrossLocalServiceInstances() async throws {
        let defaults = makeDefaults(testName: #function)
        let service = AuthService(auth: nil, defaults: defaults)

        let user = try await service.signInAnonymously()
        let reloadedService = AuthService(auth: nil, defaults: defaults)

        XCTAssertTrue(user.isGuest)
        XCTAssertEqual(reloadedService.getCurrentUser(), user)
    }

    func testLocalAccountCanSignOutAndSignBackIn() async throws {
        let defaults = makeDefaults(testName: #function)
        let service = AuthService(auth: nil, defaults: defaults)

        let createdUser = try await service.register(
            email: "player@example.com",
            password: "secret123",
            displayName: "Player One"
        )

        try service.signOut()
        XCTAssertNil(service.getCurrentUser())

        let reloadedService = AuthService(auth: nil, defaults: defaults)
        let signedInUser = try await reloadedService.signIn(
            email: "player@example.com",
            password: "secret123"
        )

        XCTAssertEqual(signedInUser.uid, createdUser.uid)
        XCTAssertEqual(signedInUser.email, createdUser.email)
        XCTAssertFalse(signedInUser.isGuest)
    }

    private func makeDefaults(testName: String) -> UserDefaults {
        let suiteName = "AuthServiceTests.\(testName)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
