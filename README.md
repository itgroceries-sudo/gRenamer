# 🛡️ gRenam Remover Ultimate
**เครื่องมือกำจัดไวรัส Grenam และกู้คืนไฟล์ต้นฉบับแบบถอนรากถอนโคน** *Developed by IT Groceries Shop™ ♥ ♥ ♥*

[![Follow on YouTube](https://img.shields.io/badge/YouTube-Follow-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/c/itgroceries?sub_confirmation=1)
[![Facebook](https://img.shields.io/badge/Facebook-Follow-blue?style=for-the-badge&logo=facebook)](https://www.facebook.com/Adm1n1straTOE)

---
# #ตำนานที่ยังมีลมหายใน    (ตัวแก้)   #ไวรัสเปลี่ยนชื่อไฟล์ 
<img width="1245" height="749" alt="image" src="https://github.com/user-attachments/assets/33122d86-d1ee-46a2-9a54-2688d45c8a15" />

---

## 🔍 ข้อมูลเบื้องต้น
**Win32/Grenam** หรือ **V-Virus** เป็นไวรัสที่สร้างความรำคาญโดยการสวมรอยไฟล์โปรแกรมหลัก (`.exe`) ของคุณ แล้วเปลี่ยนชื่อไฟล์จริงไปซ่อนไว้ด้วยการเติมตัวอักษร `g` ไว้หน้าชื่อไฟล์ (เช่น `gsetup.exe`) พร้อมตั้งค่า Attributes เป็น System/Hidden/Read-Only

**ปัญหาหลัก:** แม้คุณจะใช้ Antivirus ทั่วไปฆ่าตัวไวรัสตายแล้ว แต่ไฟล์ต้นฉบับของคุณจะยังคงถูกซ่อนและมีชื่อที่ผิดเพี้ยนอยู่ ทำให้ไม่สามารถใช้งานได้ตามปกติ

---

## 🚀 วิธีใช้งานด่วน (One-Line Run)
ไม่ต้องดาวน์โหลดไฟล์ ไม่ต้องติดตั้ง เพียงเปิด PowerShell (Admin) แล้ววางคำสั่งนี้:

```powershell
iex(irm bit.ly/gRemover)
```

## 🛠️ ฟีเจอร์หลักและการใช้งาน

### 1. การใช้งานแบบปกติ (Standard Mode)
เหมาะสำหรับเครื่องหรือ USB ที่เพิ่งติดไวรัส และยังมีไฟล์ไวรัสตัวปลอมอยู่คู่กับไฟล์จริงที่โดนซ่อน

* **Logic:** ค้นหาคู่กรณีระหว่างไฟล์ `gName.exe` (ไฟล์จริงที่โดนซ่อน) และ `Name.exe` (ไฟล์ไวรัส)
* **Action:** ลบไฟล์ไวรัสตัวปลอมทิ้ง -> ปลดล็อก Attributes (S/H/R) ของไฟล์จริง -> Rename กลับเป็นชื่อเดิมให้อัตโนมัติ

### 2. โหมดขั้นสูง (Advance Mode)
**"โหมดกู้คืนไฟล์กำพร้า"** เหมาะสำหรับ USB ที่เคยสแกนไวรัสมาแล้ว แต่ไฟล์จริงยังถูกซ่อนทิ้งไว้

* **Logic:** ค้นหาไฟล์เฉพาะที่ขึ้นต้นด้วย `g` ตัวเล็ก และมีสถานะเป็น **Hidden** เท่านั้น
* **Action:** ปลดล็อกสถานะการซ่อน และ Rename ตัดตัว `g` ออกทันทีโดยไม่ต้องรอตรวจเจอไฟล์ไวรัสคู่กรณี
* **วิธีใช้:** ติ๊กถูกที่ช่อง **"Advance Mode: Recover hidden orphaned files"** ก่อนกดปุ่มสแกน

---

## 📊 บทสรุปจุดเด่นและข้อจำกัด

| หัวข้อ | รายละเอียด |
| :--- | :--- |
| **จุดเด่น (Pros)** | ✅ **Hybrid Script:** รันได้รวดเร็วผ่าน PowerShell พร้อม UI ที่สวยงาม <br> ✅ **Dual-Panel:** แสดงหน้า GUI ควบคู่กับ Console Log แบบ Real-time <br> ✅ **Recursive Scan:** สแกนลึกทุกชั้นโฟลเดอร์แบบไม่จำกัด <br> ✅ **Tahoma Font:** แก้ปัญหาการแสดงผลภาษาไทย (สระ อุ อู) ได้สมบูรณ์ <br> ✅ **Portable:** ไฟล์เดียวจบ ไม่ทิ้งขยะไว้ในเครื่อง |
| **ความโดดเด่น (Unique)** | ⭐ **Refresh System:** ตรวจหาไดรฟ์ USB ใหม่ได้ทันทีโดยไม่ต้องเปิดโปรแกรมใหม่ <br> ⭐ **Strict Selection:** ระบบเลือกเป้าหมายแบบ Toggle Switch ที่ชัดเจนและป้องกันการกดพลาด |
| **ข้อด้อย (Cons)** | ⚠️ รองรับการทำงานเฉพาะบน Windows เท่านั้น <br> ⚠️ ต้องใช้สิทธิ์ Administrator ในการแก้ไขไฟล์ระบบ |

## 📸 ภาพตัวอย่างโปรแกรม

| หน้าจอเริ่มต้น | หน้าจอรายงานผลการสแกน |
| :---: | :---: |
| ![หน้าจอเริ่มต้น](https://github.com/user-attachments/assets/5e1161f9-aa5a-4d43-8829-977f52477394) | ![หน้าจอรายงานผลการสแกน](https://github.com/user-attachments/assets/30b3d6ca-96bc-41ce-bc51-d7e3ae545484) |

---

## 📢 ติดตามผลงาน
หากเครื่องมือนี้ช่วยคุณได้ ฝากกดติดตามเพื่อเป็นกำลังใจในการสร้างสรรค์ Tool ใหม่ๆ แจกฟรีได้ที่:
* **YouTube:** [IT Groceries Shop](https://www.youtube.com/c/itgroceries?sub_confirmation=1)
* **Facebook:** [Adm1n1straTOE](https://www.facebook.com/Adm1n1straTOE)
* **Website:** [itgroceries.blogspot.com](https://itgroceries.blogspot.com)

---
> **Disclaimer:** เครื่องมือนี้แจกฟรีเพื่อสาธารณประโยชน์ ทางผู้พัฒนาไม่รับผิดชอบต่อความเสียหายใดๆ ที่เกิดขึ้นจากการใช้งาน โปรดสำรองข้อมูลสำคัญก่อนสแกนทุกครั้ง
