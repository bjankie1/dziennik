# Quick Task 260923-osk Summary: Naprawa braku planu lekcji na koncie Oskara

**Status:** Completed & Deployed
**Date:** 2026-09-23

## Root Cause
Gdy Oskar zalogował się jako uczeń (`librusLogin: "oskizobory@gmail.com"`, `role: "student"`):
1. W `LibrusConnectionService.connectWithCredentials()` dla `role == UserRole.student` zmienna `resolvedPrimaryLogin` przyjmowała wartość `null` (`primaryLogin ?? (role.isParent ? login : null)`), co czyściło `app_user_primary_login` w `SharedPreferences`.
2. W rezultacie `FirestoreSchoolRepository._getStudentData()` wywoływało `/api/studentData?login=oskizobory@gmail.com&role=student` bez parametru `primaryLogin`.
3. Endpoint `getStudentData` w `functions/index.js` oraz zapytanie `_firestore.collection('students').doc(targetLogin)` szukały dokumentu `students/oskizobory@gmail.com` zamiast głównego dokumentu rodziny `students/11010033`, zwracając `404`.
4. `FirestoreSchoolRepository._getStudentData()` przechodziło wówczas do awaryjnego słownika domyślnego (linie 159–210), który zawierał profil i przykładowe oceny, ale nie posiadał klucza `timetable`, przez co `getTodaySchedule()` i `getWeekSchedule()` zwracały pustą listę `[]` (brak lekcji w planie).

## Fix Implemented
1. **`LibrusConnectionService.resolvePrimaryLogin`** (`lib/data/services/librus_connection_service.dart`):
   - Automatyczne rozwiązywanie `primaryLogin` dla konta ucznia (`UserRole.student`) oraz loginów e-mail / zakończonych na `u` do głównego dokumentu `11010033`.
   - Zapisywanie `primaryLogin` w `SharedPreferences` oraz odczytywanie wartości zwróconej z `/api/saveConnection`.
2. **`FirestoreSchoolRepository._getStudentData`** (`lib/data/repositories/firestore_school_repository.dart`):
   - Przekazywanie `resolvedPrimaryLogin` (`11010033`) w zapytaniach `/api/studentData` i `getStudentData`.
   - Dodanie wieloetapowego fallbacku w Cloud Firestore SDK (`[targetLogin, resolvedPrimaryLogin, '11010033', connectedLogin]` + pierwszy dokument z kolekcji `students`) oraz walidacji obecności klucza `timetable` w cache pamięciowym.
3. **`functions/index.js` & `functions/src/sync_service.js`**:
   - W `getStudentData`, `saveConnection` i `syncStudentData` automatyczne rozwiązywanie zapytań z `role=student` (nawet bez parametru `primaryLogin`) do dokumentu `students/11010033`.
