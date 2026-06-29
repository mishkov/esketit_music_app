# iOS TestFlight Deployment

This project uploads iOS builds to TestFlight with Fastlane from
`.github/workflows/ios-testflight.yml`.

The workflow runs when you start it manually from GitHub Actions or when you
push a tag that matches `ios-v*`, for example:

```bash
git tag ios-v2.3.3-15
git push origin ios-v2.3.3-15
```

## App Store Connect setup

1. In Apple Developer, make sure the bundle identifier exists:
   `com.mishkov.esketitMusicApp`.
2. In App Store Connect, create the app record for that bundle identifier if it
   does not exist yet.
3. In App Store Connect, create an API key from Users and Access > Integrations
   > App Store Connect API. Give it enough access to upload TestFlight builds,
   for example App Manager.
4. Download the `.p8` private key immediately. Apple only allows downloading it
   once.

## Signing setup

Create an Apple Distribution certificate and an App Store provisioning profile
for `com.mishkov.esketitMusicApp`.

Create the certificate signing request from the command line:

```bash
mkdir -p ios-signing
openssl genrsa -out ios-signing/apple_distribution.key 2048
openssl req \
  -new \
  -key ios-signing/apple_distribution.key \
  -out ios-signing/apple_distribution.csr \
  -subj "/emailAddress=YOUR_APPLE_ID_EMAIL,CN=YOUR_NAME,C=US"
```

Then:

1. In Apple Developer, create an Apple Distribution certificate and upload
   `ios-signing/apple_distribution.csr`.
2. Download the generated `.cer` certificate as
   `ios-signing/apple_distribution.cer`.
3. Convert the certificate and private key into the password-protected `.p12`
   file used by CI:

   ```bash
   openssl x509 \
     -in ios-signing/apple_distribution.cer \
     -inform DER \
     -out ios-signing/apple_distribution.pem \
     -outform PEM
   openssl pkcs12 \
     -export \
     -inkey ios-signing/apple_distribution.key \
     -in ios-signing/apple_distribution.pem \
     -out ios-signing/distribution.p12 \
     -name "Apple Distribution"
   ```

4. Create and download an App Store provisioning profile for the app bundle id.

Keep `ios-signing/apple_distribution.key` private. Do not commit the
`ios-signing` directory or any certificate/profile files.

## GitHub variables

The workflow has defaults for the current project, but you can override them in
Repository Settings > Secrets and variables > Actions > Variables:

| Variable | Current default |
| --- | --- |
| `APPLE_TEAM_ID` | `HXKMZK959F` |
| `IOS_APP_IDENTIFIER` | `com.mishkov.esketitMusicApp` |

## GitHub secrets

Add these in Repository Settings > Secrets and variables > Actions > Secrets:

| Secret | Value |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID for the App Store Connect API key |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID for the App Store Connect API key |
| `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64` | Base64-encoded `.p8` API private key |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Base64-encoded `.p12` Apple Distribution certificate |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded App Store `.mobileprovision` profile |
| `KEYCHAIN_PASSWORD` | Any strong random password for the temporary CI keychain |

Use these commands on macOS to copy base64 values without line breaks:

```bash
base64 -i AuthKey_KEYID.p8 | tr -d '\n' | pbcopy
base64 -i ios-signing/distribution.p12 | tr -d '\n' | pbcopy
base64 -i AppStore.mobileprovision | tr -d '\n' | pbcopy
```

## Versioning

Flutter maps `pubspec.yaml` version `2.3.3+14` to iOS marketing version
`2.3.3` and build number `14`. App Store Connect requires each uploaded build
number to be higher than the previous uploaded build for the same version.
Increment the number after `+` before uploading another build.

## Local Fastlane run

The CI workflow installs signing assets before running Fastlane. For local runs,
make sure your Apple Distribution certificate and App Store provisioning profile
are installed in a local keychain, then run:

```bash
cd ios
bundle install
bundle exec pod install
APPLE_TEAM_ID=HXKMZK959F \
IOS_APP_IDENTIFIER=com.mishkov.esketitMusicApp \
IOS_PROVISIONING_PROFILE_NAME='Your App Store profile name' \
APP_STORE_CONNECT_API_KEY_ID=KEYID \
APP_STORE_CONNECT_ISSUER_ID=ISSUER_ID \
APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64="$(base64 -i AuthKey_KEYID.p8 | tr -d '\n')" \
bundle exec fastlane ios upload_testflight
```
