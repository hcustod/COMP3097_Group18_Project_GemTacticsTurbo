//
//  GemType.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

enum GemType: String, CaseIterable, Hashable, Sendable {
    case ruby
    case sapphire
    case emerald
    case topaz
    case amethyst

    var assetName: String {
        "gem-\(rawValue)"
    }

    var displayName: String {
        switch self {
        case .ruby:
            return "Ruby"
        case .sapphire:
            return "Sapphire"
        case .emerald:
            return "Emerald"
        case .topaz:
            return "Topaz"
        case .amethyst:
            return "Amethyst"
        }
    }
}
