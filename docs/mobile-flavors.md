# Mobile flavors

The mobile apps have production and development identities so both versions
can be installed on the same device.

| Platform | Production identity | Development identity |
| --- | --- | --- |
| Android | `com.mishkov.esketitMusicApp` (`production`) | `com.mishkov.esketitMusicApp.dev` (`dev`) |
| iOS | `com.mishkov.esketitMusicApp` (existing `Runner` scheme) | `com.mishkov.esketitMusicApp.dev` (`dev` scheme) |

The development build is displayed as `Esketit Music Dev` and uses its own app
icon. The production build is displayed as `Esketit Music` and uses the current
icon.

Changing Android's production application ID from the previous local-only
`com.example.esketit_music_app` means it will not update an older build with
that ID. The old local app can be uninstalled when its data is no longer
needed.

## Run locally

List available devices when a device ID is needed:

```bash
fvm flutter devices
```

Run the development app on the selected iOS or Android device:

```bash
fvm flutter run --flavor dev
```

Pass `-d <device-id>` when more than one compatible device is available. For
example, to target a physical iPhone explicitly:

```bash
fvm flutter run --flavor dev -d <iphone-device-id>
```

Android production is also a named flavor:

```bash
fvm flutter run --flavor production -d <android-device-id>
```

iOS production continues to use the existing unflavored `Runner` scheme:

```bash
fvm flutter run -d <iphone-device-id>
```

Do not pass `--flavor` when running web or macOS. The project intentionally has
no global default flavor because a mobile default would also be applied to
those platforms.

VS Code provides separate launch configurations for mobile development, web
debugging, Android production, and unflavored production platforms. Before
starting a mobile configuration, select a compatible iOS or Android device in
the status bar. The mobile configuration name cannot constrain VS Code's
selected device, and Flutter does not support these mobile flavors on web or
macOS.

Both debug launch paths keep the existing `BASE_URL` prompt and Dart-define
behavior. Selecting an app flavor does not select a backend.

## Build locally

Useful unsigned or local smoke builds are:

```bash
fvm flutter build apk --debug --flavor dev
fvm flutter build apk --release --flavor production
fvm flutter build ios --debug --no-codesign --flavor dev
fvm flutter build ios --release --no-codesign
```

The Android production release currently uses the project's existing debug
signing configuration, so it is suitable only for local smoke testing. Before
the first Google Play release, configure a private upload/release key and keep
its credentials outside the repository.

The development flavor is currently for direct local installation only. The
production TestFlight workflow remains unchanged and does not build or upload
the development flavor.

## Regenerate launcher icons

The checked-in source images are `assets/icons/app_icon.png` and
`assets/icons/app_icon_dev.png`. After changing either source image, regenerate
both platforms and both flavors from the repository root:

```bash
fvm dart run flutter_launcher_icons
```

The two `flutter_launcher_icons-*.yaml` files are discovered automatically.

## Install on a physical iPhone

An App Store Connect app record is **not** required to run the development
flavor directly on a physical iPhone. The first time it is installed, select
the appropriate development team in Xcode and keep automatic signing enabled.
Xcode may register `com.mishkov.esketitMusicApp.dev` in the Apple Developer
account and create or update a development provisioning profile. Those Apple
Developer signing resources are separate from App Store Connect.

If signing needs to be configured manually, open `ios/Runner.xcworkspace`,
select the `dev` scheme and physical device, then select the development team
for the `Runner` target under Signing & Capabilities. The iPhone must trust the
development computer and have Developer Mode enabled when iOS requires it.

An App Store Connect record, distribution provisioning, and a deployment
workflow would only be needed later if the development flavor were distributed
through TestFlight or the App Store.

## Shared services

The flavor currently changes only the installed app identity, display name,
and icon. It does not select a separate environment:

- `BASE_URL` keeps the existing default and can still be overridden with the
  existing Dart define.
- Both flavors use the current Sentry DSN.
- Both flavors send analytics to the current backend.

Because the bundle/application identifiers differ, iOS and Android keep each
flavor's local preferences, secure storage, databases, downloads, permissions,
and other app-scoped data separate.
