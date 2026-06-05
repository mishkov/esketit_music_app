# Project Overview

Flutter music app (esketit_music_app). Clean architecture with Domain / Use-Case / UI / Esketit Rest Api / Errors / l10n / Unassigned layers.

# Architecture

## Layers (inner → outer)

- **Domain** — business entities (track, author, album, playlist). Depends only on third-party helper packages.
- **Use-case** — BLoCs, repositories interfaces, use-case models. Depends on Domain and helper packages only. Never imports Flutter-specific classes (e.g. `ThemeMode`) or low-level plugins (e.g. `shared_preferences`). Keep models free of backend field names, JSON keys, or endpoint enums — that mapping belongs in Esketit Rest Api.
- **UI** — screens, widgets, themes, localizations. Depends on Use-case BLoCs (not directly on storage/repositories). May depend on Errors and l10n.
- **Esketit Rest Api** — all REST work. Uses the custom `HttpClient` (`lib/esketit_rest_api/http_client.dart`), not `http`/`dio` directly. Owns JSON keys, query/path params, request bodies, response parsing, and API↔domain enum mapping.
- **Errors** — `AppError` and related classes.
- **l10n** — localization.
- **Unassigned** — specific helpers that don't fit any layer yet.

**Rule:** if a string/value exists only because one backend endpoint expects or returns it, keep it out of Domain and Use-case.

# Coding Conventions

## General

- No abbreviations in identifiers: `cleanArchitecture` not `clnArch`, `windowsComputer` not `wndsCmptr`.
- Prefer widget classes over builder functions for reusable widget trees.
- Keep widget trees flat: extract wrappers into variables rather than nesting conditionals inside the tree.

## BLoC

- Use `NullableOption` (`lib/use_case/shared/nullable_option.dart`) when a `copyWith` field must support being set to `null`.
- Scope `BlocBuilder` tightly — wrap only the widget that actually depends on state, not its parent subtree.

## SOLID

- **S** — one responsibility per class (don't mix song management with author management).
- **O** — design for extension from outside rather than internal modification.
- **L** — subclasses must be drop-in replacements for their parents.
- **I** — small, focused interfaces; each caller gets only what it needs.
- **D** — low-level classes depend on high-level abstractions.

# Before Any Changes

- If requirements are ambiguous, ask before starting.
- If a better solution exists than what was requested, explain it first, then implement after confirmation.

# During Any Changes

- Localize all user-visible strings.
- Add `ErrorReporter.addBreadcrumb` calls (`lib/errors/error_reporter/error_reporter.dart:6`) where useful for tracing errors.
- Write tests for new non-UI code that carries significant logic. Skip tests under `lib/ui/` unless explicitly requested.

# After Any Changes

Run in order — fix any issues found before proceeding to the next step:

```bash
dart analyze .
dcm analyze .
flutter test .
dart format .
```
