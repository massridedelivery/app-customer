# Deeplinks

รูปแบบลิงก์ (custom scheme): `massmove://app/<route>`

ส่วน path ของลิงก์ต้องตรงกับ route ใน [lib/router/app_routes.dart](../lib/router/app_routes.dart)
เช่น `massmove://app/promos/123` → เปิดหน้ารายละเอียดโปรโมชัน id `123`

## Route ที่ใช้เป็นเป้า deeplink ได้

| ลิงก์ | หน้า |
|---|---|
| `/main?tab=N` | หน้าหลัก เลือกแท็บ (`N` = index) |
| `/main?tab=2&status=ongoing` | แท็บประวัติ กรองตามสถานะ (`ongoing`/`completed`/`canceled`) |
| `/promos` | รายการโปรโมชัน |
| `/promos/:id` | รายละเอียดโปรโมชัน (back กลับไปหน้ารายการ) |
| `/restaurant/:id` | หน้าร้านอาหาร |
| `/category-list?categoryId=X&title=Y` | รายการร้านตามหมวด |
| `/food-delivery` | หน้าสั่งอาหาร |
| `/food-order/tracking/:id` | ติดตามออเดอร์อาหาร |
| `/trip/:id?type=X` | รายละเอียดประวัติการเดินทาง/ออเดอร์ |
| `/referral` | ชวนเพื่อน |

## พฤติกรรมของ router ต่อ deeplink

- ลิงก์ที่เข้ามาก่อนแอปพร้อม (ยังไม่ผ่าน splash หรือยังไม่ login) จะถูกเก็บไว้ใน
  `RouterNotifier.pendingDeepLink` แล้วพาไปต่ออัตโนมัติหลังผ่าน splash/login/onboarding แล้ว
- ถ้ามี active job อยู่ กติกา recovery เดิมชนะ: ลิงก์ที่ไม่อยู่ใน whitelist
  (`/live`, `/rating`, `/chat`, `/food-order`, `/messenger`) จะถูกพาไป `/live/:jobId` แทน
- ลิงก์ผิดรูปแบบ/ไม่รู้จัก จะตกไปหน้า `/main` (ผ่าน `onException`)
- ผลข้างเคียงที่ตั้งใจ: การ resume แอปตอนนี้จะกลับไปหน้าเดิมที่ผู้ใช้ค้างไว้
  (เดิมโดนพากลับ `/main` ทุกครั้ง)

## วิธีทดสอบ

Android (emulator/เครื่องจริง — dev flavor ใช้ package `.dev`):

```sh
adb shell am start -a android.intent.action.VIEW \
  -d "massmove://app/promos/123" com.massdrive.customer_app.dev
```

iOS simulator:

```sh
xcrun simctl openurl booted "massmove://app/promos/123"
```

เคสที่ควรเทสให้ครบ: cold start / แอปอยู่ background / ยังไม่ login (ต้องพาไปต่อหลัง login) /
มี active ride ค้างอยู่

## งานที่เหลือสำหรับ https links (ต้องรอ backend)

1. ตกลง domain เช่น `link.massmove.app`
2. Android App Links: เปิด intent-filter ที่ comment ไว้ใน
   [AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) และให้ backend วาง
   `https://<domain>/.well-known/assetlinks.json` ใส่ SHA-256 ของ release signing key
   ทั้ง `com.massdrive.customer_app` และ `com.massdrive.customer_app.dev`
   (ตอนนี้ release ยังเซ็นด้วย debug key — ต้องทำ signing config จริงก่อน)
3. iOS Universal Links: เพิ่ม Associated Domains (`applinks:<domain>`) ใน Xcode
   (สร้าง Runner.entitlements) และให้ backend วาง
   `https://<domain>/.well-known/apple-app-site-association` (ต้องใช้ Apple Team ID)
