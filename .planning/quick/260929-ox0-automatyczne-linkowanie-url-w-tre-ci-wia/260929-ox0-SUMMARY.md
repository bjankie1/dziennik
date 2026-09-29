# 260929-ox0 — SUMMARY

**Status:** ✅ Zakończone

## Zmiany
- `lib/presentation/widgets/linkified_text.dart` (nowy): `LinkSegment`, `splitLinks()`, `LinkifiedSelectableText`.
- `lib/presentation/screens/messages/message_thread_screen.dart`: treść wiadomości → `LinkifiedSelectableText` (tekst nadal zaznaczalny).
- Linki otwierane przez `openUrlInBrowser` → `window.open(url, '_blank')` (zawsze nowa karta).
- `www.` uzupełniane o `https://`; końcowa interpunkcja (`.,;:!?` itp.) i niezbalansowane `)` nie trafiają do URL.

## Testy
- `test/presentation/widgets/linkified_text_test.dart` — 7/7 zielonych.
- `flutter analyze` — bez uwag.
