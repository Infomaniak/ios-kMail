# Copilot Coding Agent Onboarding Guide for Infomaniak/ios-kMail

Before reading this file, please read AGENTS.md to learn more about the project context, structure, and conventions.

## Pull Request Review Instructions

- Pay attention for consistency with existing code style and architecture.
- Ensure new UI uses Design System components where applicable. Notably IKPaddings, IKRadius, IKIconSize.
- Ensure strings are localized with MailResourcesStrings.Localizable.<some key>
- When reviewing Realm model changes, check whether the persisted schema changed: added, removed, renamed, or type-changed persisted properties, changed optionality, lists, embedded objects, or object types.
- If the persisted Realm schema changed, ensure the matching schema version was incremented in `MailCore/Cache/MailboxManager/MailboxManager.swift`, `MailCore/Cache/MailboxInfosManager/MailboxInfosManager.swift`, or `MailCore/Cache/ContactManager/ContactManager.swift`, and that the relevant migration logic was updated when existing data needs migration.

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
