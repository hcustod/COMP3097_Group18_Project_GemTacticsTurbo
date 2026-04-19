//
//  AudioManager.swift
//  GemTacticsTurbo
//
//  Created by Fitsum on 10/04/26.
//

import AVFoundation
import Foundation

final class AudioManager {
    static let shared = AudioManager()

    enum SoundEffect: String, CaseIterable {
        case swap
        case match
        case invalid
        case win
        case lose
        case click
    }

    private var effectPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?

    private init() {}

    func playEffect(_ effect: SoundEffect, enabled: Bool) {
        guard enabled else {
            return
        }

        if let player = effectPlayers[effect] {
            player.currentTime = 0
            player.play()
            return
        }

        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") else {
            print("Missing sound file: \(effect.rawValue).mp3")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            effectPlayers[effect] = player
            player.currentTime = 0
            player.play()
        } catch {
            print("Failed to play sound \(effect.rawValue): \(error.localizedDescription)")
        }
    }

    func startBackgroundMusic(enabled: Bool) {
        guard enabled else {
            stopBackgroundMusic()
            return
        }

        guard musicPlayer?.isPlaying != true else {
            return
        }

        guard let url = Bundle.main.url(forResource: "bgm_loop", withExtension: "mp3") else {
            print("Missing sound file: bgm_loop.mp3")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.4
            player.prepareToPlay()
            player.play()
            musicPlayer = player
        } catch {
            print("Failed to play background music: \(error.localizedDescription)")
        }
    }

    func stopBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func refreshBackgroundMusic(enabled: Bool) {
        if enabled {
            startBackgroundMusic(enabled: true)
        } else {
            stopBackgroundMusic()
        }
    }
}
