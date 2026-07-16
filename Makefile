.PHONY: gen watch fix clean clean_cache test test_cov analyze pre_pr run_dev run_prod run_ios_dev run_ios_prod build_apk_dev build_apk_prod build_ios_dev build_ios_prod

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

# 📦 build APK ตาม environment
build_apk_dev:
	flutter build apk --flavor dev --dart-define-from-file=env/dev.json

build_apk_prod:
	flutter build apk --release --flavor prod --dart-define-from-file=env/prod.json

# 🍏 build iOS ตาม environment
build_ios_dev:
	flutter build ios --flavor dev --dart-define-from-file=env/dev.json

build_ios_prod:
	flutter build ios --release --flavor prod --dart-define-from-file=env/prod.json