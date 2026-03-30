# FLODO — Task Manager App

A Flutter-based mobile task manager built for **Track B: The Mobile Specialist**.

---

## Track & Stretch Goals

- **Track:** B (Mobile Specialist — Flutter & Dart, local database, no backend)
- **Stretch Goal 1:** Debounced Autocomplete Search — 300ms debounce with matched text highlighting in results
- **Stretch Goal 2:** Recurring Tasks Logic — Daily/Weekly recurrence that auto-schedules the next task on completion

---

## Prerequisites

Make sure the following are installed before running the project:

| Tool | Version | Link |
|---|---|---|
| Flutter SDK | 3.x or later | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.x (bundled with Flutter) | — |
| Android Studio | Latest stable | https://developer.android.com/studio |
| Android Emulator | API 33+ (Pixel 6 recommended) | Set up via Android Studio AVD Manager |
| Git | Any recent version | https://git-scm.com |

Verify your setup:
```bash
flutter doctor
```
All checkmarks must be green before proceeding.

---

## Setup & Run Instructions

**1. Clone the repository**
```bash
git clone https://github.com/your-username/flodo.git
cd flodo
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Generate Hive model adapters**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
> This step is required. The app will crash at launch without it.

**4. Generate the app launcher icon**
```bash
flutter pub run flutter_launcher_icons
```

**5. Start your Android emulator**
- Open Android Studio → Device Manager → Start a Pixel 6 (API 33+) emulator
- Or run via command line: `flutter emulators --launch <emulator_id>`

**6. Run the app**
```bash
flutter run
```

---

## Project Structure

```
lib/
  main.dart
  models/          # Hive data model (Task)
  providers/       # TaskProvider, DraftProvider (state management)
  screens/         # HomeScreen, TaskFormScreen, TaskDetailScreen
  widgets/         # TaskCard, FilterChipBar, EmptyState, RobotIcon
  theme/           # App theme (dark, black & blue)
  utils/           # Date utilities
assets/
  icon/            # App launcher icon (robot)
```

---

## AI Usage Report

This project was built with AI assistance across multiple tools, each used for a specific role:

| Tool | Role |
|---|---|
| **Cursor AI** | Primary code generation — scaffolded the full Flutter project structure, all screens, providers, Hive setup, and feature implementation |
| **Google Project IDX (Antigravity)** | UI design refinements — layout fixes, robot icon integration, header alignment |
| **Claude (Anthropic)** | Prompt engineering and planning — wrote all structured prompts fed into Cursor, designed feature specs and architecture decisions |
| **ChatGPT (OpenAI)** | Error handling — debugged runtime errors, Hive build_runner issues, and Flutter widget conflicts |
| **Gemini (Google)** | Research — investigated Flutter packages, compared local DB options (Hive vs Isar), looked up API docs |
| **Android Studio** | Virtual device management — ran and tested the app on Android Emulator (Pixel 6, API 33) |

**Note:** All AI-generated code was reviewed, tested, and validated manually on the emulator. No AI tool was used as a black box — every output was understood before being committed.

---

## Features Implemented

- ✅ Task model: Title, Description, Due Date, Status, Blocked By
- ✅ Main list view with blocked task visual indicator (greyed out + lock icon)
- ✅ Task creation & edit screen with full field validation
- ✅ Task detail screen (read-only view before editing)
- ✅ CRUD with Hive local persistence
- ✅ Draft auto-save on creation screen (persists across minimize/back)
- ✅ Real-time search with 300ms debounce and match highlighting
- ✅ Status filter chips (All / To-Do / In Progress / Done)
- ✅ 2-second simulated save delay with loading state (non-blocking UI)
- ✅ Recurring tasks (Daily / Weekly) with auto-scheduling on completion
- ✅ Drag-and-drop task reordering with persistent sort order
- ✅ Dark theme — black background, blue accent (`#3B9FE8`)
