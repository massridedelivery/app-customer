# 🚀 Deployment Runbook — TestFlight & Google Play

คู่มือ (SOP) การ build + อัปแอป **customer-app** ขึ้น **TestFlight (iOS)** และ
**Google Play (Android)** ทั้งแบบ **local** (`make …`) และ **CI/CD** (GitHub Actions).

> 📋 **ใช้เป็น template ได้:** เอกสารนี้เป็นทั้ง runbook ของ customer-app และ **แม่แบบ
> ให้แอป Flutter อื่นใน MassApp (เช่น driver app) เอาไปใช้ตาม**. โครงสร้าง
> (Makefile targets / fastlane lanes / GitHub workflows / repo secrets) **เหมือนกันทุกแอป —
> copy ได้เลย**; เปลี่ยนแค่ **"ค่าเฉพาะแอป"** (bundle id, applicationId, env, keystore,
> service account, ASC app, match profiles). ค่าในเอกสารนี้คือตัวอย่างจริงของ customer-app
> ใช้อ้างอิงได้. ดูขั้นตอน onboard แอปใหม่ที่ **§8**.

> **สถานะปัจจุบัน (ชั่วคราว):** backend prod ยังไม่ขึ้น → เรา ship ด้วย **flavor `prod`
> แต่ชี้ API ไป dev** ผ่าน `env/prod-devapi.json`. path หลักที่ใช้ตอนนี้คือ
> `make deploy_prod_devapi` (iOS) และ `make deploy_play_prod_devapi` (Android).
> พอ backend prod ขึ้นแล้ว → กลับไปใช้ `deploy_both_prod` (env/prod.json) แล้วลบชุด
> `*_prod_devapi` + `env/prod-devapi.json` ทิ้ง.

---

## 1. App identities

| | iOS (bundle id → ASC app) | Android (applicationId) | flavor | env file |
|---|---|---|---|---|
| **prod** | `com.massdrive.customerApp` → *Customer* | `com.massdrive.customer_app` | `prod` | `env/prod.json` (จริง, gitignored) |
| **prod→dev API** (ชั่วคราว) | `com.massdrive.customerApp` → *Customer* | `com.massdrive.customer_app` | `prod` | `env/prod-devapi.json` (committed) |
| **dev** | `com.massdrive.customerApp.develop` → *MassCustomerDev* | `com.massdrive.customer_app.dev` | `dev` | `env/dev.json` (committed) |

- Apple Team: **`Q7742Z74Q3`** (`Apple Distribution: MASS RIDE & DELIVERY`)
- ⚠️ อย่าสับสน: `deploy_prod_devapi` ขึ้น app **Customer (prod)** ส่วน `deploy_dev`
  ขึ้น app **MassCustomerDev** — คนละ app / คนละ config.

---

## 2. Prerequisites (เครื่อง Mac สำหรับ local deploy)

| Tool | Version / หมายเหตุ |
|---|---|
| **Xcode** | **26+** (iOS 26 SDK) — ASC ปฏิเสธ build ที่ใช้ SDK เก่ากว่า |
| **Flutter** | `3.41.6` (channel stable) |
| **Ruby + bundler** | `3.3.x` — ฝั่ง Android ใช้ `RBENV_VERSION=3.3.5` (ดู §5) |
| **CocoaPods** | ติดตั้งผ่าน `bundle` ใน `ios/` |

**iOS signing / upload**
- ASC API key **`M4PPU86374`** · issuer `03750a9c-5c4e-4be1-bb27-546000146161`
- `.p8` อยู่ที่ `~/.appstoreconnect/private_keys/AuthKey_M4PPU86374.p8`
- certs/profiles มาจาก fastlane **match** repo: `github.com/massridedelivery/app-customer-certs` (private)
  - bootstrap ครั้งเดียว (ต่อ bundle id):
    ```bash
    cd ios && bundle exec fastlane match appstore --readonly false            # prod
    cd ios && bundle exec fastlane match appstore \
      --app_identifier com.massdrive.customerApp.develop --readonly false     # dev
    ```

**Android signing / upload**
- keystore + `android/key.properties` (alias **`mass-customer`**) — ไม่อยู่ใน git
- service account JSON: `android/fastlane/play-service-account.json`
  (SA `play-upload@prod-mass-project…`, สิทธิ์ *Release manager* ใน Play Console)
