# Agent chat

Agent is visible after Search only when the server grants access. It requires
`agent.use`, a configured agent service, and an account matching the MCP acting
user. The permission is enforced server-side for every request. Follow the
server repository's `AGENT.md` to configure Go, Python, PostgreSQL, OpenAI and MCP.
The agent defaults to `gpt-5.4-mini`, with no automatic model upgrade or fallback.

Every Ask Agent action creates a new draft with an item attached. Sending creates
the durable request. Same-item requests wait for earlier work and reviews, then
reassess the current item before acting. Stop preserves resumable state; Resume
or the message `resume` continues it. Cancel abandons remaining agent work, while
submitted changes remain in review. Questions and answers live on the server.

## Push setup

Create a Firebase project and register the intended iOS bundle identifiers:
`com.mishkov.esketitMusicApp` and, when testing the dev flavor,
`com.mishkov.esketitMusicApp.dev`. Enable Push Notifications on those Apple App
IDs, configure the APNs authentication key in Firebase, and regenerate signing
profiles that include the push entitlement. Debug builds use development APNs;
Profile/Release builds use production APNs. Never commit private keys.

Pass public Firebase application configuration through a local, untracked
`--dart-define-from-file` file containing:

```json
{
  "FIREBASE_PROJECT_ID": "your-project",
  "FIREBASE_API_KEY": "your-public-app-api-key",
  "FIREBASE_APP_ID": "your-platform-specific-app-id",
  "FIREBASE_MESSAGING_SENDER_ID": "your-sender-id",
  "FIREBASE_IOS_BUNDLE_ID": "com.mishkov.esketitMusicApp"
}
```

For web, use the web application's app ID, set `FIREBASE_WEB_VAPID_KEY`, and
deploy `firebase-config.js` using `web/firebase-config.example.js`. It contains
the same public web app configuration. HTTPS and a push-capable browser are
required. Serve JavaScript files normally; do not rewrite them to index.html.
The messaging SDK registers `firebase-messaging-sw.js` when notifications are
enabled. Remote notification text contains no catalog or conversation contents.

In Agent, choose **Enable notifications**. Tapping a notification opens the
corresponding chat after authentication/access restoration. Device registrations
are refreshed automatically and invalidated when the account changes.

Without `FIREBASE_PROJECT_ID`, push is disabled and the rest of the app works.
Live delivery requires a configured Firebase project, server credentials and a
signed device build; it cannot be verified using an unconfigured project.

## Verification

Run, in order: `fvm dart analyze .`, `dcm analyze .`, `fvm flutter test .`,
`fvm dart format .`. Also build iOS and web, exercise the actual app with the
server, verify notification cold starts on iOS, and retain runtime UI captures
outside Git. Configure local API addresses with the existing `BASE_URL` define.
Run `node --test test/web/firebase_messaging_worker_test.js` for the web
notification click handler. It registers before Firebase's default handler,
following the [Firebase guidance](https://firebase.google.com/docs/cloud-messaging/web/receive-messages).
