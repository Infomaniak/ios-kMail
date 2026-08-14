---
applyTo: "**"
---

# Infomaniak Mail Security Review Instructions

Act as a security-aware engineer when reviewing or modifying Infomaniak Mail. Pay particular attention to seams where messages, HTML, files, URLs, identifiers, or state cross the application sandbox or change trust level.

Report only concrete, reachable security issues. Trace attacker-controlled data from its entry point to a consequential operation, explain the impact, and recommend the smallest fix that closes the boundary. Do not request a generalized security framework when a narrow validation rule is sufficient.

## Trust Model

- The application's private sandbox is trusted.
- Infomaniak APIs and authenticated transport are trusted infrastructure.
- Content keeps the trust level of its original author or source even when an Infomaniak API delivers or restores it.
- Content authored directly by the currently authenticated user may be considered trusted for malicious-intent analysis at its original input boundary.
- Messages and content received from another sender are untrusted.
- Forwarded and quoted external content remains untrusted when included in a user-authored draft or sent message.
- Shared or imported text, HTML, URLs, files, signatures, AI-generated content, and server-restored drafts require validation appropriate to their original source.
- Subjects, sender identities, headers, message bodies, links, remote resources, attachments, MIME metadata, BIMI data, and calendar invitations from incoming mail are untrusted.
- Trusted user content must still be handled safely when malformed or unexpectedly large, to prevent crashes, hangs, excessive resource use, or unsafe parser behavior.
- Sender display names, visible email addresses, contact matches, avatars, BIMI artwork, and message text do not authenticate a sender.
- Authentication does not imply authorization. Bind every mailbox, message, draft, attachment, and action to the expected account and mailbox.
- Data supplied by another application, extension, browser, custom URL scheme, pasteboard, notification payload, shared container, or other process is untrusted until validated.
- App Groups provide access control but do not make every value or file in shared storage trustworthy.
- When authorship or provenance cannot be established, state the assumption instead of silently treating the content as trusted.

## Boundaries To Review

Review code that handles, but is not limited to:

- Incoming and server-restored message bodies, subjects, headers, sender data, quotes, and previews
- HTML sanitization, SwiftSoup processing, WebViews, injected scripts, and script-message handlers
- External or remote content, images, CSS resources, tracking pixels, and content-blocking rules
- Links, redirects, `mailto:` URLs, custom URL schemes, profile callbacks, and URLs opened outside the application
- Attachments, inline content, filenames, MIME types, content IDs, attachment resources, previews, and archives
- Calendar invitations, organizers, attendees, locations, recurrence, replies, and imports
- Push notifications, notification actions, notification service/content extensions, and payload identifiers
- Share-extension item providers, Safari preprocessing results, `.webloc`, text, HTML, directories, and files
- App Groups and state shared between the app, notification extensions, share extension, and App Intents extension
- Document pickers, photo pickers, drag and drop, security-scoped URLs, pasteboards, exports, and printing
- API fields containing URLs, resource paths, cursors, identifiers, permissions, or mail-derived content
- Realm or cache writes derived from incoming messages or external processes
- Logs, analytics, crash reports, notification content, widgets, and background snapshots

## Boundary Questions

For each relevant boundary, determine:

1. Who can invoke or influence it?
2. Is the origin authenticated, and is that authentication actually required for the action?
3. Is the current user authorized for the exact account, mailbox, message, draft, attachment, and operation?
4. Which values can be controlled by another sender, application, process, or website?
5. Is input decoded and parsed exactly once?
6. Is validation completed before rendering, navigation, storage, network requests, account changes, or other side effects?
7. Is validation applied to the canonical value that is ultimately used?
8. Can encoding, normalization, redirects, aliases, symlinks, MIME ambiguity, or concurrent replacement bypass validation?
9. Are count, size, expanded size, DOM depth, recursion, memory, storage, CPU, and execution time bounded while content is consumed?
10. Can sensitive mail data leave the sandbox through logs, URLs, exports, notifications, previews, pasteboards, or shared storage?
11. Does failure leave partial files, persisted state, registered handlers, leaked access, or inconsistent authorization state?

## Message Content And HTML

- Treat incoming HTML and plain text as parser input, not passive display data.
- Preserve sanitization before loading message content into a WebView. Review changes to `SwiftSoupUtils`, its whitelist, body transformations, and `loadHTMLString` as one security boundary.
- Keep message-provided JavaScript disabled. App-injected scripts do not make script-message payloads trusted.
- Validate the type, size, format, coordinates, identifiers, and resulting native action of every `WKScriptMessage`.
- Do not widen allowed HTML elements, attributes, CSS, URL schemes, or WebView capabilities without analyzing the resulting native and network behavior.
- Escape or sanitize quoted messages, signatures, shared text, imported HTML, `mailto:` bodies, and AI output before inserting them into composed HTML.
- Do not interpolate incoming content into HTML, JavaScript, predicates, commands, or format strings without context-appropriate handling.
- Bound HTML size, DOM traversal, recursion, CSS scanning, quote extraction, and transformations. Avoid expensive parsing on the main thread.
- Preserve WebKit process-termination handling and fail closed when sanitization or parsing fails.

