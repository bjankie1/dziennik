# Project State

**Current Milestone:** Milestone v2.0
**Active Phase:** Phase 4: Bezpieczny autologin i trwałe powiązanie profilu Librus
**Status:** Planning
**Last Updated:** 2026-09-15

## Completed in v1.0
- [x] GSD Core zainstalowany i skonfigurowany w projekcie (`.agents/`, `.planning/codebase/`).
- [x] Połączenie z Librus Synergia w pełni funkcjonalne (Cloud Functions v2 w `europe-west3`).
- [x] **Phase 1**: Interaktywny przełącznik dni tygodnia w `ScheduleScreen` (Pon-Pt) powiązany z `dayScheduleProvider` i bazy Firestore. Dynamiczne daty tygodnia i nazwa miesiąca.
- [x] **Phase 1**: Kompaktowy układ siatki ocen (2 kolumny na smartfonie, 3 na desktopie) na Pulpicie (`DashboardScreen`) z czytelną datą wystawienia (`dd.MM`) przy każdej ocenie.
- [x] **Phase 2**: Rzeczywista frekwencja z Librus Synergia pobierana przez `LibrusClient.fetchAttendance()`. Statystyki (142 obecności, 98.6%, 2 nieusprawiedliwione) oraz lista wpisów w `AttendanceScreen` pogrupowana według dni.
- [x] **Phase 3**: Rzeczywiste wiadomości od nauczycieli i dyrekcji pobierane przez `LibrusClient.fetchMessages()`. Prezentacja w `MessagesScreen` z awatarami inicjałów, oznaczeniami ważności oraz automatycznym generowaniem powiadomień w cyklu synchronizacji.
- [x] Dolny pasek nawigacji z dynamicznymi plakietkami (badges) dla nieusprawiedliwionych nieobecności i nowych wiadomości.

## Milestone v2.0 Roadmap
- [ ] **Phase 4**: Bezpieczny autologin i trwałe powiązanie profilu Librus
- [ ] **Phase 5**: Nowy interfejs Ocen wg makiety
- [ ] **Phase 6**: Moduł usprawiedliwiania nieobecności wg makiety
