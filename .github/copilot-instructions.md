# Copilot Coding Agent Onboarding Guide for Infomaniak/ios-kMail

## High-Level Overview

**Repository Purpose**:  
This repository contains the source code for the Infomaniak Mail iOS application. It is a full-featured, production iOS mail app, developed in Swift, targeting iOS 15.0+ (with some components requiring iOS 16.4+), and is structured as a multi-target Tuist-managed Xcode project. The codebase is substantial, modular, and built for high reliability and maintainability.

**Languages, Frameworks, and Tooling**:  
- **Main language**: Swift (with some supporting Bash, Python, JavaScript for scripting and resources)
- **Build System**: [Tuist](https://tuist.io/) for project generation, dependency management, and Xcode integration
- **Linting**: SwiftLint with configuration in `.swiftlint.yml`
- **CI/CD**: Uses custom shell scripts in `ci_scripts/`, and validation checks via GitHub Actions and/or external CI systems (e.g., Xcode Cloud).
- **Dependency Management**: Swift Package Manager via Tuist/Package.swift
- **Testing**: Extensive Unit and UI tests under `MailTests/` and `MailUITests/`
- **Conventional Commits**: Follow the Conventional Commits specification for commit messages.

---

## Build, Bootstrap, and Validation Instructions

**Environment Setup**  
1. **Install [mise](https://mise.jdx.dev/)** (required for managing tool versions):
   - Run: `curl https://mise.run | sh`
   - Add `$HOME/.local/bin` to your `PATH`
2. **Bootstrap all tool versions**:
   - `mise install`
   - `eval "$(mise activate bash --shims)"`
3. **Install dependencies using Tuist**:
   - `tuist install`
4. **Project Generation**:
   - `tuist generate --no-open` (must always be run after bootstrapping and when project structure changes)

**Build**  
- Open the generated `.xcodeproj` in Xcode (minimum version matching deployment target).
- Alternatively, build via Xcode CLI: `xcodebuild -scheme "Infomaniak Mail"`

**Lint**  
- Always run `scripts/lint.sh` before pushing or creating a PR:
  - This invokes SwiftLint using the repo’s `.swiftlint.yml` config.
  - If SwiftLint is missing, follow the install prompt in the script output.

**Test**  
- Before running tests, **copy and edit the environment config**:
  - Duplicate `MailTests/Env.sample.swift` as `MailTests/Env.swift` and fill in required values.
- Run all tests from Xcode or with Tuist:
  - `tuist test`
  - Or via Xcode test navigator.

**Common Errors and Workarounds**  
- Always run `mise install` and `eval "$(mise activate bash --shims)"` before any build, lint, or test step.
- If you see "missing Env.swift" errors, create `MailTests/Env.swift` as described above.
- If SwiftLint or Tuist are missing, follow the install instructions from their respective websites.
- If environment variables required by CI scripts are missing, export them or set up your environment accordingly.

---

## Project Layout & Architectural Notes

**Main project directories:**
- `Mail/` — Main application code (SwiftUI, UIKit, app logic)
- `MailCore/` — Core mail logic, protocols, data handling
- `MailCoreUI/` — Shared UI components
- `MailResources/` — Localizable strings, assets, entitlements, HTML/CSS/JS used in the app
- `MailTests/` — Unit tests (requires `Env.swift`)
- `MailUITests/` — UI tests
- `Tuist/` — Project description and dependency configuration (`Project.swift`, `Package.swift`, helpers)
- `scripts/` — Utility scripts (lint, symbol stripping, localization sync, pre-commit formatting)
- `ci_scripts/` — CI/CD and environment setup scripts for Xcode Cloud, do not use locally

**Key config files:**
- `.swiftlint.yml` — SwiftLint configuration
- `Project.swift`, `Tuist/ProjectDescriptionHelpers/Constants.swift` — Project targets, dependencies, build scripts
- `scripts/lint.sh` — Linting
- `README.md` — Testing instructions and project overview

**Validation steps before check-in:**
- Run `scripts/lint.sh` and ensure no lint errors.

**Dependencies and Extensions:**
- Many external Swift packages (see `Tuist/Package.swift`).
- App uses RealmSwift for data, Alamofire for networking, and several Infomaniak internal libraries.
- App targets iPhone, iPad, and Mac Catalyst.

---

## File/Directory Listing (Root + First Level)

- README.md
- LICENSE
- Project.swift
- Tuist/
- Mail/
- MailCore/
- MailCoreUI/
- MailResources/
- MailTests/
- MailUITests/
- scripts/
- ci_scripts/
- TestFlight/

---

## Agent Instructions

- **Trust these instructions for common build, lint, and test steps; only search if these prove incomplete or fail.**
- Always bootstrap the environment (`mise install` + `eval "$(mise activate bash --shims)"`) before other steps.
- Always create `MailTests/Env.swift` for test runs.
- Use provided scripts for linting and formatting.
- Never use ci_scripts/ locally; it's for CI/CD only.
- For any environment or build error, first ensure all setup steps above are completed in order.

---

## Pull Request Review Instructions

- Pay attention for consistency with existing code style and architecture.
- Ensure new UI uses Design System components where applicable. Notably IKPaddings, IKRadius, IKIconSize.
- Ensure strings are localized with MailResourcesStrings.Localizable.<some key>

Some common UI errors with correction:

Do: `VStack(alignment: .leading, spacing: IKPadding.micro)`
Don't do: `VStack(alignment: .leading)`
Comment: Multiple IKPadding exist, the dev has to choose the closest one to the design spec (micro, ..., giant - refer to IKPadding for full list).

Do: `.padding(value: .medium)`
Don't do: `.padding(16)`
Comment: Multiple IKPadding exist, the dev has to choose the closest one to the design spec (micro, ..., giant - refer to IKPadding for full list).

Do: `RoundedRectangle(cornerRadius: IKRadius.large)`
Don't do: `RoundedRectangle(cornerRadius: 12)`
Comment: Multiple IKRadius exist, the dev has to choose the closest one to the design spec (small, medium, large).

---

*If the above instructions are incomplete or produce errors, perform a targeted search for updated scripts/configs or missing dependencies. Otherwise, rely on this onboarding for all standard build, test, and validation tasks.*
