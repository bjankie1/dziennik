---
phase: 07-funkcjonalny-modu-wiadomo-ci-czytanie-odpowiadanie-wysy-anie
verified: 2026-09-15T20:26:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
---

# Phase 7: Funkcjonalny moduł wiadomości (czytanie, odpowiadanie, wysyłanie) — Verification Report

**Phase Goal:** Pełna obsługa wiadomości Librus: widok wątku w stylu Gmail, odpowiadanie na wiadomości i pisanie nowych wiadomości z inteligentnym autocomplete nauczyciela (nazwisko oraz przedmiot).  
**Verified:** 2026-09-15T20:26:00Z  
**Status:** passed  

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Kliknięcie wątku na liście wiadomości otwiera dedykowany pełny ekran wątku w stylu Gmail z chronologiczną historią konwersacji | ✓ VERIFIED | Wdrożony `MessageThreadScreen`, podpięty pod `_buildMessageCard` w `messages_screen.dart` |
| 2 | Wcześniejsze wiadomości w wątku są zwinięte do 1-liniowych pasków z możliwością rozwinięcia/zwinięcia na kliknięcie, a najnowsza jest w pełni otwarta | ✓ VERIFIED | `_buildCollapsedMessage` / `_buildExpandedMessage` z zarządzaniem stanem `_expandedMessageIds` |
| 3 | Pod ostatnią wiadomością w wątku znajduje się przycisk 'Odpowiedz', który rozwija zintegrowane pole szybkiej odpowiedzi z przyciskiem 'Wyślij' | ✓ VERIFIED | `_buildReplySection` z animowanym rozwinięciem edytora i wysyłaniem |
| 4 | Przycisk 'Napisz' na liście wiadomości otwiera ekran nowej wiadomości z autocomplete odbiorców reagującym na nazwisko nauczyciela i nazwę przedmiotu | ✓ VERIFIED | `NewMessageScreen` z wyszukiwarką `_onSearchChanged` filtrującą przez `TeacherContact.matches` |
| 5 | Wielu nauczycieli może zostać wybranych jako usuwalne chipy (pigułki z x) w polu Do: | ✓ VERIFIED | `InputChip` z listą `_selectedRecipients` i możliwością usuwania |
| 6 | Wysłanie nowej wiadomości lub odpowiedzi aktualizuje stan lokalny oraz odpytuje endpoint backendowy Librusa | ✓ VERIFIED | Metody `sendMessage` w `MockSchoolRepository`, `FirestoreSchoolRepository` oraz Cloud Function `/api/sendMessage` |
| 7 | Otwarcie wątku wiadomości pobiera i wyświetla pełną treść wiadomości z Librus Synergia (a nie tylko powtórzony temat) z on-demand loading i trwałym cache w Firestore | ✓ VERIFIED | Endpoint `/api/messageDetails`, selektor `div.container-message-content`, metoda `getMessageBody` i wskaźnik ładowania w `MessageThreadScreen` |
| 8 | Oznaczanie wiadomości jako nowe i przeczytane (automatycznie i ręcznie) oraz precyzyjny licznik (badge) na ikonie wiadomości i w nagłówku | ✓ VERIFIED | Metody `markMessageAsRead` / `markAllMessagesAsRead`, `unreadMessagesCountProvider`, dynamiczny badge w `NavigationBar` i `AppHeader`, ukrywany gdy count == 0 |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/domain/models/teacher_contact.dart` | TeacherContact model with multi-field search | ✓ EXISTS + SUBSTANTIVE | Wyszukiwanie po nazwisku, przedmiocie i roli |
| `lib/presentation/screens/messages/message_thread_screen.dart` | Gmail-style thread view | ✓ EXISTS + SUBSTANTIVE | Zwijane wiadomości, AppBar akcji i szybka odpowiedź |
| `lib/presentation/screens/messages/new_message_screen.dart` | Compose message screen | ✓ EXISTS + SUBSTANTIVE | Formularz z autocomplete i obsługą wielu odbiorców |
| `lib/presentation/screens/messages/messages_screen.dart` | Connected message list | ✓ EXISTS + SUBSTANTIVE | Nawigacja do wątku i tworzenia nowej wiadomości |
| `functions/index.js` & `functions/src/librus_client.js` | Cloud Functions sendMessage | ✓ EXISTS + SUBSTANTIVE | Obsługa wysyłania do Librus Synergia |

### Build & Deployment Verification
- `flutter analyze`: **Passed with 0 errors and 0 warnings**.
- `flutter build web --release`: Zbudowano pomyślnie wersję produkcyjną.
- `firebase deploy`: Utworzono nową funkcję `sendMessage` w `europe-west3`, zaktualizowano hosting i opublikowano na żywo pod adresem: https://lepsza-szkola.web.app.
