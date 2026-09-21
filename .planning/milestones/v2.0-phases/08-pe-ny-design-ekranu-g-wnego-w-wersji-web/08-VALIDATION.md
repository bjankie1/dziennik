---
phase: "08"
slug: "pe-ny-design-ekranu-g-wnego-w-wersji-web"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-16"
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter Test / flutter_test |
| **Config file** | analysis_options.yaml |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | REQ-DASH-02 | — | N/A | widget | `flutter test test/navigation_shell_test.dart` | ❌ W0 | ⬜ pending |
| 08-01-02 | 01 | 1 | REQ-DASH-02 | — | N/A | static | `flutter analyze` | ✅ | ⬜ pending |
| 08-02-01 | 02 | 2 | REQ-DASH-02 | — | N/A | widget | `flutter test test/dashboard_screen_test.dart` | ❌ W0 | ⬜ pending |
| 08-02-02 | 02 | 2 | REQ-DASH-02 | — | N/A | static | `flutter analyze` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/navigation_shell_test.dart` — Test weryfikujący wyświetlanie `AppSidebar` na ekranach desktopowych (>= 1024px) oraz dolnego paska nawigacji na ekranach mobilnych (< 1024px)
- [ ] `test/dashboard_screen_test.dart` — Test weryfikujący renderowanie komponentów desktopowych Pulpitu (Bento Grid, Banner powitalny, Harmonogram na dziś, Wiadomości, Oceny i Frekwencję)

---

## Manual-Only Verifications

| Behavior | Why Manual | Verification Procedure |
|----------|------------|------------------------|
| Wierność wizualna z makietą | Sprawdzenie pixel-perfect i responsywności | Otwarcie w Chrome na ekranie desktopowym, porównanie z `docs/start_page_web_v1/screen.png` |
| Przejście do wysyłki e-Usprawiedliwienia | Modal e-Usprawiedliwień i PIN | Kliknięcie "Szybkie usprawiedliwienie (PIN)" w kolumnie frekwencji |
| Przejście do tworzenia wiadomości do wychowawcy | Autocomplete wychowawcy | Kliknięcie "Kontakt z wychowawcą" w szybkich akcjach |

---

*Phase: 08-pe-ny-design-ekranu-g-wnego-w-wersji-web*
*Created: 2026-09-16*
