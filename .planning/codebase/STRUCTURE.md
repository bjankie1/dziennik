# Codebase Structure

**Analysis Date:** 2026-09-15
**Project:** EduSync

```text
.
├── .agents/                 # Open-GSD framework (skills, hooks, agents)
├── .planning/               # GSD Project planning and codebase documentation
│   └── codebase/            # Architecture, stack, and convention maps
├── build/                   # Compiled outputs (web release)
├── functions/               # Firebase Cloud Functions (v2) Node.js service
│   ├── src/
│   │   ├── librus_client.js # Synergia scraper & OAuth handshake
│   │   └── sync_service.js  # Firestore syncer & diff detector
│   ├── index.js             # Function declarations (syncNow, getStudentData, etc.)
│   └── package.json
├── lib/                     # Flutter / Dart source code
│   ├── core/
│   │   ├── auth/            # Firebase auth client service
│   │   └── theme/           # Academic Precision color tokens and ThemeData
│   ├── data/
│   │   ├── mock/            # Static mock dataset for demo mode
│   │   ├── repositories/    # SchoolRepository, FirestoreSchoolRepository, MockSchoolRepository
│   │   └── services/        # LibrusConnectionService, LibrusAuthService
│   ├── domain/
│   │   └── models/          # Immutable entity models (Profile, Grade, LessonSlot, etc.)
│   ├── presentation/
│   │   ├── providers/       # Riverpod providers (school, auth, sync)
│   │   ├── screens/         # Dashboard, Schedule, Grades, Attendance, Messages, Auth
│   │   └── widgets/         # AppHeader, modals, components
│   ├── firebase_options.dart# Firebase configuration per platform
│   └── main.dart            # Flutter entry point
├── web/                     # Web deployment assets (index.html, manifest.json)
├── firebase.json            # Firebase Hosting, Functions, and Firestore configuration
├── firestore.rules          # Security rules for Cloud Firestore
└── pubspec.yaml             # Dart & Flutter dependencies
```

*Codebase analysis: 2026-09-15*
