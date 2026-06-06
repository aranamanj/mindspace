# 🌿 MindSpace — Mental Health Companion

A privacy-first Android mental health companion app built with Flutter and SQLite.
No accounts. No cloud. No tracking. Everything stays on your device.

---

## Features

- 😊 **Mood Tracker** — Log your mood (1–5) with an optional note and view your history
- 📓 **Journal** — Write, edit, and delete private journal entries
- 🌬️ **Breathing** — Guided 4-4-4-4 box breathing exercise with animated circle
- 🔔 **Reminders** — Daily local notifications for mood check-ins and journaling
- 💬 **Affirmations** — A new affirmation every day

---

## Tech Stack

- **Framework** — Flutter 3.x (Dart)
- **Database** — SQLite via `sqflite`
- **Notifications** — `flutter_local_notifications`
- **Platform** — Android (API 21+)

---

## Getting Started

```bash
git clone https://github.com/your-username/mindspace.git
cd mindspace
flutter pub get
flutter run
```

Make sure `minSdk = 21` is set in `android/app/build.gradle.kts`.

---

## Privacy

All data is stored locally on your device. No internet connection, no accounts,
no analytics — ever.

---

## Disclaimer

MindSpace is a personal wellness tool and is not a substitute for professional
mental health care. If you are in crisis, please reach out to a qualified
professional or helpline in your country.