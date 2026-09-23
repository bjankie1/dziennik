# Quick Task 260923-osk Plan: Naprawa braku planu lekcji na koncie Oskara

## Goal
Gdy Oskar loguje się na swoje konto (`role = student`, np. `oskizobory@gmail.com` lub `11010033u`), aplikacja musi zawsze pobierać zsynchronizowane dane szkolne (w tym `timetable` – plan lekcji na dziś i cały tydzień, sprawdziany, oceny, frekwencję i wiadomości) z głównego dokumentu ucznia `students/11010033` (Single Source of Truth `primaryLogin`), nawet jeśli w lokalnym `SharedPreferences` brakowało dotąd zapisanego `app_user_primary_login`.

## Root Cause
1. W `LibrusConnectionService.connectWithCredentials()` dla `role == UserRole.student` zmienna `resolvedPrimaryLogin` przyjmowała wartość `null` (`primaryLogin ?? (role.isParent ? login : null)`), co usuwało `app_user_primary_login` z `SharedPreferences`.
2. W `FirestoreSchoolRepository._getStudentData()` brak `app_user_primary_login` powodował wysłanie zapytania `/api/studentData?login=oskizobory@gmail.com&role=student` (bez `primaryLogin`).
3. W `functions/index.js` (`getStudentData`) dla `role === "student"` bez parametru `primaryLogin` funkcja szukała dokumentu `students/oskizobory@gmail.com` zamiast `students/11010033` (`process.env.LIBRUS_LOGIN`) i zwracała `404`.
4. W konsekwencji `FirestoreSchoolRepository._getStudentData()` wpadało w awaryjny fallback (linie 159–210), który nie posiadał klucza `timetable`, przez co `getTodaySchedule()` i `getWeekSchedule()` zwracały pustą listę `[]`.

## Tasks
1. **`lib/data/services/librus_connection_service.dart`**:
   - W `connectWithCredentials` dla konta ucznia (`role.isStudent`) automatycznie wyznaczać `resolvedPrimaryLogin` (usuwając końcowe `u` z loginu Librus lub używając domyślnego `11010033`, a także odczytując `primaryLogin` zwrócony przez `/api/saveConnection`).
   - W `getSavedAppUser()` dla `role.isStudent` gwarantować niepusty `primaryLogin` (fallback do `11010033`).
2. **`lib/data/repositories/firestore_school_repository.dart`**:
   - W `_getTargetStudentDocLogin()` oraz `_getStudentData()` rozwiązywać `primaryLogin` dla konta ucznia (lub gdy login nie jest numerem konta Librus / kończy się na `u`) do `11010033`.
   - W Method 3 (Cloud Firestore SDK) sprawdzać po kolei kandydatów `[targetLogin, strippedLogin, '11010033']` oraz opcjonalnie pierwszy dokument z kolekcji `students`, aby Oskar zawsze otrzymał pełny dokument z `timetable`.
3. **`lib/presentation/screens/auth/librus_connect_screen.dart` & `lib/presentation/providers/school_providers.dart`**:
   - Po połączeniu konta odświeżać (`ref.invalidate`) wszystkie providery danych szkolnych (`todayScheduleProvider`, `weekScheduleProvider`, `studentProfileProvider`, `upcomingExamProvider`, `subjectsProvider`, `recentGradesProvider`, `attendanceProvider`, `messagesProvider`) oraz powiązać je z `appUserProvider`, aby zmiana roli/użytkownika natychmiast przeładowywała plan lekcji.
4. **`functions/index.js` & `functions/src/sync_service.js`**:
   - W `getStudentData`, `saveConnection` i `syncStudentData` dla `role === "student"` (lub gdy dokument `students/{login}` nie istnieje) automatycznie rozwiązywać dokument docelowy do `primaryLogin || process.env.LIBRUS_LOGIN || "11010033"`.
5. **Wdrożenie (Hosting + Cloud Functions)**:
   - Zbudować `flutter build web --release` i wdrożyć na Firebase Hosting oraz zaktualizować Cloud Functions (`getStudentData`, `saveConnection`, `syncNow`).
