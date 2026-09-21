# Phase 11: Dyskretne odpytywanie serwerów Librus (rate limiting, harmonogram nocny) - Context

**Gathered:** 2026-09-18  
**Status:** Ready for planning  

<domain>
## Phase Boundary

Optymalizacja i zabezpieczenie strategii odpytywania serwerów Librus przez Cloud Functions i aplikację mobilną/webową, aby nie budzić podejrzeń o automatyzację ani łamanie regulaminu serwisu:
- Wprowadzenie ciszy nocnej (całkowity brak automatycznych zapytań w nocy).
- Zróżnicowanie częstotliwości synchronizacji (godziny lekcyjne vs popołudnia vs weekendy).
- Eliminacja jednoczesnych zapytań `Promise.all` na rzecz sekwencyjnego odpytywania z ludzkim opóźnieniem (losowy jitter 1.0 – 2.5s).
- Unowocześnienie profilu przeglądarki (aktualny User-Agent i komplet nagłówków zamiast Firefox 10 z 2012 roku).
- Zarządzanie stanem sesji (re-use ciasteczek zamiast ponownego logowania OAuth przy każdym cyklu).
- Dynamiczny backoff przy kodach 429/503 oraz cooldown po stronie interfejsu użytkownika.

</domain>

<decisions>
## Implementation Decisions

### Harmonogram i Cisza Nocna
- **D-01:** **Cisza nocna (22:30 – 06:30)**: Całkowite zawieszenie automatycznego odpytywania serwerów Librus w tle przez harmonogram (`scheduledLibrusSync`). W tych godzinach serwery Librus nie są niepokojone jakimikolwiek zapytaniami automatycznymi.
- **D-02:** **Częstotliwość w dni szkolne**: Od poniedziałku do piątku w godzinach 07:00 – 16:30 synchronizacja działa co 30–40 minut z losowym jitterem (+/- 3–7 minut), co eliminuje przewidywalne, punktualne wywołania crona. Po godzinie 16:30 do 22:30 odpytywanie co 60 minut.
- **D-03:** **Częstotliwość w weekendy**: W soboty i niedziele automatyczne odpytywanie odbywa się wyłącznie 2 razy na dobę (np. o 11:00 i 19:00).
- **D-04:** **Manualne odświeżenie na żądanie (On-demand sync)**: Użytkownik może ręcznie kliknąć „Odśwież” o dowolnej porze (w tym w nocy), ale żądanie jest chronione ogranicznikiem (cooldown minimum 2 minuty), zapobiegającym wielokrotnemu klikaniu.

### Sekwencyjność i Humanizacja Ruchu HTTP
- **D-05:** **Sekwencyjne pobieranie modułów**: Zastąpienie `Promise.all([fetchInfo, fetchAnn, fetchGrades, ...])` pętlą sekwencyjną z losową przerwą (1.0 – 2.5 sekundy) pomiędzy kolejnymi modułami (oceny, plan lekcji, frekwencja, wiadomości). Imituje to zachowanie człowieka klikającego w kolejne zakładki dziennika.
- **D-06:** **Nowoczesny profil przeglądarki i nagłówki HTTP**: Zastąpienie przestarzałego User-Agenta (`Mozilla/5.0 ... Firefox/10.0` z 2012 roku) nowoczesnym ciągiem (aktualny Chrome/Safari) oraz uzupełnienie żądań o realistyczne nagłówki (`Accept`, `Accept-Language: pl,en-US;q=0.9`, `Sec-Ch-Ua`, `Sec-Fetch-Dest`, `Sec-Fetch-Mode`).
- **D-07:** **Utrzymywanie sesji i ponowne użycie ciasteczek**: Ciasteczka sesyjne przechowywane są w Firestore / pamięci instancji i wykorzystywane ponownie tak długo, jak sesja pozostaje ważna. Ponowna procedura autoryzacji OAuth (`api.librus.pl/OAuth/Authorization`) jest wywoływana wyłącznie wtedy, gdy sesja wygaśnie (np. status 302 do logowania lub brak uprawnień).
- **D-08:** **Dynamiczny backoff przy błędach 429 / 503**: W przypadku napotkania kodu HTTP 429 (Too Many Requests), 503 lub strony z weryfikacją anty-botową, automatyczne zapytania są natychmiast wstrzymywane na okres 15–30 minut, a aplikacja bezpiecznie serwuje dane z pamięci podręcznej Firestore.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend Scraping & Cloud Functions
- `functions/src/librus_client.js` — Implementacja klienta Librus Synergia, obsługa ciasteczek (`CookieJar`), logowanie OAuth i pobieranie poszczególnych modułów.
- `functions/src/sync_service.js` — Logika synchronizacji danych ucznia, agregacja zmian i zapisywanie powiadomień w Firestore.
- `functions/index.js` — Konfiguracja harmonogramu `scheduledLibrusSync` oraz endpointów `syncNow` i `getStudentData`.

### Frontend Synchronization State
- `lib/presentation/providers/sync_provider.dart` — Zarządzanie stanem synchronizacji, wywołanie `/api/syncNow` i obsługa komunikatów statusu.

</canonical_refs>
