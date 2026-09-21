---
title: "Naprawa licznika nieprzeczytanych wiadomości oraz dodanie kafelków wiadomości na pulpicie mobilnym"
date: 2026-09-21
status: complete
---

# Plan: Licznik nieprzeczytanych wiadomości i kafelki na pulpicie mobilnym

## Problem
1. Użytkownik widzi nowe wiadomości z dzisiaj, ale przy linku do strony wiadomości (sidebar, navigation bar, mobile header) nie pojawia się żadna cyfra (badge).
   - Wynikało to ze zbyt naiwnej heurystyki scrapera w `librus_client.js` (`!$(tr).hasClass("bold") && !$(tds[3]).find("b").length`), która dla wszystkich wiadomości Synergii zwracała `isRead = true`.
   - Dodatkowo w repozytorium brakowało traktowania nowych, jeszcze nieotwartych w EduSync wiadomości z bieżącego dnia jako nieprzeczytanych.
2. Na mobilnym pulpicie (`_buildMobileDashboard`) w ogóle brakowało sekcji wiadomości.

## Rozwiązanie
1. **Librus scraper & backend (`librus_client.js`, `sync_service.js`):**
   - Poprawa detekcji nieprzeczytanych wiadomości w HTML Synergii (analiza styli pogrubienia `font-weight: bold`, ikon statusu koperty `nieprzeczytan`/`zamkniet`/`unread` oraz licznika nieprzeczytanych w menu strony).
   - Zapisywanie `unreadMessagesCount` w dokumencie studenta w Firestore.
2. **Repozytorium i stan aplikacji (`firestore_school_repository.dart`, `sync_provider.dart`):**
   - Inteligentne wyznaczanie `isUnread`: priorytet mają jawne akcje użytkownika (`_localReadOverrides`), a wiadomości nieotwarte z bieżącego dnia lub z flagą nieprzeczytanej są oznaczane jako `isUnread: true`.
   - Odczyt `unreadMessagesCount` w profilu ucznia.
   - Dodanie inwalidacji `messagesProvider` i `attendanceProvider` przy wywołaniu `syncNow()`.
3. **Pulpit mobilny (`dashboard_screen.dart`):**
   - Dodanie dedykowanej karty "WIADOMOŚCI" z banerem informującym o nowych wiadomościach oraz kafelkami najnowszych wiadomości z bezpośrednim przejściem do wątku.
