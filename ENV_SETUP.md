# Environments (dev / prod)

The app runs against a **dev** or **prod** backend selected by a Flutter
**flavor** plus a `--dart-define-from-file` env file. All URLs/keys read by Dart
come from `env/dev.json` or `env/prod.json` via `lib/core/config/app_env.dart`
(`Env`), and default to **dev** when nothing is passed.

## Env files

| file | committed? | purpose |
| --- | --- | --- |
| `env/dev.json` | ✅ yes | dev config (non-secret) |
| `env/prod.json` | ❌ gitignored | real prod config (may hold keys) |
| `env/prod.json.example` | ✅ yes | template — copy to `env/prod.json` |

Keys: `FLAVOR`, `APP_NAME`, `API_BASE_URL`, `WS_BASE_URL`,
`GOOGLE_PLACES_KEY_ANDROID`, `GOOGLE_PLACES_KEY_IOS` (Places keys optional —
empty falls back to the defaults in `GoogleConfig`).

First-time setup:
```bash
cp env/prod.json.example env/prod.json   # then fill in any prod-only keys
```

## Run / build

Via Make (see `Makefile`):
```bash
make run_dev        # flutter run --flavor dev  --dart-define-from-file=env/dev.json
make run_prod       # flutter run --flavor prod --dart-define-from-file=env/prod.json
make build_apk_dev
make build_apk_prod
make build_ios_dev
make build_ios_prod
```
Or directly:
```bash
flutter run --flavor dev --dart-define-from-file=env/dev.json
```

> With flavors defined you **must** pass `--flavor dev|prod` (a plain
> `flutter run` will fail asking for a flavor).

## Android — done ✅

`android/app/build.gradle.kts` defines `dev` / `prod` product flavors:
- `dev` → applicationId `com.massdrive.customer_app.dev`, app name **Customer Dev**
- `prod` → applicationId `com.massdrive.customer_app`, app name **Customer**
- Google Maps SDK key comes from each flavor's `manifestPlaceholders["mapsApiKey"]`
  (AndroidManifest uses `${mapsApiKey}` and `@string/app_name`).

Both install side-by-side. **TODO:** set the real prod Maps key in the `prod` flavor.

Firebase is per flavor via source sets — the Gradle plugin picks the file up
automatically, no script needed:

| flavor | applicationId | file | Firebase project |
| --- | --- | --- | --- |
| dev | `com.massdrive.customer_app.dev` | `android/app/src/dev/google-services.json` | `mass-ride-delivery` |
| prod | `com.massdrive.customer_app` | `android/app/src/prod/google-services.json` | `prod-mass-ride-delivery` |

There is deliberately **no** `android/app/google-services.json` — a file there
acts as a fallback for every flavor and silently masks a missing per-flavor one.

## iOS — one-time Xcode setup ⚠️

Flutter's `--flavor <name>` maps to an Xcode **scheme**; these must be created
in Xcode (can't be scripted safely). `ios/Flutter/Dev.xcconfig` and
`Prod.xcconfig` are provided as templates.

In Xcode (`open ios/Runner.xcworkspace`):
1. **Duplicate build configs**: Project → Info → Configurations → duplicate
   Debug/Release/Profile into `Debug-dev`, `Release-dev`, `Debug-prod`, … .
2. **Assign xcconfig**: set each build config to its matching per-config file so
   CocoaPods (`#include? Pods-Runner.<type>.xcconfig` via `Debug`/`Release`
   .xcconfig) + `Generated.xcconfig` + flavor overrides all resolve:

   | build configuration | assign |
   | --- | --- |
   | `Debug-dev`   | `Flutter/Debug-dev.xcconfig` |
   | `Release-dev` | `Flutter/Release-dev.xcconfig` |
   | `Profile-dev` | `Flutter/Profile-dev.xcconfig` |
   | `Debug-prod`   | `Flutter/Debug-prod.xcconfig` |
   | `Release-prod` | `Flutter/Release-prod.xcconfig` |
   | `Profile-prod` | `Flutter/Profile-prod.xcconfig` |

   Each per-config file `#include`s the stock `Debug`/`Release` xcconfig (Pods +
   Generated) then the flavor fragment (`Dev.xcconfig`/`Prod.xcconfig`). Do NOT
   assign `Dev.xcconfig`/`Prod.xcconfig` directly — they no longer pull in Pods.
   Profile reuses the Release Pods config, matching the stock Runner target.
3. **Bundle id / name**: in Runner target Build Settings set
   `PRODUCT_BUNDLE_IDENTIFIER = com.massdrive.customerApp$(BUNDLE_ID_SUFFIX)`
   and `Info.plist` `CFBundleDisplayName = $(APP_DISPLAY_NAME)`.
4. **Schemes**: create schemes named exactly `dev` and `prod`, each pointing at
   the matching build configs; mark them **Shared**.
5. **Maps key**: read `$(GOOGLE_MAPS_API_KEY)` from `Info.plist` in
   `AppDelegate.swift` instead of the hardcoded key:
   ```swift
   let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String ?? ""
   GMSServices.provideAPIKey(mapsKey)
   ```
   and add `GOOGLE_MAPS_API_KEY = $(GOOGLE_MAPS_API_KEY)` to `Info.plist`.
6. **Firebase per flavor**: each flavor has its own Firebase iOS app, keyed by
   bundle id, so the right `GoogleService-Info.plist` must be copied in at build
   time:

   | flavor | bundle id | file |
   | --- | --- | --- |
   | dev | `com.massdrive.customerApp.develop` | `ios/config/dev/GoogleService-Info.plist` |
   | prod | `com.massdrive.customerApp` | `ios/config/prod/GoogleService-Info.plist` |

   In Xcode:
   1. Remove the old `GoogleService-Info.plist` from the Runner target's
      **Build Phases → Copy Bundle Resources** (the file itself has moved to
      `ios/config/<flavor>/`; do **not** re-add either copy to the target).
   2. Add a **New Run Script Phase**, ordered *before* Copy Bundle Resources:
      ```sh
      # Pick the Firebase config matching the flavor (from BUNDLE_ID_SUFFIX).
      case "$CONFIGURATION" in
        *-dev)  FLAVOR_DIR=dev ;;
        *)      FLAVOR_DIR=prod ;;
      esac
      SRC="${SRCROOT}/config/${FLAVOR_DIR}/GoogleService-Info.plist"
      [ -f "$SRC" ] || { echo "error: missing $SRC"; exit 1; }
      cp "$SRC" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
      ```

Until step 4 is done, `--flavor` on iOS will fail. The Dart-side env
(`API_BASE_URL` etc.) already works on iOS once the scheme exists.

Until step 6 is done the app has **no** `GoogleService-Info.plist` in its
bundle and Firebase will fail to initialise — the plist is no longer bundled
directly, it is copied by the run-script phase.
