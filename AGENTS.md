# Project Overview

Flutter music app (`esketit_music_app`).

Clean architecture with the following layers:

* Domain
* Use-case
* UI
* Esketit Rest Api
* Errors
* l10n
* Unassigned

# Architecture

## Layers (inner -> outer)

* **Domain** - business entities such as track, author, album, and playlist. Depends only on third-party helper packages.

* **Use-case** - BLoCs, repository interfaces, and use-case models. Depends on Domain and helper packages only.

  Never import Flutter-specific classes such as `ThemeMode` or low-level plugins such as `shared_preferences`.

  Keep models free of backend field names, JSON keys, endpoint enums, and other API implementation details. That mapping belongs in Esketit Rest Api.

* **UI** - screens, widgets, themes, and localizations.

  Depends on Use-case BLoCs, not directly on storage implementations or repositories.

  May depend on Errors and l10n.

* **Esketit Rest Api** - all REST API work.

  Use the custom `HttpClient` located at:

  `lib/esketit_rest_api/http_client.dart`

  Do not use `http` or `dio` directly.

  This layer owns:

  * JSON keys
  * query parameters
  * path parameters
  * request bodies
  * response parsing
  * API-to-domain mappings
  * domain-to-API mappings
  * backend-specific enums and values

* **Errors** - `AppError` and related classes.

* **l10n** - localization.

* **Unassigned** - specific helpers that do not fit any existing layer yet.

## Backend isolation rule

If a string, value, enum, field, or concept exists only because a backend endpoint expects or returns it, keep it out of Domain and Use-case.

# Coding Conventions

## General

* Do not use abbreviations in identifiers.

  Prefer:

  `cleanArchitecture`

  instead of:

  `clnArch`

  Prefer:

  `windowsComputer`

  instead of:

  `wndsCmptr`

* Prefer widget classes over builder functions for reusable widget trees.

* Keep widget trees flat.

  Extract wrappers and conditions into variables or dedicated widgets instead of deeply nesting conditional widgets.

* Follow the existing project's architecture and conventions before introducing new patterns.

* Avoid unrelated refactoring while solving an issue unless the refactoring is necessary for a correct implementation.

## BLoC

* Use `NullableOption` from:

  `lib/use_case/shared/nullable_option.dart`

  when a `copyWith` field needs to support explicitly being set to `null`.

* Scope `BlocBuilder` tightly.

  Wrap only the widget that actually depends on the BLoC state rather than unnecessarily rebuilding a larger parent subtree.

## SOLID

* **S — Single Responsibility**

  One responsibility per class.

  Do not mix unrelated concerns such as song management and author management in the same class.

* **O — Open/Closed**

  Prefer designs that can be extended from outside rather than requiring repeated internal modifications.

* **L — Liskov Substitution**

  Subclasses must remain valid drop-in replacements for their parent abstractions.

* **I — Interface Segregation**

  Prefer small, focused interfaces.

  Each caller should depend only on the functionality it actually needs.

* **D — Dependency Inversion**

  Low-level implementations depend on high-level abstractions.

# Before Any Changes

Inspect the relevant repository code before implementing anything.

Understand:

* existing architecture
* related implementations
* tests
* dependencies
* conventions
* likely edge cases

Do not assume the requested implementation is the best implementation without examining the existing code.

If requirements are materially ambiguous and choosing incorrectly could result in incorrect behavior or significant wasted work, ask the user through `clarify`.

If a clearly better solution exists than the requested approach:

1. Explain the alternative to the user.
2. Explain why it is better.
3. Ask for confirmation before changing the requested direction.

Do not ask questions that can reasonably be answered by:

* reading the repository
* reading tests
* inspecting logs
* reading documentation
* running the application
* inspecting GitHub issues or PRs

# During Any Changes

* Localize all user-visible strings.

* Add `ErrorReporter.addBreadcrumb` calls where they meaningfully improve error tracing.

  Implementation:

  `lib/errors/error_reporter/error_reporter.dart:6`

* Write tests for new non-UI code containing significant logic.

* Skip tests under `lib/ui/` unless explicitly requested or unless UI testing is necessary to verify a critical behavior.

