# 🗺️ MASS Customer App - Frontend Integration Roadmap

เอกสารฉบับนี้สรุปรายการฟีเจอร์ทั้งหมดของแอปพลิเคชัน **MASS Customer App** (ฝั่งลูกค้า) แยกตามหมวดหมู่ (Features Deep Dive) พร้อมระบุรายละเอียด API ที่เชื่อมต่อ รวมถึงการทำงานเบื้องหลังของระบบ เพื่อใช้เป็นคู่มืออ้างอิงในการพัฒนาและนำเสนอสรุปแก่ทีมงาน

---

## 📊 สรุปความคืบหน้าภาพรวม (Overall Progress)

```text
🔴 การยืนยันตัวตนและการลงทะเบียน (Auth & Onboarding) ─── 100% [เสร็จสมบูรณ์]
🟢 ค้นหาและระบุตำแหน่งผู้ใช้ (Home & Location) ───────── 100% [เสร็จสมบูรณ์]
🚕 การเรียกรถและจองการเดินทาง (Ride Booking) ────────── 100% [เสร็จสมบูรณ์]
⚡ ติดตามการเดินทางแบบ Real-time (Live Ride Tracker) ─── 100% [เสร็จสมบูรณ์]
🍔 ค้นหาและสั่งอาหาร (Food Ordering & Delivery) ───────  95% [เสร็จสมบูรณ์ - API บางส่วนเป็น Mock]
🗺️ ประวัติการเดินทางและรายการย้อนหลัง (Trips History) ─── 100% [เสร็จสมบูรณ์]
👤 หน้าโปรไฟล์และการตั้งค่า (Profile & Settings) ───────  90% [เสร็จสมบูรณ์ - API บางส่วนเป็น Mock]
💳 ระบบการชำระเงินและบัตร (Payments) ────────────────── 100% [เสร็จสมบูรณ์]
```

---

## 📋 ตารางสรุปฟีเจอร์เบื้องต้น (High-Level Overview)

| หมวดหมู่ | หน้าจอ / ฟีเจอร์ | การผูก State | การต่อ API | สถานะ |
| :--- | :--- | :---: | :---: | :---: |
| **1. Auth** | Splash, OTP, Login, Register | `AuthController` | ✅ Real | 🟢 Complete |
| **2. Home** | Service Selection, Set Location | `HomeController` | ✅ Real | 🟢 Complete |
| **3. Ride** | Place Search, Estimate, Booking | `BookingController` | ✅ Real | 🟢 Complete |
| **4. Live Tracker**| Live Map, Driver Chat, Rating | `LiveRideController`| ✅ Real WS | 🟢 Complete |
| **5. Food** | Restaurant, Checkout, Live Food | Local/Search State | 🧪 Mock/Real | 🟢 Complete |
| **6. Trips** | History, Detail | `TripsController` | ✅ Real | 🟢 Complete |
| **7. Profile** | Settings, Loyalty, SOS, PDPA | `profileProvider` | 🔄 Real+Mock| 🟢 Complete |
| **8. Payments** | Add Card (Omise Integration) | Local State | ✅ Real | 🟢 Complete |

---

## 🔍 รายละเอียดเจาะลึกฟีเจอร์ และการต่อ API (Feature Deep Dive)

### 🛡️ 1. การยืนยันตัวตนและการลงทะเบียน (Auth & Onboarding)
ดูแลกระบวนการเข้าสู่ระบบความปลอดภัย และการเช็คสถานะของผู้ใช้ก่อนเริ่มใช้งาน

*   **Splash Screen (หน้าเริ่มแอป)**
    *   **การทำงาน:** ตรวจสอบ Secure Token ในเครื่อง หากมีโทเค็น จะเรียก API เช็คสถานะงานค้างอัตโนมัติ เพื่อกู้คืนหน้าจอที่ใช้งานล่าสุด
    *   **API Endpoint:** `GET /api/customer/jobs/active` (ตรวจสอบว่าลูกค้ามี Ride ที่กำลังดำเนินการอยู่หรือไม่)
*   **Phone Login & OTP Flow**
    *   **การทำงาน:** กรอกเบอร์โทรศัพท์ เพื่อรับและยืนยันรหัสผ่าน OTP แบบใช้ครั้งเดียว
    *   **API Endpoint:**
        *   `POST /auth/otp/send`: ส่งข้อมูลเบอร์โทรและ Device ID เพื่อขอ OTP
        *   `POST /auth/otp/verify`: ส่งรหัส OTP + `ref_id` เพื่อรับ Access Token กลับมา
