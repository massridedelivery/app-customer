.PHONY: gen watch fix clean clean_cache test test_cov analyze pre_pr run_dev run_prod run_ios_dev run_ios_prod build_apk_dev build_apk_dev_arm64 install_dev build_apk_prod build_ios_dev build_ios_prod build_aab_dev build_aab_prod deploy_play_dev deploy_play_prod deploy_play_check run_prod_devapi build_apk_prod_devapi build_aab_prod_devapi ipa_prod_devapi deploy_prod_devapi deploy_play_prod_devapi

# 📁 โฟลเดอร์เก็บ debug symbols ของ Dart (จาก --obfuscate) — ใช้ de-obfuscate stack trace ทีหลัง
SYMBOLS := build/symbols

# 🚀 สร้างไฟล์ที่จำเป็น (Freezed, Riverpod, JSON)
gen:
	@echo "🚀 Generating code (build_runner)..."
	dart run build_runner build --delete-conflicting-outputs

# 👀 สั่ง Gen โค้ดแบบ Real-time เวลาแก้ไฟล์
watch:
	@echo "👀 Watching for changes..."
	dart run build_runner watch --delete-conflicting-outputs

# 🧹 จัด Format และแก้ Lint เบื้องต้นอัตโนมัติ
fix:
	@echo "🧹 Fixing and formatting code..."
	dart fix --apply
	dart format .

# 🗑️ ล้าง Cache และโหลด Package ใหม่ (เวลาโปรเจกต์เอ๋อๆ)
clean:
	@echo "🗑️ Cleaning project..."
	flutter clean
	flutter pub get

