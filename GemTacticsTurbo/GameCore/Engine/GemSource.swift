//
//  GemSource.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

protocol GemSource {
    mutating func nextGem() -> GemType
}

struct SystemRandomGemSource: GemSource {
    private var generator = SystemRandomNumberGenerator()

    mutating func nextGem() -> GemType {
        GemType.allCases.randomElement(using: &generator) ?? .ruby
    }
}

