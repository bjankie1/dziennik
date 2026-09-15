# External Integrations

**Analysis Date:** 2026-09-15
**Project:** EduSync

## 1. Librus Synergia
- **Base Domain:** `https://synergia.librus.pl`
- **Auth Endpoint:** `https://api.librus.pl/OAuth/Authorization?client_id=46`
- **Session Handshake:**
  1. `GET https://synergia.librus.pl/loguj/portalRodzina?v=1774820765`
  2. `POST https://api.librus.pl/OAuth/Authorization?client_id=46` (action: login, login, pass)
  3. `GET https://api.librus.pl/OAuth/Authorization/2FA?client_id=46`
- **Session Cookies:** `DZIENNIKSID`, `SDZIENNIKSID`
- **Scraped Modules:**
  - Student Profile: `https://synergia.librus.pl/informacja`
  - Grades: `https://synergia.librus.pl/przegladaj_oceny/uczen`
  - Schedule/Timetable: `https://synergia.librus.pl/przegladaj_plan_lekcji`
  - Announcements: `https://synergia.librus.pl/ogloszenia`
  - Attendance (Planned): `https://synergia.librus.pl/przegladaj_nb/uczen`
  - Messages (Planned): `https://synergia.librus.pl/wiadomosci/1/5`

## 2. Google Firebase Cloud
- **Project ID:** `lepsza-szkola`
- **Services:**
  - **Firebase Auth:** Google OAuth Provider (`REDACTED_FIREBASE_KEY`)
  - **Cloud Firestore:** Collections `students/{login}`, `students/{login}/notifications`, `users/{userId}`
  - **Firebase Cloud Functions (v2):** Endpoints `syncNow`, `getStudentData`, `saveConnection`, `getConnection`
  - **Google Cloud Scheduler:** `scheduledLibrusSync` (every 30 minutes)
  - **Firebase Hosting:** Domain `https://lepsza-szkola.web.app`

*Codebase analysis: 2026-09-15*
