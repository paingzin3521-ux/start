# SKYBY — WiFi Scan Bypass Tool

```
   _____   _  __ __     __   ____   __     __
  / ____| | |/ / \ \   / /  |  _ \  \ \   / /
 | (___   | ' /   \ \_/ /   | |_) |  \ \_/ /
  \___ \  |  <     \   /    |  _ <    \   /
  ____) | | . \     | |     | |_) |    | |
 |_____/  |_|\_\    |_|     |____/     |_|
```

**Telegram:** [@paing_3521](https://t.me/paing_3521)

---

## ติดตั้ง / Install

```bash
cd $HOME
rm -rf start
git clone https://github.com/paingzin3521-ux/start
cd start
bash build.sh
bash install.sh
```

---

## အသုံးပြုနည်း / Run

```bash
star
```

---

## Update

```bash
cd $HOME
rm -rf start
git clone https://github.com/paingzin3521-ux/start
cd start
bash build.sh
bash install.sh
```

---

## အသုံးပြုနည်း / How to Use

အောက်ပါ command ကို တစ်ကြောင်းတည်း copy ကူးပြီး Termux မှာ paste လုပ်လိုက်ရုံနဲ့ အသင့်အသုံးပြုနိုင်မှာ ဖြစ်ပါတယ်။

```bash
cd $HOME && rm -rf start && git clone https://github.com/paingzin3521-ux/start && cd start && bash install.sh && star
```

တစ်ကြိမ် install ပြီးသွားရင် နောက်ပိုင်းမှာ `star` လို့ ရိုက်ရုံနဲ့ tool ကို တန်းဖွင့်နိုင်ပါပြီ။

---

## Menu Options

| Option | Function |
|--------|----------|
| `[1]` WiFi Setup | Display Router IP & WiFi Name + Clear lists + Save WiFi info for ADB persistence |
| `[2]` MAC Scan | Portal URL → ADB connect → Scan network |
| `[3]` Active Check | Test each MAC against portal → find active sessions |
| `[4]` Select Target | Pick target MAC from active list |
| `[7]` Auto Bypass | Bypass all active MACs until success |

---

## Flow

```
[1] WiFi Setup (Displays Router IP & WiFi Name, saves WiFi info)
    ↓
[2] MAC Scan (enter Portal URL, ADB auto-connects if WiFi is same)
    ↓
[3] Active Check
    ↓
[4] Select Target
    ↓
[7] Auto Bypass (uses saved ADB connection if WiFi is same)
```
