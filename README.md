# esketit_music_app

A new Flutter project.

## Deploy to own server

Build the web app for serving from the domain root and route API calls through
nginx `/api/`:

```bash
flutter build web --release --base-href / --dart-define BASE_URL=/api/
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
