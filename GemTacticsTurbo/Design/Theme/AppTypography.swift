//
//  AppTypography.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

enum AppTypography {
    static let appTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let screenTitle = Font.system(.title2, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let bodyStrong = Font.system(.body, design: .rounded).weight(.semibold)
    static let caption = Font.system(.callout, design: .rounded)
    static let statValue = Font.system(size: 28, weight: .bold, design: .rounded)
}
