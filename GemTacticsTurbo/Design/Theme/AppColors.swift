//
//  AppColors.swift
//  GemTacticsTurbo
//
//  Semantic colors aligned with Puzzle Gem Swap / Figma audit (Tailwind literals → tokens).
//

import SwiftUI

enum AppColors {
    static let backgroundTop = Color(red: 10 / 255, green: 10 / 255, blue: 15 / 255)
    static let backgroundMid = Color(red: 26 / 255, green: 15 / 255, blue: 46 / 255)
    static let backgroundBottom = Color(red: 10 / 255, green: 10 / 255, blue: 15 / 255)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundTop, backgroundMid, backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static let glassFill = Color.white.opacity(0.05)
    static let glassFillElevated = Color.white.opacity(0.10)
    static let surface = Color.white.opacity(0.08)
    static let surfaceElevated = Color.white.opacity(0.14)
    static let glassBorder = Color.white.opacity(0.10)
    static let glassBorderStrong = Color.white.opacity(0.20)
    static let stroke = glassBorder

    static let overlayScrim = Color.black.opacity(0.60)
    static let modalPanel = backgroundMid

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.70)
    static let textMuted = Color.white.opacity(0.40)
    static let textTertiary = Color.white.opacity(0.60)
    static let textLink = Color(red: 192 / 255, green: 132 / 255, blue: 252 / 255)
    static let textLinkPressed = Color(red: 216 / 255, green: 180 / 255, blue: 254 / 255)

    static let accentPrimary = Color(red: 219 / 255, green: 39 / 255, blue: 119 / 255)
    static let accentSecondary = Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255)

    private static let accentPurple = Color(red: 147 / 255, green: 51 / 255, blue: 234 / 255)
    private static let accentPink = Color(red: 219 / 255, green: 39 / 255, blue: 119 / 255)

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentPurple, accentPink],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private static let brandPurple = Color(red: 192 / 255, green: 132 / 255, blue: 252 / 255)
    private static let brandPink = Color(red: 244 / 255, green: 114 / 255, blue: 182 / 255)
    private static let brandBlue = Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255)

    static var brandGradientText: LinearGradient {
        LinearGradient(
            colors: [brandPurple, brandPink, brandBlue],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static let success = Color(red: 74 / 255, green: 222 / 255, blue: 128 / 255)
    static let error = Color(red: 248 / 255, green: 113 / 255, blue: 113 / 255)
    static let errorSurface = Color(red: 248 / 255, green: 113 / 255, blue: 113 / 255).opacity(0.18)

    static let destructiveBackground = Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255).opacity(0.10)
    static let destructiveBorder = Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255).opacity(0.30)
    static let destructiveText = Color(red: 248 / 255, green: 113 / 255, blue: 113 / 255)
    static let destructiveFill = Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255)

    static var rankGoldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 250 / 255, green: 204 / 255, blue: 21 / 255),
                Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var rankSilverGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 209 / 255, green: 213 / 255, blue: 219 / 255),
                Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let rankSilverForeground = Color(red: 31 / 255, green: 41 / 255, blue: 55 / 255)

    static var rankBronzeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 251 / 255, green: 146 / 255, blue: 60 / 255),
                Color(red: 234 / 255, green: 88 / 255, blue: 12 / 255),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var rankDefaultFill: Color {
        Color.white.opacity(0.10)
    }

    static var rankDefaultForeground: Color {
        Color.white.opacity(0.60)
    }

    static var difficultyEasyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255),
                Color(red: 5 / 255, green: 150 / 255, blue: 105 / 255),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var difficultyMediumGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255),
                Color(red: 8 / 255, green: 145 / 255, blue: 178 / 255),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var difficultyHardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255),
                Color(red: 234 / 255, green: 88 / 255, blue: 12 / 255),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let orbPurple = Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255).opacity(0.10)
    static let orbBlue = Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255).opacity(0.10)
    static let orbPink = Color(red: 236 / 255, green: 72 / 255, blue: 153 / 255).opacity(0.05)
    static let toggleTrackOff = Color.white.opacity(0.10)
}
