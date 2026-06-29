# esketit_music_app

A new Flutter project.

## Deploy iOS to TestFlight

The iOS app is built and uploaded to TestFlight with Fastlane through
`.github/workflows/ios-testflight.yml`. See
[docs/ios-testflight.md](docs/ios-testflight.md) for the required Apple
Developer, App Store Connect, certificate, provisioning profile, and GitHub
secret setup.

## Deploy to own server

Build the web app for serving from the domain root and route API calls through
nginx `/api/`:

```bash
flutter build web --release --base-href / --dart-define BASE_URL=/api/
```

Make sure nginx serves the Flutter app for direct client-side routes such as
`/playlists/7` and `/playlists/shared/<token>`:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

Copy the build output to the server:

```bash
rsync -az --delete build/web/ <user>@<server>:/tmp/esketit_music_app/
```

Install the new files on the server:

```bash
sudo mkdir -p /var/www/esketit_music_app
sudo rsync -a --delete /tmp/esketit_music_app/ /var/www/esketit_music_app/
sudo chown -R www-data:www-data /var/www/esketit_music_app
sudo nginx -t
sudo systemctl reload nginx
```
