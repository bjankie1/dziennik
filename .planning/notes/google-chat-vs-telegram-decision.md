---
title: "Analiza kanałów powiadomień: Google Chat vs Telegram Bot API"
date: "2026-09-25"
status: "decided"
decision: "Pozostajemy przy Telegram Bot API + Web Push; odrzucamy Google Chat oraz briefing e-mail"
---

# Notatka Architektoniczna: Google Chat vs Telegram Bot API (Konta `@gmail.com`)

## Kontekst
Przeprowadzono analizę wykonalności (`/gsd-explore`) podłączenia powiadomień w czasie rzeczywistym (Faza 18) oraz Piątkowego Briefingu Tygodniowego (Faza 19) do komunikatora **Google Chat** dla prywatnych kont `@gmail.com` rodzica i ucznia (Oskara), w porównaniu do wdrożonego **Telegram Bot API**.

## Kluczowe ustalenia techniczne
1. **Blokada Incoming Webhooks na prywatnych kontach `@gmail.com`:**
   - Google udostępnia funkcję *Incoming Webhooks* w pokojach Google Chat wyłącznie dla płatnych kont **Google Workspace** (dawniej G Suite).
   - W pokojach zakładanych przez użytkowników prywatnych kont konsumenckich (`@gmail.com`) sekcja *Aplikacje i integracje -> Webhooki* jest całkowicie niedostępna.
2. **Blokada Google Chat API (Boty w Google Cloud Console):**
   - Konfiguracja i publikacja aplikacji/bota Google Chat w Google Cloud Console wymaga powiązania projektu z organizacją **Google Workspace** (`Google Workspace organization required`).
3. **Przewaga Telegram Bot API:**
   - W 100% darmowy dla prywatnych kont konsumenckich.
   - Obsługuje niezależne parowanie telefonu rodzica i ucznia (osobne `chatId`), formatowanie HTML oraz dwukierunkowe wywołania bez konieczności posiadania domeny firmowej.

## Decyzja
- **Odrzucamy integrację z Google Chat** (brak konta Google Workspace — używane są wyłącznie prywatne konta `@gmail.com`).
- **Nie wdrażamy dodatkowego kanału e-mail (Gmail)** dla Piątkowego Briefingu.
- **Docelowa architektura powiadomień i raportów (Faza 18 i Faza 19):** **Telegram Bot API + Natywny Web Push (PWA) + widok w aplikacji EduSync**.
