# reusable_reminder_kit

Standalone, reminder-agnostic pieces pulled out of the Offline Smart Reminder
app's design (see the requirements doc, §12.5 "What can be built reusable").
Nothing in here knows what a "reminder" is — it just needs data and a config
— so it can be used in this app now, and copied whole into a future app
later without rewriting anything.

**Fully offline.** No third-party packages — only Flutter's own SDK. `flutter
pub get` needs no network access beyond fetching the Flutter/Dart SDK itself,
which you already have once Flutter is installed.

For complete step-by-step instructions for Windows, Linux, Codespaces, desktop
demo testing, Android phones, and Android emulators, see
[TESTING_GUIDE.md](TESTING_GUIDE.md).

## What's in here

| File | Type | What it does |
|---|---|---|
| `lib/core/result.dart` | pure Dart | `Result<T>` type so use-cases return Ok/Fail instead of throwing |
| `lib/core/date_time_helpers.dart` | pure Dart | Leap-year/month-end-safe date math + dependency-free date formatting |
| `lib/core/importance.dart` | Flutter | Shared `Importance` enum (high/medium/low) + colour/label mapping |
| `lib/recurrence/recurrence_engine.dart` | pure Dart | Given a rule + last trigger date, returns the next trigger date |
| `lib/widgets/importance_color_tag.dart` | Flutter widget | Red/blue/green colour-coded pill |
| `lib/widgets/reminder_list_tile.dart` | Flutter widget | "[Category • Importance] Title" two-line row |
| `lib/widgets/category_selector.dart` | Flutter widget | Dropdown with a built-in "+ Add new category" option |
| `lib/widgets/confirm_action_dialog.dart` | Flutter widget | One confirm/cancel dialog used for every delete action |
| `lib/widgets/empty_state_view.dart` | Flutter widget | Icon + message + optional action, for empty lists |
| `lib/widgets/filter_chips_row.dart` | Flutter widget | Generic single-select chip row (used for the 1wk/2wk/3wk/1mo filter) |

`lib/reusable_reminder_kit.dart` is a barrel file — import that one file to
get everything.

## Current scope and status

This repository is the reusable package layer, not the complete Android
Reminder App. The implemented and tested package scope includes date helpers,
recurrence calculation, result handling, importance mapping, and reusable
Flutter widgets.

The separate browser demo validates the reminder UI flow, including creating,
editing, deleting, filtering, category management, calendar date selection,
clock time selection, and recurrence choices. The demo stores data in memory
only and is intended for smoke testing.

The requirements document also calls for voice recording, audio playback,
local persistence, Android notifications, exact alarms, snooze actions, and
background reminder behavior. Those features are not implemented in this
package yet. They belong in a complete host Flutter app using Android-capable
services and must be validated on a local Android phone or emulator.

## Using it in the Offline Smart Reminder app (now)

1. Copy this whole folder into your project, e.g. as a local package at
   `packages/reusable_reminder_kit/`.
2. In the main app's `pubspec.yaml`, add:
   ```yaml
   dependencies:
     reusable_reminder_kit:
       path: packages/reusable_reminder_kit
   ```
3. Import what you need:
   ```dart
   import 'package:reusable_reminder_kit/reusable_reminder_kit.dart';
   ```
4. This matches the folder structure already proposed in the requirements
   doc §12.2 — `core`, `recurrence`, and the shared widgets are exactly the
   pieces marked reusable in §12.5.

## Using it in a future app (later)

Because there are zero reminder-specific assumptions baked in:

- Drop the whole `reusable_reminder_kit/` folder into a new Flutter project.
- `recurrence_engine.dart` works for any "when does this repeat" feature —
  subscriptions, medication schedules, habit streaks.
- The widgets work for any tagged/dated/categorised list, not just reminders.
- `Result<T>` and the date helpers are generically useful in any Dart project,
  Flutter or not (`date_time_helpers.dart` and `result.dart` have zero
  Flutter imports).

## Testing and running locally

This repository is a reusable Flutter package, not a standalone mobile app. It
does not contain an application `main()` entrypoint, so `flutter run` cannot be
used directly from this repository. There are two separate things to test:

1. The package logic and widgets, tested with `flutter test`.
2. A small host/demo app that imports this package and displays its widgets.

### 1. Test the package logic

This is the required validation step and works on Windows, macOS, Linux, or a
Codespace. It does not need Android, an emulator, or a physical phone.

From the package folder, run:

```bash
flutter pub get
flutter test
flutter analyze
```

To run only the recurrence tests:

```bash
flutter test test/recurrence_engine_test.dart
```

The test suite covers:

- Leap-year Feb 29 handling for yearly recurrence
- End-of-month clamping for monthly recurrence (Jan 31 -> Feb 28/29)
- Fixed-interval-day recurrence
- The `notAfter` upper bound stopping a recurring series
- The dependency-free date formatters

Verified in this project:

```text
00:03 +14: All tests passed!
```

### 2. Run the demo app

The demo is a separate Flutter app that imports this package through a local
path dependency. In this workspace it was created at:

```text
/workspaces/reminder_demo
```

The demo currently includes both `linux/` and `windows/` desktop host folders.
The Windows host was generated with `flutter create --platforms=windows .` and
is ready to run on a Windows computer with the required desktop tooling.

The demo exercises the real package widgets: the category selector, filter
chips, importance tags, reminder list tiles, category dialog, empty state,
confirmation dialog, calendar/time pickers, and recurrence calculation.

If you need to create it again beside this repository:

```bash
cd ..
flutter create --platforms=windows,android reminder_demo
cd reminder_demo
```

Add the local package dependency to the demo app's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  reusable_reminder_kit:
    path: ../Reminder-App
```

