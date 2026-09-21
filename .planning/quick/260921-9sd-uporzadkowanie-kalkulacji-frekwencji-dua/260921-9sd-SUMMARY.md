---
status: complete
quick_id: 260921-9sd
date: 2026-09-21
description: Uporzadkowanie kalkulacji frekwencji: dual ring gauge i spojne wskazniki obecnosci
---

# Quick Task Summary: 260921-9sd
## Uporządkowanie kalkulacji frekwencji: dual ring gauge i spójne wskaźniki obecności

### Wykonane prace:
1. **Dual Ring Attendance Gauge (`DualRingAttendanceGauge`):**
   - Utworzono komponent `lib/presentation/screens/attendance/widgets/dual_ring_attendance_gauge.dart`.
   - Zewnętrzny pierścień: frekwencja rozliczona (obecności + usprawiedliwione / wszystkie lekcje) w kolorze szmaragdowym (`#059669`).
   - Wewnętrzny pierścień: frekwencja fizyczna (rzeczywista obecność na lekcjach / wszystkie lekcje) w kolorze błękitnym/oceanicznym (`#0284C7`).
   - Centrum: czytelna wartość procentowa rozliczenia oraz pigułka informująca wprost: `$unexcusedCount nieusp.` (czerwona, gdy >0) lub `100% usp.` (zielona, gdy 0).
2. **Kalkulacja i eliminacja błędnego zapisu `3 / 20`:**
   - Wyeliminowano sztuczny fallback `(absences - excused) > 0 ? ... : 3`, który fałszywie pokazywał `3` godziny do usprawiedliwienia.
   - Wskaźniki są teraz obliczane bezpośrednio na podstawie rzeczywistej listy rekordów:
     - `unexcusedCount`: 1 godz. (dokładnie tyle, ile jest w filtrze "Do usprawiedliwienia (1)")
     - `totalAbsences`: suma opuszczonych godzin (19 usprawiedliwionych + 1 nieusprawiedliwiona = 20 opuszczonych)
3. **Nowe, jednoznaczne kafelki podsumowania:**
   - Kafel `Obecności`: 142
   - Kafel `Do uspraw.`: 1 (z podtytułem `z 20 opuszczonych`)
   - Kafel `Usprawiedliwione`: 19 (np. wycieczka szkolna, zwolnienia)
   - Kafel `Spóźnienia`: 2
4. **Weryfikacja i wdrożenie:**
   - `flutter analyze`: 0 błędów i ostrzeżeń.
   - `npm test --prefix functions`: 18/18 testów zdanych.
   - `flutter build web --release` oraz wdrożenie na Firebase Hosting: `https://lepsza-szkola.web.app`.
