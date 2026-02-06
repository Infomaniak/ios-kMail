# AGENTS.md

## Project Summary

Infomaniak Mail — a production iOS mail client supporting iPhone, iPad, and Mac Catalyst (iOS 15.0+).

- **Language:** Swift 5.10
- **UI:** SwiftUI (primary) with UIKit integration
- **Build system:** Tuist 4.x (project generation + SPM dependency management)
- **Architecture:** MVVM + Coordinator, DI via `InfomaniakDI` (`@LazyInjectService`)
- **Database:** RealmSwift
- **Networking:** Alamofire
- **Linting:** SwiftLint 0.63, SwiftFormat 0.58
- **CI/CD:** GitHub Actions + Xcode Cloud
- **Commit style:** Conventional Commits

## Context Map

```
ios-kMail/
├── Mail/                        # Main app target — SwiftUI views, scenes, app lifecycle
│   ├── MailApp.swift            #   @main entry point
│   ├── AppDelegate.swift        #   UIApplicationDelegate
│   ├── SceneDelegate.swift      #   UISceneDelegate (shortcuts)
│   ├── RootView.swift           #   Root state machine (lock, onboarding, auth, main)
│   ├── Views/                   #   Feature screens (AI Writer, Attachment, New Message, Search, Settings, Thread, Thread List, etc.)
│   ├── Components/              #   Reusable view components (ThreadCell, Custom Buttons)
│   ├── Helpers/                 #   View helpers & notification handlers
│   ├── Utils/                   #   Constants, formatters
│   └── Proxy/                   #   Protocol abstraction layer
├── MailCore/                    # Business logic framework
│   ├── API/                     #   REST API layer (MailApiFetcher + endpoint definitions)
│   ├── Cache/                   #   State managers (AccountManager, MailboxManager, DraftManager, ContactManager)
│   ├── Models/                  #   Data models (Draft, Contact, Settings enums, AI, Calendar)
│   ├── Utils/                   #   Realm helpers, notifications, SnackBar
│   └── ViewModel/               #   Shared view models
├── MailCoreUI/                  # Shared UI components framework (Reactions, RecipientChip, ViewModifiers)
├── MailResources/               # Assets, localized strings, entitlements, HTML/CSS/JS templates, Lottie animations
├── MailTests/                   # Unit & integration tests (XCTest)
├── MailUITests/                 # UI automation tests
├── MailShareExtension/          # Share extension target
├── MailNotificationServiceExtension/   # Silent push processing
├── MailNotificationContentExtension/   # Rich notification UI
├── MailAppIntentsExtension/     # Siri Shortcuts / App Intents (iOS 16.4+)
├── Tuist/                       # Tuist config
│   ├── Package.swift            #   SPM dependency declarations
│   └── ProjectDescriptionHelpers/  #   Build constants & helpers
├── Project.swift                # Tuist project definition (all targets, deps, build scripts)
├── scripts/                     # Dev scripts (lint.sh, git-format-staged, strip_symbols.sh, update_loco.sh)
├── ci_scripts/                  # Xcode Cloud CI scripts — DO NOT run locally
├── .github/workflows/           # 10 GitHub Actions (CI, lint, format, periphery, semantic-commit, UI tests, etc.)
├── .swiftlint.yml               # SwiftLint rules
├── .swiftformat                 # SwiftFormat config
├── .mise.toml                   # Tool versions (Tuist, SwiftLint, SwiftFormat, Periphery, sentry-cli, import-loco)
├── .periphery.yml               # Dead code detection config
├── .import_loco.yml             # Localization sync config
└── .sonarcloud.properties       # SonarCloud config
```

## Local Norms

### Command Patterns

```bash
# Bootstrap environment (required before build/lint/test)
mise install
eval "$(mise activate bash --shims)"

# Install SPM dependencies
tuist install

# Generate Xcode project
tuist generate --no-open

# Build
xcodebuild -scheme "Infomaniak Mail"

# Lint (run before every PR)
scripts/lint.sh

# Run tests
tuist test
# Or via Xcode Test Navigator

# Localization sync
scripts/update_loco.sh
```

### Code Style

- **Naming:** Swift standard — `camelCase` for variables/functions, `PascalCase` for types.
- **Max line width:** 130 characters.
- **Indentation:** 4 spaces, LF line endings.
- **Imports:** Alphabetical grouping, blank line after imports.
- **Type organization:** Organize by `actor`, `class`, `enum`, `struct` (SwiftFormat `--organizetypes`).
- **SwiftUI property wrappers must be private:** `@State`, `@StateObject`, `@ModalState`, `@Environment`, `@EnvironmentObject` — enforced by custom SwiftLint rules.
- **Design System tokens — never use raw values:**
  - Spacing: `IKPadding.micro`, `.small`, `.medium`, etc. — not literal numbers.
  - Radii: `IKRadius.small`, `.medium`, `.large` — not literal numbers.
  - Icon sizes: `IKIconSize` constants.
  - Example: `.padding(value: .medium)` not `.padding(16)`.
- **Localized strings:** Always use `MailResourcesStrings.Localizable.<key>`, never raw string literals.
- **DI:** Use `@LazyInjectService` for dependency injection; register via target assembly classes.
- **API layer:** Extend `MailApiFetcher` with focused extensions (e.g., `+Calendar`, `+AI`, `+Attachment`).
- **Concurrency:** Use `async/await` and structured concurrency. `RefreshActor` for background sync.
- **Formatting:** Pre-commit hook runs `scripts/git-format-staged`. SwiftFormat excludes `DerivedData`, `Derived`, `Tuist`, `Project.swift`.

### Testing

- **Unit tests:** `MailTests/` — XCTest-based.
- **UI tests:** `MailUITests/` — XCTest UI automation.
- **Setup:** Duplicate `MailTests/Env.sample.swift` → `MailTests/Env.swift` and fill in `token`, `userId`, `mailboxId`, `mailboxUuid`. For UI tests, also set `testAccountEmail` and `testAccountPassword`.
- **Run:** `tuist test` or Xcode Test Navigator.
- **CI:** GitHub Actions run `MailTests` on PRs (skips `MailUITests` in standard CI).

### PR Checklist

- Run `scripts/lint.sh` — no lint errors.
- Use Conventional Commits for commit messages.
- Use Design System tokens (IKPadding, IKRadius, IKIconSize) — no raw numeric values.
- Localize all user-facing strings.
- Never use `ci_scripts/` locally.

### Learned Preferences

_None yet. Add user-corrected preferences here as they arise._

## Self-correction

> This section is for you, the future agent.
>
> 1. **Stale Map:** If you encounter a file or folder not listed in the "Context Map", update the map in this file.
> 2. **New Norms:** If the user corrects you (e.g., "Don't use X, use Y"), add that rule to the "Local norms" section immediately so you don't make the mistake again.
> 3. **Refinement:** If you find this file is too verbose, prune it. Keep it high-signal.
