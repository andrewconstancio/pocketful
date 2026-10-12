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

## Communication style

- The user is a junior developer — explain what code does in plain terms, not shorthand that assumes senior-level familiarity.
- Keep every answer short: lead with the direct answer, then only the details needed to act on it. Aim for a few sentences or a short list, not a write-up.
- Don't add extra sections, alternatives, tips, or "next steps" unless asked. Offer more detail in one line instead ("Want me to…?").
- For drafts the user asked for (copy, posts, code), give just the draft plus at most a line or two of notes.
