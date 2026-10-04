# Phase 26: Pełna treść wiadomości i ogłoszeń oraz linki do załączników w powiadomieniach Telegram - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-04
**Phase:** 26-pe-na-tre-wiadomo-ci-i-og-osze-oraz-linki-do-za-cznik-w-w-po
**Areas discussed:** Pełna treść i zachowanie przy bardzo długich wiadomościach/ogłoszeniach, Prezentacja załączników na Telegramie, Układ wiadomości Telegram

---

## Pełna treść i zachowanie przy bardzo długich wiadomościach/ogłoszeniach

| Option | Description | Selected |
|--------|-------------|----------|
| Pełna treść w 1 wiadomości (z bezpiecznym obcięciem ~3500 zn.) | Wysyłaj pełną treść w jednej wiadomości z zachowaniem podziału na linie; jeśli przekracza ~3500 znaków, obetnij z dopiskiem „… (pełna treść w aplikacji)”, aby zawsze zmieścić załączniki i link na dole | ✓ |
| Dzielenie na 2 wiadomości | Dziel bardzo długie wiadomości/ogłoszenia (>4096 znaków) na 2 kolejne wiadomości na Telegramie | |
| Skrócony podgląd | Wysyłaj skrócony podgląd (np. pierwsze 500–800 znaków) zamiast pełnej treści | |

**User's choice:** Wysyłaj pełną treść w jednej wiadomości z zachowaniem podziału na linie; jeśli przekracza ~3500 znaków, obetnij z dopiskiem „… (pełna treść w aplikacji)”, aby zawsze zmieścić załączniki i link na dole.

---

## Prezentacja załączników na Telegramie

| Option | Description | Selected |
|--------|-------------|----------|
| Klikalne linki HTML w treści | Sekcja „📎 Załączniki (X):” w treści wiadomości Telegram z klikalnymi linkami HTML do każdego pliku (`https://lepsza-szkola.web.app/api/downloadAttachment?path=...`) | ✓ |
| Klikalne linki + wysyłka plików (sendDocument) | Klikalne linki w treści wiadomości + dodatkowo wysyłanie każdego załącznika jako osobnego pliku (`sendDocument`) na czat Telegram | |

**User's choice:** Sekcja „📎 Załączniki (X):” w treści wiadomości Telegram z klikalnymi linkami HTML do każdego pliku (`https://lepsza-szkola.web.app/api/downloadAttachment?path=...`).

---

## Układ wiadomości Telegram

| Option | Description | Selected |
|--------|-------------|----------|
| Osobne nagłówki + deep link + zwięzłe „Ostatnie alerty” | Osobne nagłówki (`📬 Nowa wiadomość` vs `📢 Nowe ogłoszenie szkolne`), bezpośredni deep link do wątku (`/wiadomosci/{id}`) oraz zwięzły podgląd w „Ostatnich alertach” w aplikacji (pełna treść w polu `content` dla Telegrama) | ✓ |
| Pełna treść także na karcie w „Ostatnich alertach” | Taki sam układ i pełna wieloliniowa treść zarówno na Telegramie, jak i na karcie w zakładce „Ostatnie alerty” w oknie Ustawień powiadomień | |

**User's choice:** Osobne nagłówki (`📬 Nowa wiadomość` vs `📢 Nowe ogłoszenie szkolne`), bezpośredni deep link do wątku (`/wiadomosci/{id}`) oraz zwięzły podgląd w „Ostatnich alertach” w aplikacji (pełna treść w polu `content` dla Telegrama).

---

## the agent's Discretion

- Dokładny próg znaków obcięcia treści (~3400–3500 znaków), aby cały komunikat HTML nigdy nie przekroczył 4096 znaków.

## Deferred Ideas

None.