- รายละเอียด setup ครั้งแรก: ดู [`docs/android-play-setup.md`](android-play-setup.md)
- เช็คว่า SA ใช้ได้: `make deploy_play_check`

---

## 3. 🔑 Keys & credentials registry

> ⚠️ **ไม่มีค่า secret จริงในไฟล์นี้** (ไฟล์นี้อยู่ใน git) — เก็บแค่ "ใช้ key ไหน /
> อยู่ที่ไหน / rotate ยังไง". ค่า secret จริงอยู่ใน GitHub repo secrets, keychain,
> และไฟล์ gitignored เท่านั้น.

### App Store (iOS)

| Item | Identifier / location | เป็น secret? |
|---|---|---|
| ASC API key | ID `M4PPU86374` · issuer `03750a9c-5c4e-4be1-bb27-546000146161` | `.p8` = ใช่ |
| `.p8` (local) | `~/.appstoreconnect/private_keys/AuthKey_M4PPU86374.p8` | ✅ |
| Apple Team | `Q7742Z74Q3` (`Apple Distribution: MASS RIDE & DELIVERY`) | — |
| Cert + profiles | match repo `github.com/massridedelivery/app-customer-certs` · profiles `match AppStore com.massdrive.customerApp` / `…​.develop` | repo private + `MATCH_PASSWORD` |
| CI secrets | `MATCH_GIT_URL`, `MATCH_PASSWORD`, `MATCH_GIT_BASIC_AUTHORIZATION`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`, `PROD_ENV_JSON` | ✅ |

### Google Play (Android)

| Item | Identifier / location | เป็น secret? |
|---|---|---|
| Upload keystore (local) | path จาก `android/key.properties` → `storeFile` · alias **`mass-customer`** | ✅ (`.jks` + passwords) |
| `key.properties` | `android/key.properties` (gitignored): storePassword / keyPassword / keyAlias / storeFile | ✅ |
| Play service account | `android/fastlane/play-service-account.json` (gitignored) · email `play-upload@prod-mass-project.iam.gserviceaccount.com` · project `prod-mass-project` · role *Release manager* | ✅ (`private_key` ในไฟล์) |
| CI secrets | `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `PLAY_SERVICE_ACCOUNT_JSON`, `PROD_ENV_JSON` | ✅ |

### Rotate / อัปเดต key

- **ASC API key:** App Store Connect → Users and Access → Integrations → App Store
  Connect API → สร้าง key ใหม่ → วาง `.p8` ที่ `~/.appstoreconnect/private_keys/` แล้ว
  อัปเดต `--apiKey/--apiIssuer` ใน `Makefile` + `ios/fastlane/Fastfile` และ secrets
  `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_P8_BASE64` (`base64 -i AuthKey_XXX.p8 | pbcopy`).
- **match (cert/profile):** `cd ios && bundle exec fastlane match appstore --readonly false`
  (ต่อ bundle id) เพื่อ renew; อัปเดต `MATCH_*` secrets ถ้า repo/รหัสเปลี่ยน.
- **Android keystore:** ⚠️ **ห้ามเปลี่ยน keystore ของแอปที่ release แล้ว** (เว้นแต่เปิด
  Play App Signing). ถ้าเปลี่ยนได้ → อัปเดต `android/key.properties` + secrets
  `KEYSTORE_BASE64` (`base64 -i keystore.jks`) / `KEYSTORE_PASSWORD` / `KEY_PASSWORD` / `KEY_ALIAS`.
- **Play service account:** Google Cloud Console → IAM → service account `play-upload@…`
  → สร้าง JSON key ใหม่ → แทนที่ `android/fastlane/play-service-account.json` + secret
  `PLAY_SERVICE_ACCOUNT_JSON`; และกำหนดสิทธิ์ใน Play Console ด้วย.

> 🔒 **ถ้า secret หลุด:** revoke ทันที (ASC key/Play SA key/PAT), สร้างใหม่, อัปเดตทุกที่
> ด้านบน. keystore หลุด = ร้ายแรงสุด (เซ็นแอปแทนได้) — ต้องพึ่ง Play App Signing ในการกู้.

---

## 4. Versioning (สำคัญมาก)

`pubspec.yaml` → `version: X.Y.Z+BUILD` เป็น single source of truth:

| | มาจาก | สูตร |
|---|---|---|
| iOS `CFBundleShortVersionString` | `X.Y.Z` | marketing version |
| iOS build | `BUILD` | — |
| Android `versionName` | `X.Y.Z` | — |
| Android `versionCode` | `BUILD` | **`2000 + BUILD`** (ดู `android/app/build.gradle.kts`) |

