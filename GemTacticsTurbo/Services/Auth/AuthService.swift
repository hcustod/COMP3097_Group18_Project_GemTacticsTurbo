//
//  AuthService.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import FirebaseAuth
import Foundation

final class AuthService {
    static let shared = AuthService()

    private enum LocalKey {
        static let session = "auth.localGuestSession"
    }

    private let auth: Auth?
    private let defaults: UserDefaults
    private let authStateSubject: CurrentValueSubject<AuthUser?, Never>
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init(
        auth: Auth? = nil,
        defaults: UserDefaults = .standard
    ) {
        let resolvedAuth = auth ?? (FirebaseRuntime.isConfigured ? Auth.auth() : nil)
        self.auth = resolvedAuth
        self.defaults = defaults
        let initialUser: AuthUser?
        if let remoteUser = Self.mapUser(resolvedAuth?.currentUser) {
            initialUser = remoteUser
        } else if resolvedAuth == nil {
            initialUser = Self.loadLocalSession(from: defaults)
        } else {
            initialUser = nil
        }
        self.authStateSubject = CurrentValueSubject(initialUser)
        self.authStateHandle = resolvedAuth?.addStateDidChangeListener { [weak self] _, user in
            self?.authStateSubject.send(Self.mapUser(user))
        }
    }

    deinit {
        if let auth, let authStateHandle {
            auth.removeStateDidChangeListener(authStateHandle)
        }
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        guard let auth else {
            throw AuthServiceError.firebaseUnavailable
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        let result: AuthDataResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            auth.signIn(withEmail: normalizedEmail, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result else {
                    continuation.resume(throwing: AuthServiceError.missingUser)
                    return
                }

                continuation.resume(returning: result)
            }
        }

        guard let user = Self.mapUser(result.user) else {
            throw AuthServiceError.missingUser
        }

        return user
    }

    func register(email: String, password: String, displayName: String) async throws -> AuthUser {
        guard let auth else {
            throw AuthServiceError.firebaseUnavailable
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        let result: AuthDataResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            auth.createUser(withEmail: normalizedEmail, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result else {
                    continuation.resume(throwing: AuthServiceError.missingUser)
                    return
                }

                continuation.resume(returning: result)
            }
        }

        if !normalizedDisplayName.isEmpty {
            try await updateDisplayName(normalizedDisplayName, for: result.user)
        }

        guard let user = Self.mapUser(auth.currentUser) else {
            throw AuthServiceError.missingUser
        }

        return user
    }

    func signInAnonymously() async throws -> AuthUser {
        guard let auth else {
            let localUser = loadOrCreateLocalGuestUser()
            authStateSubject.send(localUser)
            return localUser
        }

        let result: AuthDataResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            auth.signInAnonymously { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result else {
                    continuation.resume(throwing: AuthServiceError.missingUser)
                    return
                }

                continuation.resume(returning: result)
            }
        }

        guard let user = Self.mapUser(result.user) else {
            throw AuthServiceError.missingUser
        }

        return user
    }

    func signOut() throws {
        guard let auth else {
            clearLocalSession()
            authStateSubject.send(nil)
            return
        }

        try auth.signOut()
    }

    func deleteCurrentUser() async throws {
        guard let auth else {
            throw AuthServiceError.firebaseUnavailable
        }

        guard let currentUser = auth.currentUser else {
            throw AuthServiceError.noCurrentUser
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            currentUser.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
    }

    func getCurrentUser() -> AuthUser? {
        authStateSubject.value
    }

    var isRemoteAuthAvailable: Bool {
        FirebaseRuntime.isConfigured && auth != nil
    }

    func observeAuthState() -> AnyPublisher<AuthUser?, Never> {
        authStateSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func errorMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain, let errorCode = AuthErrorCode(rawValue: nsError.code) else {
            return nsError.localizedDescription
        }

        switch errorCode {
        case .invalidEmail:
            return "Enter a valid email address."
        case .wrongPassword, .invalidCredential, .userNotFound:
            return "Invalid email or password."
        case .emailAlreadyInUse:
            return "That email address is already in use."
        case .weakPassword:
            return "Choose a stronger password with at least 6 characters."
        case .networkError:
            return "A network error occurred. Try again."
        case .tooManyRequests:
            return "Too many attempts were made. Wait a moment and try again."
        case .operationNotAllowed:
            return "This sign-in method is not enabled for the project."
        case .userDisabled:
            return "This account has been disabled."
        case .missingEmail:
            return "Enter an email address."
        case .requiresRecentLogin:
            return "For safety, sign in again before deleting this account."
        default:
            return nsError.localizedDescription
        }
    }

    private func loadOrCreateLocalGuestUser() -> AuthUser {
        if let existingUser = Self.loadLocalSession(from: defaults) {
            return existingUser
        }

        let localUser = AuthUser(
            uid: UUID().uuidString,
            email: nil,
            displayName: "Guest Player",
            isGuest: true
        )
        persistLocalSession(localUser)
        return localUser
    }

    private func persistLocalSession(_ user: AuthUser?) {
        guard let user else {
            defaults.removeObject(forKey: LocalKey.session)
            return
        }

        guard let data = try? JSONEncoder().encode(user) else {
            return
        }

        defaults.set(data, forKey: LocalKey.session)
    }

    private func clearLocalSession() {
        persistLocalSession(nil)
    }

    private func updateDisplayName(_ displayName: String, for user: User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.commitChanges { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
    }

    private static func mapUser(_ user: User?) -> AuthUser? {
        guard let user else {
            return nil
        }

        return AuthUser(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            isGuest: user.isAnonymous
        )
    }

    private static func loadLocalSession(from defaults: UserDefaults) -> AuthUser? {
        guard let data = defaults.data(forKey: LocalKey.session) else {
            return nil
        }

        guard let user = try? JSONDecoder().decode(AuthUser.self, from: data), user.isGuest else {
            return nil
        }

        return user
    }
}

private enum AuthServiceError: LocalizedError {
    case missingUser
    case noCurrentUser
    case firebaseUnavailable

    var errorDescription: String? {
        switch self {
        case .missingUser:
            return "Firebase returned no user for the completed authentication request."
        case .noCurrentUser:
            return "There is no currently signed-in user."
        case .firebaseUnavailable:
            return "Firebase is not configured for this build. Use guest mode to keep testing the app locally."
        }
    }
}
