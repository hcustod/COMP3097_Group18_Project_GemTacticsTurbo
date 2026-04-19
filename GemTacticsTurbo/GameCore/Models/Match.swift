//
//  Match.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

struct Match: Equatable, Sendable {
    let positions: [BoardPosition]
    let gemType: GemType

    var length: Int {
        positions.count
    }
}