Then install dependencies and run the demo on an available target:

```bash
flutter pub get
flutter run
```

The demo itself was also verified with a widget test:

```text
00:04 +2: All tests passed!
No issues found!
```

## If your local computer does not have Linux

You do not need Linux to test this package. Flutter chooses a target platform
based on what is installed on your computer.

### Windows desktop

Install Flutter for Windows and Visual Studio 2022 with the **Desktop
development with C++** workload. Then check the target:

```powershell
flutter doctor
flutter devices
```

If `Windows (desktop)` appears, run the demo with:

```powershell
cd C:\path\to\reminder_demo
flutter pub get
flutter run -d windows
```

The package tests also run directly on Windows:

```powershell
cd C:\path\to\Reminder-App
flutter test
```

Official setup guide: <https://docs.flutter.dev/get-started/install/windows>

### Android phone or Android emulator

For mobile testing, install Android Studio and its Android SDK, then run:

```powershell
flutter doctor
flutter devices
flutter run -d <device-id>
```

You can use a real Android phone with USB debugging enabled. An Android
emulator also works if your computer supports hardware virtualization. A phone
is often easier than configuring an emulator.

### macOS or Linux desktop

Use the corresponding Flutter desktop target shown by `flutter devices`, for
example:

```bash
flutter run -d linux
```

The Codespace used to develop this package has Linux available but no graphical
display. The demo built successfully there, and it could start under a virtual
display with:

```bash
xvfb-run -a flutter run -d linux
```

That verifies startup, but it does not provide a visible window for interactive
use. A normal Windows, macOS, or Linux desktop provides the visible demo UI.

## Recommended workflow

If your local computer is Windows:

1. Install Flutter for Windows.
2. Clone this repository.
3. Run `flutter pub get`, `flutter test`, and `flutter analyze` in this repo.
4. Use a Windows demo app for a visible UI test, or run the demo on Android.
5. Use a real Android phone for mobile installation testing if an emulator is
   unavailable.

The core package validation does not depend on Linux, Android, or an emulator.

For the complete audio and Android notification implementation, continue in a
separate Flutter host app. Use Codespace for Dart/package development and
tests; use Android Studio on a local computer for microphone permissions,
scheduled notifications, exact alarms, background execution, locked-screen
behavior, and real audio playback.
