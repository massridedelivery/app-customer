# Push Notifications (FCM)

Firebase project: `mass-ride-delivery` — config มาจากไฟล์ native
(`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`)
ตัวจัดการฝั่งแอปคือ
[PushNotificationService](../lib/core/services/push_notification_service.dart)

## Flow ฝั่งแอป

- ขอ permission + ลงทะเบียน token **หลัง login** (ทุกช่องทาง) และตอนเปิดแอปถ้า
  session ยังอยู่; ฟัง `onTokenRefresh` ด้วย
- Logout → เรียก unregister กับ backend ก่อนเคลียร์ session แล้ว `deleteToken()`
- Foreground: Android โชว์ผ่าน flutter_local_notifications (channel
  `massmove_default`), iOS โชว์เองด้วย presentation options — ข้ามการเด้งถ้า
  ผู้ใช้อยู่บนหน้าที่ตรงกับ deeplink อยู่แล้ว
- กดแจ้งเตือน (ทุกสถานะแอป) → นำทางด้วย `data.deeplink` ผ่าน router เดิม
  (กลไก pending-link ใน [deeplinks.md](deeplinks.md) จัดการ splash/login ให้)
- token ถูก `debugPrint` ตอนลงทะเบียน — ใช้ยิงทดสอบจาก Firebase console ได้

## สัญญา payload (ฝั่ง backend ต้องส่งแบบนี้)

```json
{
  "notification": { "title": "คนขับรับงานแล้ว", "body": "สมชายกำลังไปที่ร้าน" },
  "data": { "deeplink": "/food-order/tracking/ORDER_ID" },
  "android": { "notification": { "channel_id": "massmove_default" } }
}
```

`data.deeplink` = path ที่ match route ใน lib/router/app_routes.dart
(ดูตารางใน [deeplinks.md](deeplinks.md))

## Endpoint ที่ backend ต้องทำ (ยังไม่มีจริง — แอปเรียกแล้ว swallow error)

| Method | Path | Body | ใช้ตอน |
|---|---|---|---|
| POST | `/api/customer/devices` | `{"token": "...", "platform": "android\|ios"}` | login / token refresh (idempotent upsert) |
| DELETE | `/api/customer/devices` | `{"token": "..."}` | logout |

ฝั่ง server ยิงผ่าน FCM HTTP v1 ด้วย service account ของ project
`mass-ride-delivery` และควรลบ token ที่ FCM ตอบ UNREGISTERED ทิ้ง

## งานที่เหลือ

- [ ] Backend: endpoints ด้านบน + trigger ตาม event (driver assigned,
      food order status, chat ตอน user offline, promo broadcast)
- [ ] iOS: APNs Auth Key (.p8) อัปโหลดเข้า Firebase + เปิด Push Notifications
      capability ใน Xcode (ต้องมี Apple Developer แบบเสียเงิน + เครื่อง Mac)
      — ก่อนหน้านั้น push บน iOS ยังไม่เข้า
- [ ] Settings toggle ปิด/เปิดแจ้งเตือนในหน้า profile (มี l10n string แล้ว)

## ทดสอบ (Android ทำได้เลย)

1. รันแอป dev flavor + login → ดู token จาก logcat (`Push: FCM token:`)
2. Firebase console → Messaging → New campaign → Send test message → วาง token
3. เช็คครบ 3 สถานะ: foreground (เด้ง heads-up), background (กดแล้วเข้าหน้า
   deeplink), ปิดแอป (กดแล้วเปิดแอปเข้าหน้า deeplink ผ่าน splash)