- `make bump` = `+BUILD` **+1** (เรียกอัตโนมัติใน target `deploy_*`)
- ⚠️ **Marketing-version train ปิดหลัง build ถูก approve ขึ้น App Store** →
  build ถัดไปของ **prod app** ต้องขึ้น `X.Y.Z` ให้สูงกว่าเดิม ไม่งั้น altool 409
  *"Invalid Pre-Release Train … is closed"*. วิธีแก้: bump marketing เช่น
  `1.0.1 → 1.0.2` ใน `pubspec.yaml` (ส่วนหน้า `+`) แล้ว **rebuild IPA** (ค่าถูกเบคตอน build).
  — **Google Play ไม่ล็อกแบบนี้** → สโตร์ drift กันได้ (iOS 1.0.2 vs Play 1.0.1 ที่ build เดียวกัน),
  ค่อย realign ตอน upload Play รอบถัดไป.

---

## 5. Local deploy (`make …`)

> ทุก target `deploy_*` จะ `bump` ก่อนเสมอ (ยกเว้น `upload_*` / `promote_*`).
> หลัง deploy จะมี `pubspec.yaml` ค้างใน working tree — ตัดสินใจ commit เองตาม
> [`docs/GIT_WORKFLOW.md`](GIT_WORKFLOW.md).

### 4.1 iOS → TestFlight

| คำสั่ง | ทำอะไร | ขึ้น app ไหน |
|---|---|---|
| **`make deploy_prod_devapi`** ⭐ | bump + build IPA (`prod` flavor, `prod-devapi.json`) + altool upload | **Customer (prod)** |
| `make deploy_dev` | bump + build IPA (`dev` flavor, `dev.json`) + altool upload | MassCustomerDev |
| `make deploy_both_prod` | real prod (`prod.json`): bump ครั้งเดียว → iOS + Android lock-step | Customer (prod) |

ขั้นแยก (ใช้ artifact ที่ build ค้าง): `make ipa_prod_devapi` → `make upload_testflight_prod_devapi`

### 4.2 Android → Google Play (internal track)

ใช้ Ruby 3.3.5 ผ่าน rbenv:

```bash
RBENV_VERSION=3.3.5 make deploy_play_prod_devapi   # ⭐ prod flavor @ dev API → internal
RBENV_VERSION=3.3.5 make deploy_play_dev           # dev flavor → internal
RBENV_VERSION=3.3.5 make deploy_play_prod          # real prod (env/prod.json) → internal
```

promote internal → production (ไม่ re-upload — Google ไม่รับ versionCode ซ้ำ; publish + rollout% ทำต่อใน Console):

```bash
make promote_play_prod VERSION_CODE=2071           # เลข = 2000 + pubspec build
```

### 4.3 ทั้งสองสโตร์พร้อมกัน (build number ล็อกกัน)

```bash
make deploy_both_prod_devapi   # bump ครั้งเดียว → iOS IPA + Android AAB → upload ทั้งคู่
```

---

## 6. CI/CD (GitHub Actions)

| Workflow | Trigger | ผลลัพธ์ |
|---|---|---|
| `ci.yml` | PR / push → `main`,`develop` | format check + `flutter analyze` + tests |
| `deploy-ios.yml` | `workflow_dispatch` **หรือ** tag `release/*` | prod → TestFlight (fastlane `beta`) |
| `deploy-ios-dev.yml` | `workflow_dispatch` **หรือ** tag `dev/*` | dev → TestFlight (fastlane `dev`) |
| `deploy-preprod.yml` | `workflow_dispatch` **หรือ** push → `main`/`master` | prod AAB → Play *Internal testing* |

### 5.1 Tag-driven deploy (ใครก็ปล่อยได้ รวม Windows ที่ไม่มี Xcode)

```bash
git tag release/1.2.3 && git push origin release/1.2.3   # → prod TestFlight
git tag dev/1.2.3     && git push origin dev/1.2.3       # → dev TestFlight
```
- `X.Y.Z` ใน tag → `--build-name` (ถ้า dispatch เฉยๆ จะ fallback เป็น pubspec)
- **build number / versionCode บน CI = `GITHUB_RUN_NUMBER + 10`** (iOS และ Android นับแยกกัน;
  Android สุดท้ายได้ `versionCode = 2000 + run + 10`)

