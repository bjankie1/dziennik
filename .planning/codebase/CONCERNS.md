# Technical Concerns & Identified Gaps

**Analysis Date:** 2026-09-15
**Project:** EduSync

## 1. Plan Lekcji (Schedule Tab) Day Switching
- **Observed Bug:** Switching between Monday, Tuesday, Wednesday, Thursday, Friday in `ScheduleScreen` does not change the active day's lessons, or defaults to a hardcoded view.
- **Root Cause:** State of the selected day is disconnected from the timetable filter in `ScheduleScreen`.
- **Target Fix:** Wire the selected day tab (1 to 5) to dynamically filter the timetable entries from `timetable` for that day.

## 2. Dashboard Grades Layout & Dates
- **Observed Issue:** Recent grades cards on the dashboard occupy full horizontal width, limiting the number of visible grades, and do not show the date of each grade.
- **Target Fix:** Compact grid or horizontal/two-column layout with explicit display of date (e.g. `15.09`), weight, category, and subject badge.

## 3. Frekwencja (Attendance) Real Data
- **Current State:** Still returns `_mockFallback.getAttendanceRecords()` (mock dates from October 2024 as shown in user screenshot).
- **Target Fix:** Implement attendance scraping from `https://synergia.librus.pl/przegladaj_nb/uczen`, save attendance entries to Firestore, and wire to `FirestoreSchoolRepository.getAttendanceRecords()`.

## 4. Wiadomości (Messages) Real Data
- **Current State:** Returns `_mockFallback.getMessages()`.
- **Target Fix:** Implement messages scraping from `https://synergia.librus.pl/wiadomosci/1/5`, save threads to Firestore, and wire to `FirestoreSchoolRepository.getMessages()`.

*Codebase analysis: 2026-09-15*