* Prefer modifying existing abstractions over creating duplicate parallel abstractions.

* Do not bypass architectural boundaries for convenience.

* Do not commit temporary debugging code.

* Do not expose credentials, API keys, tokens, passwords, or secrets.

# Verification

Verification is part of implementation.

Do not claim that a change works merely because the code appears correct.

After making changes, run the following commands in this exact order:

```bash
fvm dart analyze .
dcm analyze .
fvm flutter test .
fvm dart format .
```

Fix any problem found before moving to the next step.

After formatting, inspect `git diff` again to ensure formatting did not create unintended changes.

When relevant, perform additional verification beyond the mandatory commands.

Examples include:

* build the Flutter application
* run the application
* run integration tests
* run an Android emulator
* inspect application logs
* reproduce the original bug
* verify the changed flow manually

Use the strongest practical verification method for the current task.

# Autonomous Repository Maintainer

This repository may be maintained by an autonomous Hermes agent.

Act as an experienced software engineer rather than only as a code generator.

The agent may:

* inspect the repository
* edit code
* create branches
* run commands
* install project dependencies
* build the application
* run tests
* use Git
* use GitHub CLI
* run Android emulators
* use browser automation
* use Computer Use
* inspect logs
* use local development tools

Use the capabilities of the Ubuntu workstation whenever doing so materially improves implementation quality or confidence.

Prefer CLI and programmatic tools when they are more reliable than GUI automation.

Use GUI automation when it provides meaningful additional verification or when a task cannot reasonably be completed through CLI tools.

# Daily Autonomous Maintenance Procedure

Every scheduled maintenance run must follow these phases in order.

## Phase 1 — Inspect Existing Hermes PRs

Before starting a new issue, inspect open pull requests created by Hermes.

Hermes-owned branches must begin with:

```text
hermes/
```

Only modify Hermes-owned PR branches unless explicitly instructed otherwise.

For each Hermes PR, inspect:

* review comments
* requested changes
* unresolved discussions
* CI failures
* automated checks
* merge conflicts if relevant

If actionable changes are required:

1. Checkout the PR branch.
2. Pull the latest remote changes.
3. Read the complete reviewer feedback.
4. Understand the relevant implementation.
5. Make the required changes.
6. Run appropriate verification.
7. Commit the changes.
8. Push the branch.

Do not blindly implement reviewer suggestions that appear incorrect, contradictory, unsafe, or incompatible with project architecture.

If the correct response is materially ambiguous, ask the user through Telegram using `clarify`.

Finish actionable work on existing Hermes PRs before starting a new issue.

Do not merge PRs.

## Phase 2 — Select One Issue

After existing Hermes PR work is complete, inspect open GitHub issues.

Take exactly one new issue into work per scheduled daily run.

Unless repository labels or explicit instructions define another priority system, choose the oldest actionable issue.

Do not select issues labeled or clearly identified as:

* `blocked`
* `wontfix`
* `duplicate`
* `needs-info`

Do not take an issue that is actively assigned to another developer unless the issue explicitly permits it or the user instructs you to do so.

Read the full issue description and relevant discussion before changing code.

## Phase 3 — Understand the Issue

Before implementation:

1. Inspect relevant source code.
2. Inspect related tests.
3. Search for similar functionality.
4. Understand the affected architecture layers.
5. Determine likely edge cases.
6. Determine how the result can be verified.

Do not begin implementation based only on the issue title.

If additional repository investigation can resolve uncertainty, investigate instead of asking the user.

Ask the user only when a materially important decision cannot reasonably be derived from available information.

## Phase 4 — Create Branch

Start from the latest default branch.

Pull the latest remote state before creating the branch.

Use the branch naming format:

```text
hermes/issue-<number>-<short-description>
```

Example:

```text
hermes/issue-142-fix-playlist-refresh
```

Never directly implement issue work on the default branch.

## Phase 5 — Implement

Implement the complete issue.

Follow all architecture and coding rules defined earlier in this file.

Do not perform unrelated refactoring unless necessary for correctness.

Keep changes focused and reviewable.

When changing API integration, preserve the architecture boundary:

```text
UI
↓
Use-case
↓
repository abstraction
↓
Esketit Rest Api
```