*   **Email Login & Register**
    *   **การทำงาน:** รองรับการกรอกอีเมลและรหัสผ่านแบบดั้งเดิม
    *   **API Endpoint:**
        *   `POST /auth/login`: เข้าสู่ระบบด้วยอีเมล
        *   `POST /auth/register`: ลงทะเบียนบัญชีใหม่
*   **Forgot Password Flow**
    *   **สถานะ:** 🧪 Mock API (ฝั่งไคลเอนต์รองรับ State UI พร้อมแล้ว รอเปลี่ยน Endpoint จริง)
    *   **โครงสร้าง API:** `/auth/forgot-password` (ขอรีเซ็ต) และ `/auth/forgot-password/reset`

---

### 📍 2. หน้าจอหลักและบริการแผนที่ (Home & Location)
จุดศูนย์กลางของการเลือกใช้บริการและการระบุพิกัดเบื้องต้น

*   **Home Screen (Landing)**
    *   **การทำงาน:** โหลด UI สไตล์พรีเมียม แสดงแผนที่รอบตัว ดึงตำแหน่งปัจจุบัน (User GPS) ผ่านแพ็กเกจ `location` เพื่อใช้เป็นข้อมูลตั้งต้น
    *   **API Endpoint:** `GET /api/customer/jobs/active` (เช็คงานค้างหน้า Home หากมีระบบจะ Redirect ไปยัง Live Tracker อัตโนมัติ)
*   **Service Selection**
    *   **การทำงาน:** แสดงเมนูแบบ Grid ในการเลือก "Ride" หรือ "Food" และส่งข้อมูลผ่าน Navigation
*   **Location Pin Snap**
    *   **การทำงาน:** ตรวจสอบว่าหมุดที่ผู้ใช้วางอยู่นั้น ตรงกับจุดจอดหรือ Venue หลักของระบบหรือไม่ เพื่อระบุตำแหน่งรับที่ชัดเจน
    *   **API Endpoint:** `GET /api/customer/pin-snap` (รับ lat, lng เพื่อตรึงหมุดให้อัตโนมัติ)

---

### 🚕 3. การเรียกรถและการจอง (Ride Booking)
กระบวนการค้นหาตำแหน่ง คำนวณราคา และส่งคำขอหาคนขับ

*   **Place Search Screen**
    *   **การทำงาน:** ค้นหาสถานที่ปลายทางด้วยคีย์เวิร์ด รองรับ Autocomplete แสดงผลระยะทางเบื้องต้น
    *   **API Endpoint:** `GET /api/geospatial/place-search` (ค้นหาพิกัดด้วย text query)
*   **Booking Screen & Fare Estimate**
    *   **การทำงาน:** แสดงตัวเลือกรถหลายประเภท (Motorcycle, Car, SUV) พร้อมประเมินระยะทาง เวลา และยอดรวมตามพื้นที่จริง
    *   **API Endpoint:** `POST /api/customer/jobs/estimate`
        *   *Payload:* Pickup/Dropoff coordinates
        *   *Response:* รายการราคาแยกตามประเภทรถ, ข้อมูล Surge Pricing (ถ้ามี), Encoded Polyline สำหรับลากเส้นบนแผนที่
*   **Promo Code Verification**
    *   **การทำงาน:** ตรวจสอบโค้ดคูปองส่วนลด ยืนยันความถูกต้องก่อนนำมาหักลบราคา
    *   **API Endpoint:** `GET /api/customer/promo/validate` (ส่ง Code + ยอดเงิน เพื่อคำนวณส่วนลด)
*   **Dispatching Ride (จองรถ)**
    *   **การทำงาน:** สร้างงานส่งเข้าสู่ระบบ เพื่อกระจายหาคนขับที่อยู่บริเวณรอบข้าง
    *   **API Endpoint:** `POST /api/customer/jobs`
        *   *Payload:* coordinates, address, vehicle_type_id, payment_method, promo_code

---

### ⚡ 4. ระบบติดตามสด (Live Ride Tracker)
การติดตามการเดินทางแบบ Real-time ผ่าน WebSocket และปฏิสัมพันธ์กับคนขับ

