# Phase 20: Asystent AI dziennika szkolnego (Konwersacyjny agent Q&A) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-26
**Phase:** 20-asystent-ai-dziennika-szkolnego
**Areas discussed:** Umiejscowienie Asystenta AI w interfejsie, Silnik AI i Telegram, Indeksowanie pełnej treści wiadomości Librus, Interaktywne źródła i historia rozmowy

---

## Umiejscowienie Asystenta AI w interfejsie

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrydowo (nagłówek + `/czat`) | Globalny przycisk w górnym nagłówku + zakładka w `/czat` | |
| Tylko globalny modal z nagłówka | Wysuwana szuflada z górnego paska | |
| Osobna 8. pozycja w menu | Nowa zakładka `/asystent` w menu bocznym | |
| Własna odpowiedź użytkownika | Czat jako pływający przycisk pozwalający napisać do Oskara albo do Agenta AI (bez nowej zakładki) | ✓ |

**User's choice:** „To mogłaby być część czatu. Czat jako pływający przycisk pozwalający na napisanie coś albo do Oskara albo do Agenta AI. Nie potrzebuję nic dodatkowego jako nowej zakładki w tej fazie.”

---

## Silnik AI (Firebase AI Logic + Gemini 3) oraz zadawanie pytań przez Telegram

| Option | Description | Selected |
|--------|-------------|----------|
| W aplikacji + w bocie Telegram | Działa w czacie w aplikacji oraz odpowiada na pytania wysyłane do bota na Telegramie | |
| Tylko w pływającym czacie w aplikacji | Telegram służy wyłącznie do jednostronnych powiadomień i piątkowego raportu | ✓ |

| Option (Wybór modelu i autoryzacji) | Description | Selected |
|--------|-------------|----------|
| **Firebase AI Logic (`FirebaseAI.googleAI` Free Tier) + `gemini-3.8-flash` (`gemini-flash-latest`) + przełącznik na `gemini-3.1-pro-preview`** | Darmowy Free Tier Gemini Developer API bez ręcznych kluczy API, z najnowszym modelem Gemini 3.8 Flash i opcją przełączenia na Gemini 3.1 Pro | ✓ |
| Tylko jeden model bez przełącznika | Stały model bez wyboru w UI | |

**User's choice:** Firebase AI Logic (`FirebaseAI.googleAI` na darmowym Free Tierze) z najnowszym modelem **Gemini 3.8 Flash (`gemini-3.8-flash` / `gemini-flash-latest`)** oraz opcją przełączenia na **Gemini 3.1 Pro (`gemini-3.1-pro-preview`)**; wywoływany wyłącznie z pływającego czatu w aplikacji.

---

## Pełna treść wiadomości Librus (pytania o wycieczki i zebrania)

| Option | Description | Selected |
|--------|-------------|----------|
| Automatyczne dogrywanie pełnych treści w tle | Po kilka niepobranych wiadomości na cykl synchronizacji z jitterem Fazy 11, aż zbuforuje ostatnie ~30–40 wiadomości w Firestore | ✓ |
| Tylko już pobrane treści + dociąganie on-demand | Przeszukiwanie tylko już otwartych wiadomości + dociąganie 2–3 pasujących tematów w momencie pytania | |

**User's choice:** Automatyczne dogrywanie pełnych treści w tle (po kilka niepobranych wiadomości na cykl synchronizacji z jitterem z Fazy 11, aż zbuforuje ostatnie ~30–40 wiadomości w Firestore) — dzięki temu AI zna treść nawet nieotwartych jeszcze wiadomości.

---

## Interaktywne źródła, szybkie akcje i widoczność rozmowy z AI

| Option | Description | Selected |
|--------|-------------|----------|
| Odpowiedź + klikalne źródło + szybkie akcje (`+ Kalendarz Google`, `+ Dodaj zadanie`) | Klikalne pigułki źródeł + kontekstowe przyciski kalendarza i zadań dla terminów/wydarzeń | ✓ |
| Tylko odpowiedź + link do źródła | Bez przycisków kalendarza i zadań | |

| Option (Historia rozmowy) | Description | Selected |
|--------|-------------|----------|
| Osobna dla każdego użytkownika + „Wyczyść czat” | Rodzic ma swój wątek z AI, a Oskar swój własny wątek z AI | ✓ |
| Wspólna dla rodziny | Rodzic i Oskar widzą te same pytania i odpowiedzi | |

**User's choice:** Odpowiedź + klikalne źródło + kontekstowe przyciski szybkiej akcji (`+ Kalendarz Google`, `+ Dodaj zadanie`); osobna historia rozmowy dla każdego użytkownika + przycisk „Wyczyść czat”.

---

## the agent's Discretion

- Struktura promptu systemowego dla Gemini 2.5 Flash i format zwracanych metadanych (`sources`, `suggestedEvent`, `suggestedTask`).
- Konfiguracja klucza `GEMINI_API_KEY` w Cloud Functions / ustawieniach aplikacji.

## Deferred Ideas

- Dwukierunkowy czat z AI na Telegramie — pominięty celowo.