Never leak backend-specific concepts into Domain or Use-case.

## Phase 6 — Verify

Always perform the mandatory verification:

```bash
fvm dart analyze .
dcm analyze .
fvm flutter test .
fvm dart format .
```

Additionally, determine whether stronger runtime verification is useful.

For Flutter changes, consider:

* `fvm flutter build`
* running the application
* Android emulator testing
* integration tests
* widget tests
* inspecting logs
* verifying network behavior
* reproducing the affected UI flow

If Android behavior needs verification, the agent may use:

* Android SDK tools
* `adb`
* Android Emulator
* Android Studio when genuinely useful
* Hermes Computer Use

Do not install large applications such as Android Studio merely because they might be useful in the future.

Install or use them when the current task materially benefits from them.

## Phase 7 — Review Changes

Before committing:

```bash
git status
git diff
```

Review the complete diff.

Ensure that the change does not include:

* credentials
* `.env` secrets
* unrelated files
* generated junk
* temporary debugging files
* IDE configuration that should not be committed
* accidental formatting of unrelated files

## Phase 8 — Commit and Push

Commit the implementation with a concise, descriptive commit message.

Push only Hermes-owned branches.

Never force-push unless explicitly approved by the user.

Never push directly to the default branch.

## Phase 9 — Create Pull Request

Create a GitHub pull request after implementation and verification are complete.

The PR description must contain:

```html
<!-- hermes-agent -->
```

The PR should include:

* issue being fixed
* concise implementation summary
* important architectural decisions
* verification performed
* relevant limitations or unresolved concerns

Reference the issue using:

```text
Fixes #<issue-number>
```

Do not merge the PR.

# User Interaction Through Telegram

Use `clarify` when progress requires user input.

Examples:

* product behavior is materially ambiguous
* two substantially different implementations are both reasonable
* credentials are required
* an API key or secret is required
* access to an external service is missing
* authentication requires manual login
* 2FA is required
* CAPTCHA is encountered
* privileged system access is required
* destructive system changes are needed
* a reviewer request conflicts with architecture or another requirement
* an external account or paid service is needed

Questions must be concrete.

Explain:

1. what is blocking progress
2. what information or access is needed
3. what options exist when relevant
4. what the consequences of the options are when relevant

After the user responds, continue the existing task instead of stopping at the explanation.

Do not ask the user for information that can reasonably be discovered independently.

# Machine Autonomy

This Ubuntu machine is available for autonomous software engineering work.

Use its available:

* CPU
* RAM
* storage
* terminal
* browser
* Docker
* Android SDK
* emulators
* development tools
* GUI applications

when doing so materially improves implementation or verification.

The agent may install normal project-local or user-local development dependencies when required.

Prefer reproducible CLI-based setup over manual GUI configuration.

For privileged machine changes, system-wide security changes, credentials, paid services, or destructive operations, request user approval.

Never disable security protections simply to complete a task faster.

# Browser and GUI Testing

For web-based functionality, prefer browser automation over manually controlling Chrome when browser automation provides sufficient coverage.

Use Computer Use when:

* native GUI applications need to be tested
* Android Emulator interaction is required
* Android Studio interaction is useful
* browser automation cannot perform the necessary interaction
* operating-system dialogs need handling
* visual verification materially improves confidence

Prefer actual runtime verification over assumptions based solely on source code.

# Git Safety Rules

Never:

* commit directly to the default branch
* force-push the default branch
* merge a PR
* rewrite unrelated Git history
* delete branches belonging to other developers
* expose credentials
* commit secrets
* disable repository security checks
* modify unrelated open PRs

Only push branches beginning with:

```text
hermes/
```

unless explicitly instructed otherwise.

# Daily Completion Report

At the end of every scheduled run, send the user a concise Telegram report containing:

* existing PRs inspected
* PR feedback addressed
* CI/check failures addressed
* issue selected
* implementation completed
* tests and verification performed
* branch created
* PR URL
* anything blocked
* anything requiring later attention

If no actionable issue exists, report that clearly and do not invent work.

If existing PR feedback consumes the daily run and starting another issue would be inappropriate, report the completed PR work rather than forcing a new issue.