*   **Live Map & Job Status**
    *   **การทำงาน:** อัปเดตตำแหน่งคนขับ และสถานะของงาน (เช่น ACCEPTED, ARRIVED, PICKED_UP) บนแผนที่ทันทีโดยไม่ต้องโหลดหน้าใหม่
    *   **WebSocket Connection:** `ws://<host>/ws?token=<access_token>`
    *   **WebSocket Events:**
        *   `job_accepted`: เมื่อมีคนขับรับงาน
        *   `driver_location`: รับพิกัด (lat, lng) ของคนขับสดๆ
        *   `job_status`: รับการอัปเดตสถานะ (เช่น คนขับมาถึงแล้ว/รับลูกค้าขึ้นรถแล้ว)
*   **Driver Chat (แชทคุยกับคนขับ)**
    *   **การทำงาน:** สื่อสารกับคนขับผ่านข้อความแชทแบบเรียลไทม์
    *   **API/WS:**
        *   `GET /api/customer/jobs/:id/chat`: ดึงประวัติแชทย้อนหลัง
        *   `ws event [chat_message]`: รับและส่งข้อความสดๆ
*   **Rating Screen (รีวิวและการให้คะแนน)**
    *   **การทำงาน:** เมื่อจบการเดินทาง จะแสดงหน้าต่างเพื่อให้คะแนนคนขับและส่งฟีดแบค
    *   **API Endpoint:** `POST /api/customer/jobs/:id/rate` (ส่ง rating [1-5ดาว] และ text comment)

---

### 🍔 5. การค้นหาและสั่งอาหาร (Food Ordering)
ระบบการสั่งอาหารแบบครบวงจร

*   **Food Discovery (หน้ารวมร้านอาหาร/โปรโมชั่น)**
    *   **สถานะปัจจุบัน:** 🧪 Mock API (ผ่าน `mockFoodApiProvider`)
    *   **ฟังก์ชันที่มี:** เลื่อนดูแบนเนอร์โปรโมชั่น, หมวดหมู่อาหาร, ค้นหาชื่อร้านหรือเมนู
    *   **การทำงาน:** ดึงรายชื่อร้านค้า ระยะทาง ค่าส่ง และคะแนนรีวิวของร้าน
*   **Restaurant Detail & Add to Cart**
    *   **การทำงาน:** แสดงรายการเมนูอาหารแยกตามหมวดหมู่ รองรับการเลือกออฟชันเสริม (Add-ons) และสรุปรายการลงตะกร้าสินค้า
*   **Checkout Screen (สรุปสั่งซื้อ)**
    *   **การทำงาน:** รวมราคาค่าอาหาร ค่าจัดส่ง การประยุกต์ใช้คูปอง และการบันทึกโน้ตถึงร้านค้า
    *   **API Endpoint หลัก:** `POST /api/customer/orders` (ส่งรายการอาหาร พิกัดส่ง และข้อมูลการชำระเงินเข้าเซิร์ฟเวอร์)
*   **Live Food Tracking & Interaction**
    *   **การทำงาน:** อัปเดตความคืบหน้าตั้งแต่อาหารกำลังทำ จนกระทั่งไรเดอร์ออกเดินทางส่งสินค้า
    *   **API/WS Integration:**
        *   `GET /api/customer/orders/:id/chat`: แชทคุยกับไรเดอร์ส่งอาหาร
        *   `POST /api/customer/orders/:id/review`: ให้คะแนนและรีวิวหลังได้รับอาหาร
        *   `WebSocket`: ติดตามสถานะคำสั่งซื้อแบบสด ๆ

---

### 🗺️ 6. ประวัติการใช้งาน (Trips History)
ดูประวัติย้อนหลัง ทั้งรายละเอียดเวลา ราคา และข้อมูลคนขับ

*   **Trip History List**
    *   **การทำงาน:** ดึงข้อมูลรายการเดินทางทั้งหมดเรียงตามเวลา (Pagination supported)
    *   **API Endpoint:** `GET /api/customer/trips`
*   **Trip Detail Screen**
    *   **การทำงาน:** ดูรายละเอียดลึกซึ้งของเที่ยวที่ผ่านมา เช่น แผนที่เส้นทาง, ข้อมูลการชำระเงิน, ค่าโดยสาร, และสรุปส่วนลด

---