## Remote Content And Tracking

- Treat external images, SVG resources, CSS URLs, imports, fonts, media, and tracking pixels as privacy-sensitive network requests.
- Preserve remote-content blocking before loading the document.
- Keep the existing explicit display-external-content behavior and spam-folder restrictions unless a product requirement deliberately changes them.
- Validate allowed hosts using exact host boundaries. A suffix string match must not allow deceptive sibling domains.
- Review URL encodings, ports, schemes, redirects, CSS syntax, and alternate resource attributes when changing remote-content detection or `ContentBlocker` rules.
- Do not attach authentication headers, cookies, mailbox identifiers, or private referrer data to arbitrary remote-content requests.
- Do not assume an Infomaniak-looking hostname is safe without canonical host validation.

## Links, Deeplinks, And External Navigation

- Treat every link in incoming mail as attacker-controlled.
- Require the exact expected scheme, host, path, and parameter set for custom URL schemes and callbacks.
- Do not treat possession of a custom-scheme URL as proof of sender identity.
- Allow only explicitly supported schemes before opening a URL internally or externally. Reject `javascript:`, `data:`, local-file, and unexpected custom schemes unless safely required.
- Validate every redirect when the application follows or handles redirects itself.
- Detect deceptive URLs containing user information, encoded hosts, Unicode ambiguity, unexpected ports, or credentials before presenting or acting on them.
- Treat `mailto:` recipients, subject, body, and headers as untrusted input. Bound their size and sanitize content before composing HTML.
- Bind profile callbacks and other stateful callbacks to the flow that initiated them and prevent replay or cross-account confusion.
- Never authorize mailbox or message operations solely from externally supplied identifiers.

## Attachments And Files

- Treat attachment names, part IDs, MIME types, sizes, resources, content IDs, dispositions, Drive URLs, and bytes as untrusted.
- Sanitize every attacker-controlled path component. Filename sanitization is not a substitute for validating full path containment.
- Compare standardized path components, not string prefixes, when checking containment.
- Resolve or reject symlinks before trusting imported paths. Consider symlinks in parent directories as well as at the file itself.
- Reject traversal through `..`, encoded separators, repeated encoding, aliases, item-provider indirection, or archive entries.
- Accept only expected filesystem object types. Do not accidentally import directories, sockets, devices, or other special files as attachments.
- Do not rely only on extensions, advertised MIME types, UTTypes, or server metadata to select a security-sensitive parser or behavior.
- Treat Quick Look, image, SVG, PDF, office, calendar, media, and archive previews as parser boundaries.
- Bound attachment count, individual and aggregate size, decompressed size, nesting depth, image dimensions, and concurrent downloads.
- Enforce limits while downloading, reading, decompressing, and decoding. Do not rely only on declared attachment size or `Content-Length`.
- Use unique local destinations, avoid attacker-controlled overwrites, and clean up partial files after failure or cancellation.
- Keep `startAccessingSecurityScopedResource()` balanced with `stopAccessingSecurityScopedResource()` and limit access duration.

## Sender Identity And Phishing

- Do not infer sender authenticity from display name, visible address, contact presence, avatar, BIMI artwork, or message content.
- Preserve the distinction between informational indicators and cryptographic or server-validated identity signals such as DKIM-related status.
- Avoid UI changes that make an unverified sender appear certified, internal, or trusted.
- Keep phishing reporting and sender restrictions bound to the exact mailbox, message, and sender identity selected by the user.
- Treat punycode, Unicode-confusable domains, reply-to differences, and mismatches between visible text and link destination as phishing-sensitive display cases.

## Calendar Invitations

- Treat ICS attachments and event fields, including title, location, organizer, attendees, recurrence, dates, method, and event ID, as untrusted.
- Do not render event content as trusted HTML or execute embedded URLs automatically.
- Importing an event or replying to an invitation is a state-changing action and should require explicit user intent.
- Bind calendar replies and imports to the expected account, mailbox, message, and attachment.
- Do not allow invitation data to select arbitrary API resources or recipients outside the validated event context.

## Share Extension And App Groups

- Treat every `NSExtensionItem`, `NSItemProvider`, Safari preprocessing result, `.webloc`, text value, directory, and file as untrusted.
- Validate declared types against the representation actually loaded.
- Escape or sanitize shared text and HTML before inserting it into a draft.
- Bound item counts and sizes, and avoid loading large provider content entirely into memory when streaming is practical.
- Use safe temporary locations and unique names. Clean up partial files and do not trust provider-supplied paths after validation if they can be replaced.
- Treat shared Realm data, preferences, files, and identifiers as crossing a target boundary even when stored in an App Group.
- Do not expose tokens or broader account state to an extension that does not require them.
- Preserve the content's trust classification when copied into the main application's private sandbox or persisted in Realm.

