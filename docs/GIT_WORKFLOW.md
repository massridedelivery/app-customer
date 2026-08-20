# Git Workflow Standard — Mass Move (ใช้เหมือนกันทั้ง Customer / Driver / Merchant)

เป้าหมาย: ทำงานหลายคนไม่ชนกัน, ประวัติเส้นตรงอ่านง่าย, ของเสียไม่หลุดเข้า develop/main
กติกาหลัก: **ทุกงานแยก branch → rebase → PR → review + CI → merge** · **ห้าม push ตรง develop/main**

---

## 1) โครง branch
- `main` = production (ปล่อยจริง) — แตะโดยคนที่ได้รับมอบหมายเท่านั้น
- `develop` = integration (งานที่ผ่านรีวิวแล้วมารวมกัน)
- `feature branch` = แยกต่อ 1 งาน จาก `develop`

**ห้าม commit/push ตรงเข้า `develop` หรือ `main`** — ทุกอย่างผ่าน PR

## 2) ตั้งชื่อ branch
```
feat/<สั้นๆ>     ฟีเจอร์ใหม่        เช่น feat/messenger-eta
fix/<สั้นๆ>      แก้บั๊ก            เช่น fix/map-zoom
chore/<สั้นๆ>    งานทั่วไป/config   เช่น chore/bump-1.0.2
docs/<สั้นๆ>     เอกสาร
```

## 3) Flow ต่อ 1 งาน
```bash
# เริ่มงาน — อัปเดต develop ให้ล่าสุดก่อน (rebase เสมอ ไม่ merge)
git checkout develop && git pull --rebase origin develop
git checkout -b feat/<ชื่องาน>

# ...ทำงาน + commit บน branch ตัวเอง...

# ก่อนเปิด PR — rebase ให้ทัน develop (แก้ conflict ที่ branch ตัวเอง)
git fetch origin
git rebase origin/develop
git push -u origin feat/<ชื่องาน>       # ครั้งแรก; หลัง rebase ใช้ push --force-with-lease
```
> **กฎเหล็ก: rebase ก่อนทุกครั้ง ห้าม `git merge` โดยไม่ rebase ก่อน**
> หลัง rebase แล้ว push ใช้ `git push --force-with-lease` (ปลอดภัยกว่า --force)

## 4) เปิด Pull Request
- base = `develop`, compare = branch ตัวเอง
- ใส่คำอธิบาย: ทำอะไร / ทำไม / เทสต์ยังไง (แนบ screenshot ถ้าเป็น UI)
- ต้องได้ **review อย่างน้อย 1 คน** + **CI เขียว** ก่อน merge
- ผูก issue/Jira ที่เกี่ยว (เช่น "closes SCRUM-xx")

## 5) Merge strategy (เลือกอย่างเดียวให้เหมือนกันทั้งทีม)
- **Rebase and merge** → ทุก commit เข้า develop แบบเส้นตรง (แนะนำ ถ้า commit สะอาด)
- หรือ **Squash and merge** → 1 PR = 1 commit (สะอาดสุด อ่าน history ง่าย)
- **ปิด "Create a merge commit"** (ไม่เอา merge commit → ประวัติไม่แตกเป็นกิ่ง)

## 6) Branch protection (ตั้งใน GitHub → Settings → Branches) — ทำทั้ง `develop` และ `main`
- [x] Require a pull request before merging (review ≥ 1)
- [x] Require status checks to pass (CI) before merging
- [x] Require branches to be up to date before merging (บังคับ rebase ให้ทัน)
- [x] Do not allow bypassing the above
- [x] Restrict who can push (`main` = จำกัดเฉพาะผู้ดูแล)
- [x] (แนะนำ) Require linear history

## 7) เข้า `main` (ปล่อย production)
- เปิด PR จาก `develop` → `main`, **rebase ก่อน**, ให้คนดูแล merge เอง (ไม่ auto)
- ตัดผ่าน PR เท่านั้น + tag version (เช่น `v1.0.2`)

## ⚠️ Release / TestFlight — สั่งโดยเจ้าของงานเท่านั้น
- **ห้าม build / upload TestFlight (หรือ App Store / Play) เองเด็ดขาด** — build จะถูก
  **สั่งโดยผู้ดูแลเท่านั้น** (เช่น "build TestFlight +NN")
- ห้าม auto-deploy หลัง merge/PR · CI build เพื่อ "ตรวจ" ได้ แต่ไม่ปล่อยขึ้นสโตร์เอง
- คน/agent ที่ทำฟีเจอร์: เสร็จแล้วแค่รายงาน + รอคำสั่ง build — ไม่ริเริ่มเอง
- (ทดสอบบนเครื่อง local เช่น `make install_dev` ทำได้; ที่ห้ามคือ upload ขึ้นสโตร์)

## 8) Commit message
```
<type>(<scope>): <สรุปสั้น>

<รายละเอียด/เหตุผล ถ้าจำเป็น>
```
type: `feat` `fix` `chore` `docs` `refactor` `test` · เช่น `fix(ride): re-fit map on dropoff change`

## 9) อย่าเอาเข้า commit (stage เฉพาะไฟล์ที่ตั้งใจ — ห้าม `git add -A/.`)
- ไฟล์ generated: `*.g.dart`, `*.freezed.dart` (ถ้า gitignore อยู่แล้ว)
- lockfiles ที่ไม่เกี่ยวกับงาน: `Podfile.lock`, บางที `pubspec.lock`
- config เครื่อง/เครดิเชียล: `env/*`, `ios/Flutter/Generated.xcconfig`, `key.properties`, keystore
- generated plugin registrants (linux/macos/windows)

## Checklist ก่อนเปิด PR
- [ ] แยก branch จาก develop (ไม่ทำบน develop ตรงๆ)
- [ ] `flutter analyze` สะอาด + test ผ่าน
- [ ] rebase onto origin/develop แล้ว (ไม่มี conflict)
- [ ] stage เฉพาะไฟล์ที่ตั้งใจ (ไม่มี config/generated หลุด)
- [ ] PR มีคำอธิบาย + ผูก Jira + (UI) แนบรูป

---
**สรุปสั้น:** branch ต่องาน → rebase → PR → review+CI → **rebase/squash merge** · develop/main ล็อกด้วย branch protection · rebase ก่อน merge ทุกครั้งเสมอ
