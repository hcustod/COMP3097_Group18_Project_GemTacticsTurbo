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

    static let glassFill = Color(red: 38 / 255, green: 44 / 255, blue: 96 / 255).opacity(0.56)
    static let glassFillElevated = Color(red: 58 / 255, green: 69 / 255, blue: 132 / 255).opacity(0.70)
    static let surface = Color(red: 31 / 255, green: 37 / 255, blue: 82 / 255).opacity(0.84)
    static let surfaceElevated = Color(red: 53 / 255, green: 63 / 255, blue: 120 / 255).opacity(0.94)
    static let glassBorder = Color(red: 80 / 255, green: 186 / 255, blue: 1.0).opacity(0.28)
    static let glassBorderStrong = Color(red: 1.0, green: 192 / 255, blue: 76 / 255).opacity(0.52)
    static let stroke = Color(red: 92 / 255, green: 160 / 255, blue: 1.0).opacity(0.34)

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

    static let arcadeInk = Color(red: 17 / 255, green: 14 / 255, blue: 37 / 255)
    static let arcadePanelTop = Color(red: 66 / 255, green: 79 / 255, blue: 150 / 255)
    static let arcadePanelBottom = Color(red: 28 / 255, green: 29 / 255, blue: 79 / 255)
    static let arcadePanelGlow = Color(red: 77 / 255, green: 203 / 255, blue: 1.0)
    static let arcadeWarmEdge = Color(red: 1.0, green: 188 / 255, blue: 70 / 255)
    static let arcadePrimaryTop = Color(red: 1.0, green: 231 / 255, blue: 100 / 255)
    static let arcadePrimaryMid = Color(red: 1.0, green: 150 / 255, blue: 35 / 255)
    static let arcadePrimaryBottom = Color(red: 199 / 255, green: 40 / 255, blue: 12 / 255)
    static let arcadeSecondaryTop = Color(red: 148 / 255, green: 249 / 255, blue: 1.0)
    static let arcadeSecondaryMid = Color(red: 28 / 255, green: 203 / 255, blue: 211 / 255)
    static let arcadeSecondaryBottom = Color(red: 17 / 255, green: 82 / 255, blue: 178 / 255)
    static let arcadeBevelHighlight = Color.white.opacity(0.46)
    static let arcadeBevelShadow = Color.black.opacity(0.46)

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