### 👤 7. โปรไฟล์ การตั้งค่า และความปลอดภัย (Profile & Utils)
ส่วนกลางของผู้ใช้งาน และการดูแลความปลอดภัยของข้อมูล

*   **Profile Management**
    *   **API Endpoint:**
        *   `GET /api/customer/profile`: ดึงข้อมูลชื่อ อีเมล เบอร์โทร สถิติของผู้ใช้
        *   `PUT /api/customer/profile`: อัปเดตข้อมูลส่วนบุคคล
*   **Saved Places (สถานที่โปรด)**
    *   **การทำงาน:** บันทึกที่อยู่เช่น บ้าน, ที่ทำงาน, หรือห้างสรรพสินค้าเพื่อการเรียกครั้งต่อไปได้รวดเร็ว
    *   **API Endpoint:**
        *   `GET /api/customer/places`: ดึงรายชื่อสถานที่ที่บันทึกไว้
        *   `POST /api/customer/places`: บันทึกสถานที่ใหม่พร้อมระบุ Tag/Name
        *   `DELETE /api/customer/places/:id`: ลบสถานที่ออกจากรายการ
*   **MASS Rewards (Loyalty & Referral)**
    *   **การทำงาน:** สะสมคะแนนจากการเดินทาง ตรวจสอบยอดเงินคืน และแบ่งปันรหัสแนะนำเพื่อน
    *   **API Endpoint:**
        *   `GET /api/customer/loyalty/summary`: สรุปแต้มสะสมและระดับสมาชิก
        *   `POST /api/customer/loyalty/points/redeem`: แลกคะแนนสะสมเป็นคูปองส่วนลด
        *   `GET /api/customer/loyalty/referral`: ดูรหัสแนะนำของคุณเพื่อส่งให้ผู้อื่น
*   **Emergency Support (SOS)**
    *   **การทำงาน:** ส่งสัญญาณขอความช่วยเหลือด่วน พร้อมพิกัดปัจจุบันไปยัง Call Center ของระบบทันทีเมื่อเกิดเหตุไม่คาดฝัน
    *   **API Endpoint:** `POST /api/customer/sos`
*   **Privacy & Data Control (PDPA)**
    *   **การทำงาน:** การยอมรับข้อตกลงนโยบาย, การดาวน์โหลดข้อมูลส่วนบุคคล และการลบบัญชี
    *   **API Endpoint:**
        *   `POST /api/customer/consent`: บันทึกการตอบรับนโยบายข้อมูล
        *   `GET /api/customer/export`: ส่งออกข้อมูลใช้งานของผู้ใช้
        *   `DELETE /api/customer/account`: ร้องขอการยกเลิกและลบบัญชีออกจากระบบ

---

### 💳 8. ระบบการชำระเงิน (Payments)
การจัดการบัตรและช่องทางการชำระเงิน

*   **Add Card (Omise SDK Integration)**
    *   **การทำงาน:** รับข้อมูลบัตรเครดิต/เดบิตจากผู้ใช้ ผ่าน Omise Flutter SDK เพื่อสร้าง Secure Token และนำโทเค็นนั้นส่งมาบันทึกที่เซิร์ฟเวอร์หลัก
    *   **API Endpoint:** `POST /api/payment/card` (บันทึก Token จากการ Tokenization เพื่อใช้ตัดเงินในการใช้งานครั้งต่อไป)

---

## 🛠️ ข้อมูลทางเทคนิคของระบบ (System Architecture Highlights)

1.  **Networking (Dio Service)**: ติดตั้ง Global Interceptor เพื่อแนบ Header Authorization: Bearer JWT โดยอัตโนมัติ และมีกลไก Handle 401 ในการ Refresh Token เบื้องหลัง
2.  **Real-time Layer (WebSocketService)**: รักษาการเชื่อมต่อตลอดเวลา มีการสตรีมรับ-ส่งข้อมูล JSON ทันที พร้อมกลไก Auto-Reconnect หากอินเทอร์เน็ตหลุด
3.  **State Management (Riverpod)**: แยก Logic และ UI ชัดเจน ข้อมูลทุกอย่าง Sync ข้าม Widget โดยอาศัย Controller ที่เป็น Single Source of Truth

---
*จัดทำโดย AI coding assistant เพื่อการนำเสนอภาพรวมและส่งต่อให้ทีมพัฒนาต่อไป*
