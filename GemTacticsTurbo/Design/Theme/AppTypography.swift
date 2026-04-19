//
//  AppTypography.swift
//  GemTacticsTurbo
//


import SwiftUI

enum AppTypography {
    static let heroTitle = Font.system(size: 36, weight: .bold, design: .rounded)
    static let appTitle = heroTitle
    static let screenTitle = Font.system(.title2, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let bodyStrong = Font.system(.body, design: .rounded).weight(.semibold)
    static let buttonArcade = Font.system(size: 18, weight: .black, design: .rounded)
    static let label = Font.system(.subheadline, design: .rounded).weight(.medium)
    static let caption = Font.system(.callout, design: .rounded)
    static let hudLabel = Font.system(.caption2, design: .rounded).weight(.medium)
    static let hudValue = Font.system(.title3, design: .rounded).weight(.bold)
    static let scoreHero = Font.system(size: 56, weight: .bold, design: .rounded)
    static let scoreLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let statValue = Font.system(size: 28, weight: .bold, design: .rounded)
}
