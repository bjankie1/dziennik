# Discussion Log: Phase 13 — Dedykowane URL i routing dla podstron i zasobów (deep linking)

- **Date:** 2026-09-21
- **Participants:** User, Assistant

## Discussed Areas:
1. **Format URL w przeglądarce:**
   - Wybrano: Czyste ścieżki bez hasha (Path URL Strategy, np. `https://lepsza-szkola.web.app/plan-lekcji`).
   - Uzasadnienie: Standard nowoczesnych aplikacji webowych, w pełni kompatybilne z konfiguracją Firebase Hosting rewrites (`"source": "**", "destination": "/index.html"`).

2. **Konwencja nazewnictwa tras:**
   - Wybrano: Język polski (`/pulpit`, `/plan-lekcji`, `/oceny`, `/frekwencja`, `/wiadomosci`).

3. **Deep linking do zasobów:**
   - Wybrano: Pełna obsługa linków bezpośrednich do wątków (`/wiadomosci/:threadId`), parametryzacja planu lekcji (`/plan-lekcji?data=YYYY-MM-DD`).

4. **Zachowanie autoryzacji przy bezpośrednim wejściu:**
   - Wybrano: Zapamiętanie docelowego adresu URL i automatyczne przekierowanie po udanym uwierzytelnieniu/autologinie.
