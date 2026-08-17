# Google Play deploy pipeline (Android)

The Android equivalent of the iOS TestFlight flow. `make deploy_play_dev` bumps
the build number, builds a signed AAB, and uploads it to the **internal testing**
track via fastlane `supply`.

```
make deploy_play_dev     # dev flavor  → com.massdrive.customer_app.dev, internal track
make deploy_play_prod    # prod flavor → com.massdrive.customer_app,     internal track
make deploy_play_check   # verify the service-account JSON only (no upload)
make build_aab_dev       # just build the AAB (no bump, no upload)
```

The gradle signing config (`android/app/build.gradle.kts`) and the `.gitignore`
for secrets are already in place. What's left is **one-time setup** with three
secrets that only you can create. None of them are committed.

---

## What is already done (in this repo)

- `android/app/build.gradle.kts` — release `signingConfig` reads `android/key.properties`; falls back to debug keys when it's absent.
- `android/fastlane/Appfile` + `Fastfile` — `deploy` and `whoami` lanes.
- `android/Gemfile` — fastlane.
- `Makefile` — `build_aab_*`, `deploy_play_*`, `deploy_play_check`.
- `android/.gitignore` — ignores `key.properties`, `**/*.jks`, `fastlane/play-service-account.json`.
- `android/key.properties.example` — template.

## What you need to provide (one-time)

### 1. Upload keystore + `key.properties`

```bash
# generate the upload keystore (pick strong passwords, keep them safe)
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# create key.properties from the template and fill in the passwords
cp android/key.properties.example android/key.properties
```

Both files are gitignored. **Back up the keystore + passwords** — losing them
means you can't ship updates (unless enrolled in Play App Signing, see below).

### 2. Google Play Console app

1. In [Play Console](https://play.google.com/console) → **Create app**.
2. Create the app with package name:
   - dev pipeline → `com.massdrive.customer_app.dev`
   - prod pipeline → `com.massdrive.customer_app`
3. Enroll in **Play App Signing** (recommended default). Google holds the app
   signing key; your `upload-keystore.jks` is just the upload key.
4. Do the **first release manually** in the console (upload one AAB by hand):
   Google requires the app to exist and pass initial setup before the API can
   push to it. After that, `fastlane supply` handles every subsequent upload.

### 3. Service-account JSON (API access)

1. [Play Console → Setup → API access](https://play.google.com/console) → link a
   Google Cloud project → **Create service account** (opens Google Cloud).
2. In Google Cloud, create the service account and a **JSON key**; download it.
3. Back in Play Console → grant that service account access to this app with at
   least the **Release** permission (Release manager / Release apps to testing
   tracks).
4. Save the JSON here (gitignored):

```
android/fastlane/play-service-account.json
```

Verify it works:

```bash
cd android && bundle install    # once
make deploy_play_check          # → "Service-account JSON is valid for ..."
```

---

## Deploying

```bash
make deploy_play_dev
```

This runs: `bump` → `flutter build appbundle --flavor dev` → `fastlane deploy
track:internal`. Testers on the internal track get it within minutes.

Override track/status when needed:

```bash
cd android && AAB_PATH=... bundle exec fastlane deploy track:beta status:draft
```

## Notes

- `versionCode` comes from the pubspec `+N` (Flutter maps it). Play rejects a
  reused code, so each upload must bump — the deploy targets bump for you.
- `deploy_play_prod` also needs a real `env/prod.json` (copy `env/prod.json.example`
  and fill the production Google Maps key) — the prod flavor currently reuses the
  dev Maps key placeholder.
- CI: set `PLAY_JSON_KEY_FILE` to the secret path and provide `key.properties` +
  keystore from encrypted secrets; the lanes read both via env.
