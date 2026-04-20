# Gem Tactics Turbo

Gem Tactics Turbo is an iOS match-3 puzzle game built with SwiftUI and SpriteKit.

Swap adjacent gems to make matches, score points, and reach the target before you run out of moves or time.

## Features

- Match-3 gameplay with swaps, clears, gravity, refills, pause, and game over screens
- Easy, Medium, and Hard difficulty modes
- Profile and leaderboard screens
- Guest play
- Optional Firebase sign-in and cloud data
- Sound, music, and haptics settings

## Tech Stack

- SwiftUI
- SpriteKit
- Firebase Auth
- Firestore
- XCTest

## Run

1. Open `GemTacticsTurbo.xcodeproj` in Xcode.
2. Let Swift Package Manager resolve dependencies.
3. Select the `GemTacticsTurbo` scheme.
4. Run on an iPhone simulator.

If `GoogleService-Info.plist` is not included, the app still runs in local mode.

## Test

```sh
xcodebuild \
  -project GemTacticsTurbo.xcodeproj \
  -scheme GemTacticsTurbo \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test
```

## Project Structure

```text
GemTacticsTurbo/
├── GemTacticsTurbo/App/
├── GemTacticsTurbo/Features/
├── GemTacticsTurbo/GameCore/
├── GemTacticsTurbo/GameScene/
├── GemTacticsTurbo/Services/
├── GemTacticsTurbo/Design/
├── GemTacticsTurbo/Resources/
└── GemTacticsTurboTests/
```