### 5.2 กลไกเซ็น CI
- iOS: `setup_ci` + `match(readonly:true)` (auth เฉพาะ git ผ่าน `MATCH_GIT_BASIC_AUTHORIZATION`,
  **ไม่** ส่ง api_key — กัน spaceship crash บน OpenSSL3) → archive → upload ด้วย **altool**
  (เซ็น ASC JWT native, materialize `.p8` จาก `ASC_KEY_P8_BASE64`)
- Android: build signed AAB (keystore จาก secret) → `r0adkll/upload-google-play`

### 5.3 Secrets ที่ต้องตั้งบน repo

**iOS** (`deploy-ios*.yml`): `MATCH_GIT_URL`, `MATCH_PASSWORD`,
`MATCH_GIT_BASIC_AUTHORIZATION`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`
(+ `PROD_ENV_JSON` สำหรับ prod เพราะ `env/prod.json` ไม่อยู่ใน git)

**Android** (`deploy-preprod.yml`): `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`,
`KEY_PASSWORD`, `KEY_ALIAS`, `PROD_ENV_JSON`, `PLAY_SERVICE_ACCOUNT_JSON`

> `MATCH_GIT_BASIC_AUTHORIZATION` = base64 ของ `user:PAT` (fine-grained PAT,
> Contents\:Read บน certs repo) **ห้ามมี newline ท้าย** (`tr -d '\n'`) ไม่งั้น git auth header พัง → clone 400

---

## 7. Troubleshooting / Gotchas

| อาการ | สาเหตุ | วิธีแก้ |
|---|---|---|
| altool 409 *"train version … is closed"* / `CFBundleShortVersionString must be higher` | marketing version ถูก approve แล้ว (prod) | bump `X.Y.Z` ใน pubspec (§4) แล้ว rebuild IPA |
| altool *"Unsupported Architectures … objective_c.framework contains '[x86_64]'"* (409) | เคย build `--simulator` ใน session เดียวกัน ทำ IPA ปน x86_64 | `flutter clean` + `make gen` + build IPA ใหม่ (arm64-only) |
| ASC *"must be built with the iOS 26 SDK"* | Xcode เก่า | ใช้ Xcode 26+ (CI: `maxim-lobanov/setup-xcode@latest-stable`) |
| Play *"version code already used"* | versionCode ซ้ำ | เพิ่ม `+BUILD` ใน pubspec (→ versionCode = 2000+BUILD) |
| match clone 400 บน CI | `MATCH_GIT_BASIC_AUTHORIZATION` มี newline | สร้าง base64 แบบ `tr -d '\n'` |
| Gradle *"Could not read workspace metadata … metadata.bin"* | cache พังจาก disk เต็ม | `pkill -9 -f GradleDaemon` + `rm -rf ~/.gradle/caches/<ver>` + `android/.gradle` (เก็บ `modules-2`) |
| push notification ไม่เข้า ตอนใช้ `prod-devapi` | เครื่อง register FCM token project **prod** แต่ backend **dev** ส่งผ่าน project dev | คาดไว้แล้ว — ปกติสำหรับ build ชั่วคราวนี้ |
| Play upload timeout ~300s | AAB ใหญ่ | fastlane `deploy` ตั้ง timeout 900s ให้แล้ว (retry ได้) |

---

## 8. นำไปใช้กับแอปอื่น (template checklist)

ของที่ **copy ได้เลยแทบไม่ต้องแก้**: `Makefile` (ชุด target deploy), `ios/fastlane/*`,
`android/fastlane/*`, `.github/workflows/*`, สคีม versioning (`2000 + build`),
และกลไกเซ็น CI (match readonly + altool).

### 8.1 ค่าที่ต้องเปลี่ยนต่อแอป (app-specific)

| ค่า | ที่แก้ | ตัวอย่าง customer-app |
|---|---|---|
| iOS bundle id | `ios/fastlane/Appfile`, `Fastfile` lanes, `Runner.xcodeproj` | `com.massdrive.customerApp` (+`.develop`) |
| Android applicationId | `android/app/build.gradle.kts`, `android/fastlane/Appfile` | `com.massdrive.customer_app` (+`.dev`) |
| env files | `env/dev.json`, `env/prod.json`, `env/prod-devapi.json` | API base URL, Maps key, FLAVOR |
| Apple Team | `ios/fastlane/Fastfile` (`TEAM_ID`), Appfile | `Q7742Z74Q3` (อาจใช้ team เดียวกันได้) |
| ASC app record | สร้างใน App Store Connect | *Customer* / *MassCustomerDev* |
| match profiles | `match AppStore <bundle id>` (bootstrap ต่อ bundle id) | ดู §3 |
| Android keystore | สร้างใหม่ต่อแอป (alias + passwords) | alias `mass-customer` |
| Play app + service account | สร้าง app ใน Play Console + ให้สิทธิ์ SA | pkg `com.massdrive.customer_app` |
| ASC API key / Play SA | **ใช้ซ้ำข้ามแอปได้** ถ้าอยู่ account/org เดียวกัน | key `M4PPU86374`, SA `play-upload@…` |

### 8.2 ขั้นตอน onboard แอปใหม่

1. **Copy โครง:** `Makefile`, `ios/fastlane/`, `android/fastlane/`, `.github/workflows/`
   มาไว้ในแอปใหม่ แล้วแก้ค่าในตาราง §8.1
2. **iOS:**
   - สร้าง app record ใน App Store Connect (ต่อ flavor/bundle id)
   - สร้าง/เพิ่ม bundle id ใน match repo:
     `cd ios && bundle exec fastlane match appstore --app_identifier <bundle id> --readonly false`
   - วาง ASC `.p8` ที่ `~/.appstoreconnect/private_keys/` (ใช้ key เดิมได้ถ้า account เดียวกัน)
3. **Android:**
   - สร้าง keystore ใหม่ (`keytool -genkey … -alias <alias>`) + `android/key.properties`
   - สร้าง app ใน Play Console, ให้สิทธิ์ *Release manager* กับ service account,
     วาง `android/fastlane/play-service-account.json`
   - อัปโหลด **AAB แรกด้วยมือ**ผ่าน Play Console (Google ต้องเห็น package ก่อน fastlane ถึง upload ได้)
4. **ตั้ง repo secrets** (ดูรายการ §6.3) บน repo ของแอปใหม่
5. **ทดสอบ:** `make deploy_play_check` → แล้ว local deploy (§5) ครั้งแรก → ค่อยเปิด tag/CI
6. **ปรับ build-number offset** (`GITHUB_RUN_NUMBER + N`) ใน workflow ให้สูงกว่า versionCode
   สูงสุดที่เคยใช้บน Play ของแอปนั้น (กัน *"version code already used"*)

> 💡 ของที่ควร **gitignore** ทุกแอป: `env/prod.json`, `android/key.properties`,
> keystore (`*.jks`), `android/fastlane/play-service-account.json`, `.p8`.

---

## 9. Cheat sheet

```bash
# ── iOS TestFlight ───────────────────────────────────────────────
make deploy_prod_devapi        # ⭐ ตอนนี้: prod flavor @ dev API → Customer (prod)
make deploy_dev                #    dev flavor → MassCustomerDev
make deploy_both_prod          #    real prod (เมื่อ backend prod ขึ้น)

# ── Android Google Play (internal) ───────────────────────────────
RBENV_VERSION=3.3.5 make deploy_play_prod_devapi    # ⭐ ตอนนี้
RBENV_VERSION=3.3.5 make deploy_play_prod           #    real prod
make promote_play_prod VERSION_CODE=<2000+build>    #    internal → production (draft)
make deploy_play_check                              #    verify service account

# ── ทั้งสองสโตร์พร้อมกัน ──────────────────────────────────────────
make deploy_both_prod_devapi

# ── CI/CD (tag-driven) ───────────────────────────────────────────
git tag release/1.2.3 && git push origin release/1.2.3   # prod → TestFlight
git tag dev/1.2.3     && git push origin dev/1.2.3        # dev  → TestFlight
# Play internal: push main/master หรือ กด Run บน Actions → "Deploy to Google Play"
```

---

### ไฟล์ที่เกี่ยวข้อง
- `Makefile` — targets ทั้งหมด
- `ios/fastlane/Fastfile` — lanes `beta` (prod) / `dev`
- `android/fastlane/Fastfile` — lanes `deploy` / `promote` / `whoami`
- `.github/workflows/` — `ci.yml`, `deploy-ios.yml`, `deploy-ios-dev.yml`, `deploy-preprod.yml`
- `docs/android-play-setup.md` — setup keystore + service account ครั้งแรก
- `docs/GIT_WORKFLOW.md` — นโยบาย branch / commit
