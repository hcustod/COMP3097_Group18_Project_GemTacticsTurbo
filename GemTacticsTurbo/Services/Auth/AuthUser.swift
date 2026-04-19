//
//  AuthUser.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Foundation

struct AuthUser: Codable, Equatable, Sendable {
    let uid: String
    let email: String?
    let displayName: String?
    let isGuest: Bool
}
