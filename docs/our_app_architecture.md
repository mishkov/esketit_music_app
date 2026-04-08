# Layers

## Domain

Here we put the most closest things to bussiness domain. In our case it's track, author, album, playlist etc.

## Use Case

This layer can depend only on domain layer or third-party helpers packages. Specifically, for instance, this layer cannot depend directly on Flutter's `ThemeMode` class because it's very specific details about how ui is implemented. Also this layer cannot depend on such plugins like `shared_preferences` because it's very low-level details how data is stored. But it's okay to import `flutter_bloc`, `bloc`, `equatable`, `meta` etc.

## UI

On this layer we put all screens, button, views, localizations, themes etc.

## Esketit Rest Api

Here we put any work with esketit rest api but we don't mention any specific http client like `http` or `dio` plugin instead we use our custom (HttpClient)[lib/esketit_rest_api/http_client.dart]

## Errors

Here we put any work around `AppError` class.

## l10n

Here we put any work with localization

## Unassigned Layer

Here we put any specifc, non-abstract classes/helpers that does not depend to previously defined layers because for example currently we don't know exact layer or new layer is not defined for such classes yet.

# How layers depends on each other

We are trying to keep clean architecture approach so consider it like in Robert Martin's book "Clean Architecture". If we image the architecture like circles then (from circle center to outside):

- `Domain`. This is the most hight level layer. It can depend only on third party helpers packages
- `Use-case`. This layer can depend on `Domain` and on third party helpers packages
- `UI`, `Esketit Rest Api`, `Errors`, `l10n`, `Unassigned Layer` etc. this layers are the most low level. They can depend on any other layer and can import any third party plugin but there is still some limitations. For example `UI` should not depend on `Esketit Rest Api` becuase ui should not know how we work with data but `UI` can depend on `Errors`, `l10n` because we want to identify the error and show related localized message to user. Shortly, we should keep as less as possible links to other layer to simplify their changes and replacement in future.