# Coding Conventions

**Analysis Date:** 2026-09-15
**Project:** EduSync

## Code Style & Lints
- **Flutter:** `flutter_lints: ^6.0.0` with `analysis_options.yaml`.
- **Formatting:** `dart format` (standard 80/100 col width).
- **Naming:**
  - Classes/Enums: `PascalCase` (`StudentProfile`, `LessonStatus`)
  - Variables/Methods: `camelCase` (`getTodaySchedule`, `isSyncing`)
  - Files: `snake_case.dart` (`firestore_school_repository.dart`)
  - Constants: `lowerCamelCase` or `UPPER_SNAKE` for fixed constants

## State Management Guidelines
- Riverpod Notifiers and FutureProviders are preferred over `setState` for domain state.
- Use `ref.watch` in build methods for reactive re-renders.
- Use `ref.read` in action callbacks (e.g. `onTap`, `onPressed`).
- `ref.invalidate(...)` is used to force refresh cached FutureProviders upon sync.

## Error Handling & Resiliency
- Web/Platform independence: Never depend solely on browser-specific JS bindings when pure Dart HTTP REST calls are viable.
- Fallback pattern: Real data primary -> Cached snapshot secondary -> Graceful fallback to demo mode on network failure.

*Codebase analysis: 2026-09-15*
