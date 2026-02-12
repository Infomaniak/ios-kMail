# Infomaniak Mail for iOS

Welcome to the official repository for **Infomaniak Mail**, a modern and secure email client for iOS, iPadOS, and macOS (via Catalyst).

[<img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1662076800" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;">](https://apps.apple.com/ch/app/infomaniak-mail/id1622596573)

## About Infomaniak Mail

Infomaniak Mail is part of the [Infomaniak](https://www.infomaniak.com/) ecosystem, providing a privacy-focused, Swiss-based email solution with a beautiful native iOS experience. Built with Swift and SwiftUI, this app offers a fast, secure, and user-friendly way to manage your emails.

## Architecture

The project follows a modular architecture with clear separation of concerns:

- **Mail**: Main app target containing SwiftUI views, scenes, and app lifecycle
- **MailCore**: Business logic framework with API layer, state managers, and data models
- **MailCoreUI**: Shared UI components and view modifiers
- **MailResources**: Assets, localized strings, and resources
- **Extensions**: Share extension, notification extensions, and App Intents

## Technology Stack

- **Language**: Swift 5.10
- **UI Framework**: SwiftUI (primary) with UIKit integration
- **Database**: [RealmSwift](https://realm.io/) for local data persistence
- **Build System**: [Tuist](https://tuist.io/) for project generation and SPM dependency management
- **Tool Management**: [Mise](https://mise.jdx.dev/) for managing tool versions
- **Networking**: Alamofire
- **Minimum iOS**: 15.0+

## Getting Started

### Prerequisites

1. Install [Mise](https://mise.jdx.dev/) for tool version management:
   ```bash
   curl https://mise.run | sh
   ```

2. Bootstrap the development environment:
   ```bash
   mise install
   eval "$(mise activate bash --shims)"
   ```

3. Install dependencies and generate the Xcode project:
   ```bash
   tuist install
   tuist generate
   ```

### Building and Running

Open the generated `Mail.xcworkspace` in Xcode and build the project, or use:
```bash
xcodebuild -scheme "Infomaniak Mail"
```

## Testing
Before running the Unit and UI tests, you must create an `Env` struct/enum. Duplicate the sample file (`MailTests/Env.sample.swift`), rename it to `Env`, and complete it. You can then run the tests using Xcode or Tuist.
