//
//  FirestoreServiceError.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Foundation

enum FirestoreServiceError: LocalizedError {
    case firebaseUnavailable

    var errorDescription: String? {
        switch self {
        case .firebaseUnavailable:
            return "Firebase is not configured for this build."
        }
    }
}
