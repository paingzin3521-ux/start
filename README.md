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

## Menu Options

| Option | Function |
|--------|----------|
| `[1]` WiFi Setup | Internet check + Gateway IP + Clear lists |
| `[2]` MAC Scan | Portal URL → ADB connect → Scan network |
| `[3]` Active Check | Test each MAC against portal → find active sessions |
| `[4]` Select Target | Pick target MAC from active list |
| `[5]` AES Encrypt | AES-CBC encrypt tool |
| `[6]` Encode Session URL | Base64 encode portal URL |
| `[7]` Auto Bypass | Bypass all active MACs until success |

---

## Flow

```
[1] WiFi Setup
    ↓
[2] MAC Scan  (enter Portal URL first)
    ↓
[3] Active Check
    ↓
[4] Select Target
    ↓
[7] Auto Bypass  ← tries all active MACs automatically
```