## Notifications And Extensions

- Treat notification payload values as untrusted selectors, not authoritative mailbox or message content.
- Type-check payload fields and bind user, mailbox, and message identifiers before fetching or acting.
- Fetch canonical message data from the expected authenticated mailbox before rendering sensitive notification content or performing actions.
- Do not let a payload switch accounts, select an unrelated mailbox, or trigger an action on an arbitrary message.
- Avoid logging complete notification payloads, subjects, senders, message snippets, or identifiers that are not required for diagnostics.
- Keep fallback notification content privacy-preserving when canonical data cannot be fetched or the extension expires.
- Clean up cached account state and temporary resources on success, failure, cancellation, and extension expiration.

## API Resources And Authorization

- Trusted API transport does not make message-derived fields safe to render, parse, store as paths, or execute.
- Keep server-provided resource URLs, attachment resources, cursors, and action URLs constrained to the expected Infomaniak API origin and account context.
- Never attach bearer credentials or authenticated cookies to arbitrary URLs or cross-origin redirects.
- Verify that user, mailbox, message, draft, and attachment identifiers belong to one coherent authorization context before performing an action.
- Do not infer permissions from UI state or stale cached metadata when a fresh authorization decision is required.
- Prevent external identifiers from causing data to be read from or written into another account's Realm, cache, draft, or attachment directory.

## Resource Exhaustion

- Bound message bodies, sub-bodies, recursive MIME structures, HTML DOM depth, CSS scanning, recipients, attachments, archives, image dimensions, and preview work.
- Stream large content instead of loading it entirely into memory when practical.
- Do not trust declared MIME sizes, image dimensions, archive metadata, recipient counts, or server pagination alone.
- Apply limits during download, parsing, decoding, rendering, and persistence.
- Avoid expensive parsing on the main thread and preserve cancellation throughout asynchronous work.
- Ensure cancellation and extension expiration clean up resources and partial state.
- Consider malformed or unexpectedly large user-authored content a reliability and availability risk even when malicious intent is out of scope.

## Secrets And Privacy

- Do not log or report message bodies, subjects, sender or recipient addresses, attachment contents or sensitive names, notification payloads, raw API JSON containing mail, passwords, tokens, authorization headers, cookies, profile data, or pasteboard content.
- Redact sensitive values from errors, Matomo events, Sentry data, diagnostics, and test artifacts.
- Sentry consent does not replace data minimization.
- Store credentials only in platform-provided secure storage and use the narrowest practical Keychain access group.
- Avoid exposing private mail content in notifications, App Intents, pasteboards, previews, screenshots, or background snapshots without an explicit product requirement.
- Verify exported, printed, or shared content does not include unintended messages, metadata, recipients, credentials, or temporary information.

## Review Behaviour

- Inspect directly called helpers when their behavior determines whether a boundary is safe.
- Do not report an issue merely because input is external. Explain the concrete bypass and consequence.
- Do not assume TLS, authentication, App Groups, sandboxing, HTML sanitization, or server-side filtering solves unrelated validation problems.
- Distinguish trusted API infrastructure from externally authored mail content carried by the API.
- Distinguish directly user-authored content from quoted, forwarded, shared, imported, AI-generated, or restored content.
- Prefer validation at the boundary before side effects, then pass a typed or validated representation inward.
- Avoid duplicate validation unless each check protects a distinct boundary; explain those boundaries when both checks are necessary.
- Preserve existing behavior unless it is unsafe.
- Request focused positive and negative tests for the accepted contract and realistic bypasses.
- If no concrete issue is found, state that clearly and list only meaningful residual assumptions or testing gaps.

## Finding Format

Use this format for concrete findings:

### [Severity] Short title

**Location:** `path/to/file:line`

**Boundary:** How untrusted data enters or changes trust level.

**Attack path:** The concrete sequence from attacker-controlled input to the vulnerable operation.

**Impact:** What another sender, application, or website could read, modify, trigger, expose, or exhaust.

**Existing protection:** Relevant validation and why it is insufficient.

**Recommended fix:** The smallest change that closes the boundary.

**Tests:** Focused accepted and rejected cases.

Use these severities:

- **Critical:** Direct compromise of credentials, accounts, private mail, or arbitrary code execution.
- **High:** Unauthorized sensitive operations, substantial mail exposure, credential leakage, or sandbox-boundary bypass.
- **Medium:** Constrained exposure, persistent spoofing, meaningful denial of service, phishing-enabling behavior, or an exploitable validation weakness.
- **Low:** A defense-in-depth weakness with limited practical impact.

If no concrete issue is found, state:

> No concrete security issue found in the reviewed Infomaniak Mail trust boundaries.

List residual assumptions and untested boundaries separately.
