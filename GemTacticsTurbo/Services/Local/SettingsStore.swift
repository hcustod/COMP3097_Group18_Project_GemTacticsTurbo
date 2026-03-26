//
//  SettingsStore.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Key.soundEnabled) }
    }

    @Published var musicEnabled: Bool {
        didSet { defaults.set(musicEnabled, forKey: Key.musicEnabled) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Key.hapticsEnabled) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.soundEnabled = defaults.object(forKey: Key.soundEnabled) as? Bool ?? true
        self.musicEnabled = defaults.object(forKey: Key.musicEnabled) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: Key.hapticsEnabled) as? Bool ?? true
    }
}

private enum Key {
    static let soundEnabled = "settings.soundEnabled"
    static let musicEnabled = "settings.musicEnabled"
    static let hapticsEnabled = "settings.hapticsEnabled"
}
