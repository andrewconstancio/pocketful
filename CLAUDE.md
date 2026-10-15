# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Pocketful — a SwiftUI iOS app (no UIKit). Single Xcode project (`pocketful-ios.xcodeproj`), no third-party dependencies (no SPM/CocoaPods packages), no test target, no CI. Bundle identifier is `com.kuma.pocketful-ios` (org prefix is "kuma", not "pocketful" — don't assume they match when searching signing/config). `landing/` is a standalone static marketing page (`index.html`), unrelated to the app build.

## Conventions

- Views live under `<Feature>/Views/<Name>View.swift` (e.g. `Auth/Views/LoginView.swift`). Helper/manager types live under `Utilites/<Category>/` (e.g. `Utilites/Fonts/FontManager.swift`) — note the directory is spelled `Utilites` (missing an "l"). This is the existing committed convention; match it for new utility code rather than "fixing" the spelling.
- Custom fonts are centralized in `FontManager` as nested enums per font family (raw value = PostScript name) exposing a `.font(size:)` helper. Register new font files in `Info.plist` under `UIAppFonts`.
- Colors are defined as named assets in `Assets.xcassets/Colors/` (e.g. `appBackground`, `textPrimary`) and referenced via dot-syntax (`.foregroundStyle(.textPrimary)`), not hardcoded hex/Color literals.
- Uses the modern `#Preview` macro for SwiftUI previews.

## Working in this repo

- There is no test target, linter, or CI configured — don't assume `xcodebuild test`, SwiftLint, or SwiftFormat exist. No build verification step is required before considering a change done.
- No strong git branch/commit conventions yet (single `main` branch, early-stage repo).

## Code review

- **Correctness first**: Does it do what it claims? Check edge cases (empty states, nil/optional unwraps, async timing).
- **Consistency with conventions**: Follows the patterns above — view file locations, `FontManager` usage, named color assets instead of hex, `#Preview` macro present.
- **State management**: `@State`/`@Binding`/`@ObservedObject` used correctly — no unnecessary re-renders, no state that should be hoisted or lowered.
- **No dead code**: Remove unused variables, commented-out blocks, leftover print statements.
- **Naming**: Clear, descriptive names for views, functions, variables — no abbreviations that only make sense today.
- **Small, single-purpose views**: If a view file is getting long or doing too much, flag it for splitting.
- **Force unwraps (`!`) and force-try**: Justify every one — prefer `if let`/`guard let` unless truly guaranteed safe.
- **Security basics**: No hardcoded secrets/API keys, no sensitive data logged.
- **Comments**: Only where the code isn't self-explanatory. Keep them short and to the point — one sentence, straight to what's happening or why, no multi-line explanations.
- **Manual test pass**: Since there's no test target, actually run the feature in the simulator before calling it done — note what you tested.
- **Self-review before asking for a second opinion**: Read your own diff top-to-bottom once, as if someone else wrote it.

## Communication style

- The user is a junior developer — explain what code does in plain terms, not shorthand that assumes senior-level familiarity.
- Keep every answer short: lead with the direct answer, then only the details needed to act on it. Aim for a few sentences or a short list, not a write-up.
- Don't add extra sections, alternatives, tips, or "next steps" unless asked. Offer more detail in one line instead ("Want me to…?").
- For drafts the user asked for (copy, posts, code), give just the draft plus at most a line or two of notes.
