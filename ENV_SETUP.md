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
| `env/prod-devapi.json` | ✅ yes | **ชั่วคราว** — flavor prod แต่ชี้ API/WS ของ dev (ดูด้านล่าง) |

Keys: `FLAVOR`, `APP_NAME`, `API_BASE_URL`, `WS_BASE_URL`,
`GOOGLE_PLACES_KEY_ANDROID`, `GOOGLE_PLACES_KEY_IOS` (Places keys optional —
empty falls back to the defaults in `GoogleConfig`).

First-time setup:
```bash
cp env/prod.json.example env/prod.json   # then fill in any prod-only keys
```

## prod ชี้ dev API (ชั่วคราว) ⚠️

backend prod (`driver-api.nutchaphut.dev`) ยังไม่ขึ้น — Cloudflare ตอบ **502** ทุก path
(dev host `driver-api-dev.nutchaphut.dev` ตอบ 200 ปกติ) ระหว่างนี้จึง build ด้วย
`env/prod-devapi.json` — flavor `prod` เหมือนเดิม (applicationId / bundle id / ชื่อ
"Customer" จริง) แต่ `API_BASE_URL` / `WS_BASE_URL` ชี้ dev

```bash
make run_prod_devapi          # รันบนเครื่อง
make build_aab_prod_devapi    # AAB อย่างเดียว
make ipa_prod_devapi          # IPA อย่างเดียว
make deploy_prod_devapi       # bump + IPA + TestFlight
make deploy_play_prod_devapi  # bump + AAB + Play internal
make deploy_both_prod_devapi  # bump ครั้งเดียว → ส่งทั้ง TestFlight + Play
```

`deploy_both_prod_devapi` มีไว้เพราะ `deploy_prod_devapi` กับ `deploy_play_prod_devapi`
ต่างก็ `bump` เอง ถ้ารันต่อกันเลข build จะขยับสองครั้ง (`+49` แล้ว `+50`) iOS กับ Android
เลยไม่ตรงกัน ตัวรวมทำ `bump` รอบเดียวแล้ว build ให้ครบทั้งสองก่อนค่อย upload —
ถ้าฝั่งไหน build พังจะไม่มี artifact หลุดขึ้น store ไปก่อน

ถ้า build ค้างไว้แล้วอยาก upload ซ้ำอย่างเดียว (ไม่ bump ไม่ build):

```bash
make upload_testflight_prod_devapi
make upload_play_prod_devapi
```

ทำไมต้องมีไฟล์แยก: `env/prod.json` อยู่ใน `.gitignore` (มีเฉพาะเครื่องแต่ละคน)
ค่าที่ตั้งไว้จึง track ไม่ได้ ไฟล์แยกทำให้ทุกเครื่อง/CI build ได้เหมือนกัน
และ `env/prod.json.example` ยังเป็น template ของ prod จริงไม่โดนแก้

ข้อจำกัด — **push notification จะไม่เข้า**: prod flavor ใช้ Firebase project
`prod-mass-ride-delivery` แต่ backend dev ส่ง push ผ่าน `mass-ride-delivery`
ไม่กระทบส่วนอื่น — ล็อกอินเป็น OTP เบอร์โทรที่ backend ออก token เอง ไม่ได้ใช้
Firebase Auth และ register device token ที่ `push_notification_service.dart` จับ error ทิ้งอยู่แล้ว

เมื่อ backend prod ขึ้น: กลับไปใช้ `make run_prod` / `build_aab_prod` / `deploy_play_prod`
ตามเดิม แล้วลบ `env/prod-devapi.json` + กลุ่ม target `*_devapi` ใน `Makefile` ทิ้ง
(อย่าลืมเช็คว่า `env/prod.json` ในเครื่องชี้ host ประจำจริงหรือยัง)

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
- `dev` → applicationId `com.massdrive.customer_app.dev`, app name **Mass Delivery Dev**
- `prod` → applicationId `com.massdrive.customer_app`, app name **Mass Delivery**
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
