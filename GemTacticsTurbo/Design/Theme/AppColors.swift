//
//  AppColors.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

enum AppColors {
    static let backgroundTop = Color(red: 0.10, green: 0.06, blue: 0.18)
    static let backgroundBottom = Color(red: 0.03, green: 0.02, blue: 0.08)
    static let surface = Color.white.opacity(0.08)
    static let surfaceElevated = Color.white.opacity(0.14)
    static let stroke = Color.white.opacity(0.12)
    static let accentPrimary = Color(red: 1.00, green: 0.35, blue: 0.66)
    static let accentSecondary = Color(red: 0.32, green: 0.88, blue: 0.96)
    static let error = Color(red: 1.00, green: 0.46, blue: 0.54)
    static let errorSurface = Color(red: 1.00, green: 0.20, blue: 0.28).opacity(0.18)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.76)
    static let textMuted = Color.white.opacity(0.56)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
