# Gem Tactics Turbo

Gem Tactics Turbo is an iOS match-3 puzzle game built with SwiftUI and SpriteKit. The project combines an arcade-style presentation with a pure Swift game engine, multiple difficulty levels, Firebase-backed authentication and persistence, and a local guest fallback so the app can still run when Firebase is not configured.

## Overview

Players swap adjacent gems on a portrait-friendly board to create matches of 3 or more. Each round has both a move limit and a time limit, and the goal is to reach the target score before either one runs out. Completed rounds can update a player profile and submit scores to a difficulty-based leaderboard.

The app is structured so the gameplay rules live in testable Swift models and engine types, while SpriteKit handles board rendering and animation and SwiftUI drives the surrounding application flow.

## Features

- Arcade-styled match-3 gameplay with animated swaps, clears, gravity, refills, pause, and game-over overlays
- Three difficulty modes with distinct score targets, move limits, time limits, and score multipliers
- Email/password sign-in and account creation through Firebase Authentication when Firebase is configured
- Guest play support
- Automatic local fallback mode when `GoogleService-Info.plist` is not present
- Player profile screen with games played, average score, best score, total score, and total match groups resolved
- Difficulty-filtered leaderboard backed by Firestore when available
- Local persistence for guest sessions, settings, and offline leaderboard/profile data
- Settings screen with persisted sound, music, and haptics toggles
- Account deletion flow for authenticated non-guest users
- Unit tests for the game engine and main gameplay view model

## Gameplay

### Board and Rules

- Default board size: `9 x 5`
- Valid moves: orthogonally adjacent swaps only
- A move must create at least one match to be accepted
- Matches: horizontal or vertical runs of 3 or more identical gems
- Gem types: Ruby, Sapphire, Emerald, Topaz, and Amethyst
- Boards are generated without starting matches and are repaired if they become effectively dead boards with too few valid swaps

### Difficulty Modes

| Difficulty | Moves | Time | Target Score | Score Multiplier |
| --- | ---: | ---: | ---: | ---: |
| Easy | 30 | 120s | 1,000 | 1.0x |
| Medium | 25 | 90s | 2,000 | 1.5x |
| Hard | 20 | 60s | 3,500 | 2.0x |

### Scoring

- Base score: `100` points per gem in a match
- Extra length bonus: `50` additional points for each gem beyond the first 3
- Combo bonus: each cascade step adds a `25%` multiplier
- Difficulty multiplier is applied on top of the match and combo score

## Tech Stack

- `SwiftUI` for the app shell, navigation flow, menus, forms, overlays, and profile/leaderboard/settings screens
- `SpriteKit` for the interactive gem board, touch input, and swap/cascade animation
- `Combine` for observable state and auth/profile update propagation
- `FirebaseCore`, `FirebaseAuth`, and `FirebaseFirestore` through Swift Package Manager
- `UserDefaults` for local settings, guest sessions, and fallback persistence
- `XCTest` for unit testing

## Firebase Behavior

Firebase support is optional at runtime.

If `GoogleService-Info.plist` is available in the app bundle, the app configures Firebase on launch and enables:

- Email/password registration and sign-in
- Anonymous Firebase guest sessions
- Firestore-backed profile storage
- Firestore-backed leaderboard storage

If `GoogleService-Info.plist` is missing, the app intentionally skips Firebase configuration and falls back to local-only behavior:

- The app can still be used in guest mode
- Guest session state is stored locally
- Leaderboard entries are stored locally
- Guest profile data is stored locally

To use the full backend flow, make sure your Firebase project has these enabled:

- Email/Password authentication
- Anonymous authentication
- Cloud Firestore

## Project Structure

```text
GemTacticsTurbo/
├── GemTacticsTurbo/App/                # App entry point, bootstrapping, routing
├── GemTacticsTurbo/Features/           # SwiftUI feature screens and view models
├── GemTacticsTurbo/GameCore/           # Pure game rules, board generation, scoring
├── GemTacticsTurbo/GameScene/          # SpriteKit scene and animation coordination
├── GemTacticsTurbo/Services/           # Auth, Firestore, and local persistence services
├── GemTacticsTurbo/Design/             # Shared styling, components, spacing, colors
├── GemTacticsTurbo/Resources/          # Assets, logos, launch visuals
└── GemTacticsTurboTests/               # Unit tests
```

## Build and Run

### Requirements

- Xcode with the iOS `26.2` SDK installed
- Swift Package Manager dependency resolution enabled in Xcode
- Optional: a Firebase project and local `GoogleService-Info.plist` file for backend features

### Running in Xcode

1. Open `GemTacticsTurbo.xcodeproj` in Xcode.
2. Let Xcode resolve the Swift Package Manager dependencies.
3. If you want Firebase-backed auth and Firestore features, add `GoogleService-Info.plist` to the app target.
4. Select the shared `GemTacticsTurbo` scheme.
5. Choose an iPhone or iPad simulator that supports iOS `26.2`.
6. Build and run.

If you do not add `GoogleService-Info.plist`, the app should still launch and operate in its local guest-mode fallback path.

### Command-Line Test Example

```sh
xcodebuild \
  -project GemTacticsTurbo.xcodeproj \
  -scheme GemTacticsTurbo \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test
```

## Testing

The test target currently focuses on the gameplay and state-management layers.

Covered areas include:

- Board generation without starting matches
- Swap adjacency and move validation
- Horizontal and vertical match detection
- Gravity and refill behavior
- Cascade resolution
- Score calculation
- Dead-board detection and playability repair
- GameViewModel round reset, timer handling, win/loss conditions, and router behavior

## Notable Implementation Details

- `GameCore` is intentionally separated from UI concerns so the matching logic can be tested independently.
- `GameSceneCoordinator` bridges SpriteKit input/animation with the SwiftUI-driven `GameViewModel`.
- Profiles and leaderboard entries are updated when a round ends, but those persistence failures are intentionally non-blocking so the game flow stays responsive.
- The app supports both portrait and landscape layouts, with the board and HUD adapting to available space.

## Current Dependencies

Directly used Firebase products in the project:

- `FirebaseCore`
- `FirebaseAuth`
- `FirebaseFirestore`

These are resolved through Swift Package Manager, with transitive Google/Firebase packages recorded in `Package.resolved`.

## License

No license file is included in this repository.