# 💽 เคลียร์ dev cache ที่กินพื้นที่ (เวลาดิสก์เต็ม / No space left on device)
# ลบเฉพาะ cache ที่ระบบสร้างใหม่ได้เอง — ไม่แตะ .pub-cache (จะได้ไม่ต้อง re-download deps ทุก project)
clean_cache:
	@echo "💽 Disk before:"; df -h /System/Volumes/Data | tail -1
	@echo "🗑️  flutter clean (project build/)..."
	-flutter clean
	@echo "🗑️  Xcode DerivedData..."
	-rm -rf ~/Library/Developer/Xcode/DerivedData/*
	@echo "🗑️  unavailable simulators..."
	-xcrun simctl delete unavailable
	@echo "🗑️  CocoaPods + Gradle caches (re-download on next build)..."
	-rm -rf ~/Library/Caches/CocoaPods ~/.gradle/caches
	@echo "✅ Disk after:"; df -h /System/Volumes/Data | tail -1

# 🔍 ตรวจสอบโค้ดว่ามี Error/Warning ตามกฎ Lint หรือไม่
analyze:
	@echo "🔍 Analyzing code..."
	flutter analyze

# 🧪 รัน Unit Test ธรรมดา
test:
	@echo "🧪 Running tests..."
	flutter test

# 📊 รัน Unit Test พร้อมทำรายงาน Coverage (แบบ HTML)
test_cov:
	@echo "📊 Running tests with coverage..."
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html

# ✅ รวมฮิตคำสั่งที่ต้องรัน "ก่อน" จะเปิด Pull Request (PR)
pre_pr: clean gen fix analyze test
	@echo "✅ All checks passed! Ready for PR. 🚀"

# 🏃 รันแอปตาม environment
run_dev:
	flutter run --flavor dev --dart-define-from-file=env/dev.json

run_prod:
	flutter run --flavor prod --dart-define-from-file=env/prod.json

# 🍏 รันแอปบน iOS ตาม environment (ต้องตั้ง scheme dev/prod ใน Xcode ก่อน — ดู ENV_SETUP.md)
run_ios_dev:
	flutter run -d ios --flavor dev --dart-define-from-file=env/dev.json

run_ios_prod:
	flutter run -d ios --flavor prod --dart-define-from-file=env/prod.json

# 📦 build APK ตาม environment (universal — ทุก ABI, ไฟล์ใหญ่)
build_apk_dev:
	flutter build apk --flavor dev --dart-define-from-file=env/dev.json

build_apk_prod:
	flutter build apk --release --flavor prod --dart-define-from-file=env/prod.json

# 📱 build APK dev แบบเล็กสำหรับ sideload/ทดสอบบนเครื่อง — arm64 อย่างเดียว + obfuscate
#    เล็กกว่า build_apk_dev ~3 เท่า (ตัด armeabi-v7a/x86_64 + ตัด Dart debug symbols)
#    ~22MB เทียบกับ universal ~66MB · ออกไฟล์ที่ build/app/outputs/flutter-apk/app-dev-release.apk
build_apk_dev_arm64:
	flutter build apk --release --flavor dev --dart-define-from-file=env/dev.json \
		--target-platform android-arm64 --obfuscate --split-debug-info=$(SYMBOLS)

# 📲 build (arm64) แล้วติดตั้ง + เปิดบนเครื่อง Android ที่ต่ออยู่ (adb)
#    ถ้าต่อหลายเครื่อง ให้ระบุ: make install_dev ANDROID_SERIAL=<serial>
install_dev: build_apk_dev_arm64
	adb install -r build/app/outputs/flutter-apk/app-dev-release.apk
	adb shell monkey -p com.massdrive.customer_app.dev -c android.intent.category.LAUNCHER 1

# 🍏 build iOS ตาม environment
build_ios_dev:
	flutter build ios --flavor dev --dart-define-from-file=env/dev.json

build_ios_prod:
	flutter build ios --release --flavor prod --dart-define-from-file=env/prod.json

# 🔢 bump build number (เลขหลัง + ใน version) +1 — ใช้ก่อน archive ขึ้น TestFlight
bump:
	@perl -i -pe 's/^(version:\s*\d+\.\d+\.\d+\+)(\d+)\s*$$/$$1 . ($$2 + 1) . "\n"/e' pubspec.yaml
	@grep '^version:' pubspec.yaml

# 🍏 build IPA dev พร้อมขึ้น TestFlight (App Store distribution)
ipa_dev:
	flutter build ipa --flavor dev --dart-define-from-file=env/dev.json --export-method app-store

# 🚀 bump + build + upload dev ขึ้น TestFlight ในคำสั่งเดียว (ไม่ต้องเปิด Transporter)
# ใช้ App Store Connect API key M4PPU86374 (.p8 อยู่ใน ~/.appstoreconnect/private_keys/)
deploy_dev: bump ipa_dev
	xcrun altool --upload-app --type ios \
		-f build/ios/ipa/customer_app.ipa \
		--apiKey M4PPU86374 --apiIssuer 03750a9c-5c4e-4be1-bb27-546000146161

# ─── 🤖 Android / Google Play ───────────────────────────────────────────────
# One-time setup (keystore + service account + Play app) is documented in
# docs/android-play-setup.md. AABs are signed with the release keystore only
# when android/key.properties exists.

# 📦 build Android App Bundle (AAB) per flavor — no version bump
#    obfuscate + split symbols: Play จะแตก ABI/ความหนาแน่นให้ต่อเครื่องเองอยู่แล้ว
#    (เล็กสุดสำหรับผู้ใช้) ส่วน --obfuscate ตัด Dart symbols ออกจาก libapp.so
#    เก็บ symbols ไว้ที่ $(SYMBOLS) เผื่อ de-obfuscate crash report ทีหลัง
build_aab_dev:
	flutter build appbundle --flavor dev --dart-define-from-file=env/dev.json \
		--obfuscate --split-debug-info=$(SYMBOLS)

build_aab_prod:
	flutter build appbundle --release --flavor prod --dart-define-from-file=env/prod.json \
		--obfuscate --split-debug-info=$(SYMBOLS)

# ✅ verify the Play service-account JSON authenticates (no upload)
deploy_play_check:
	cd android && bundle exec fastlane whoami

# 🚀 bump + build dev AAB + upload to Google Play internal track
# needs android/key.properties (+keystore) and android/fastlane/play-service-account.json
deploy_play_dev: bump build_aab_dev
	cd android && \
		PLAY_PACKAGE_NAME=com.massdrive.customer_app.dev \
		AAB_PATH="$(CURDIR)/build/app/outputs/bundle/devRelease/app-dev-release.aab" \
		bundle exec fastlane deploy track:internal

# 🚀 bump + build prod AAB + upload to Google Play internal track
# needs env/prod.json (real Maps key) in addition to the signing + service account
deploy_play_prod: bump build_aab_prod
	cd android && \
		PLAY_PACKAGE_NAME=com.massdrive.customer_app \
		AAB_PATH="$(CURDIR)/build/app/outputs/bundle/prodRelease/app-prod-release.aab" \
		bundle exec fastlane deploy track:internal

# ─── ⚠️  ชั่วคราว: prod flavor → dev API ─────────────────────────────────────
# backend prod (driver-api.nutchaphut.dev) ยังไม่ขึ้น (Cloudflare ตอบ 502) ชุดนี้จึง build
# ด้วย flavor prod (applicationId/bundle id จริง ชื่อ "Customer") แต่ชี้ API/WS ไปที่
# dev ผ่าน env/prod-devapi.json — ดู ENV_SETUP.md → "prod ชี้ dev API (ชั่วคราว)"
#
# ข้อจำกัด: push notification จะไม่เข้า — เครื่อง register FCM token ของ Firebase
# project prod แต่ backend dev ส่ง push ผ่าน project dev (register พลาดถูก ignore อยู่แล้ว)
#
# พอ backend prod ขึ้น: เลิกใช้ target ชุดนี้ กลับไปใช้ run_prod / build_aab_prod / deploy_play_prod
# ตามเดิม แล้วลบ block นี้ + env/prod-devapi.json ทิ้ง

run_prod_devapi:
	flutter run --flavor prod --dart-define-from-file=env/prod-devapi.json

build_apk_prod_devapi:
	flutter build apk --release --flavor prod --dart-define-from-file=env/prod-devapi.json

build_aab_prod_devapi:
	flutter build appbundle --release --flavor prod --dart-define-from-file=env/prod-devapi.json \
		--obfuscate --split-debug-info=$(SYMBOLS)

ipa_prod_devapi:
	flutter build ipa --flavor prod --dart-define-from-file=env/prod-devapi.json --export-method app-store

# 🚀 bump + build + upload prod (ชี้ dev API) ขึ้น TestFlight
deploy_prod_devapi: bump ipa_prod_devapi
	xcrun altool --upload-app --type ios \
		-f build/ios/ipa/customer_app.ipa \
		--apiKey M4PPU86374 --apiIssuer 03750a9c-5c4e-4be1-bb27-546000146161

# 🚀 bump + build prod AAB (ชี้ dev API) + upload ขึ้น Google Play internal track
deploy_play_prod_devapi: bump build_aab_prod_devapi
	cd android && \
		PLAY_PACKAGE_NAME=com.massdrive.customer_app \
		AAB_PATH="$(CURDIR)/build/app/outputs/bundle/prodRelease/app-prod-release.aab" \
		bundle exec fastlane deploy track:internal
