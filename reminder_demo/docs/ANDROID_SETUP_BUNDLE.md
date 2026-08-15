# Android Setup Bundle

Use this as the single source of truth for dependency paths, checks, and reuse steps in this workspace.
This is the only setup document you need to keep.

## What this workspace contains

- Reusable Flutter package: [pubspec.yaml](pubspec.yaml)
- Package API barrel: [lib/reusable_reminder_kit.dart](lib/reusable_reminder_kit.dart)
- Package logic tests: [test/recurrence_engine_test.dart](test/recurrence_engine_test.dart)
- Host demo app: [reminder_demo/](reminder_demo/)
- Host app entrypoint: [reminder_demo/lib/main.dart](reminder_demo/lib/main.dart)
- Host app manifest: [reminder_demo/pubspec.yaml](reminder_demo/pubspec.yaml)
- Host app test: [reminder_demo/test/widget_test.dart](reminder_demo/test/widget_test.dart)
- Android host folder: [reminder_demo/android/](reminder_demo/android/)

## Dependency locations

### Flutter package root

- [pubspec.yaml](pubspec.yaml)
- [lib/core/date_time_helpers.dart](lib/core/date_time_helpers.dart)
- [lib/core/importance.dart](lib/core/importance.dart)
- [lib/core/result.dart](lib/core/result.dart)
- [lib/recurrence/recurrence_engine.dart](lib/recurrence/recurrence_engine.dart)
- [lib/widgets/category_selector.dart](lib/widgets/category_selector.dart)
- [lib/widgets/confirm_action_dialog.dart](lib/widgets/confirm_action_dialog.dart)
- [lib/widgets/empty_state_view.dart](lib/widgets/empty_state_view.dart)
- [lib/widgets/filter_chips_row.dart](lib/widgets/filter_chips_row.dart)
- [lib/widgets/importance_color_tag.dart](lib/widgets/importance_color_tag.dart)
- [lib/widgets/reminder_list_tile.dart](lib/widgets/reminder_list_tile.dart)

### Demo host app

- [reminder_demo/pubspec.yaml](reminder_demo/pubspec.yaml)
- [reminder_demo/lib/main.dart](reminder_demo/lib/main.dart)
- [reminder_demo/test/widget_test.dart](reminder_demo/test/widget_test.dart)
- [reminder_demo/android/](reminder_demo/android/)

## Where the package dependency is declared

The demo app uses the reusable package with a local path dependency in [reminder_demo/pubspec.yaml](reminder_demo/pubspec.yaml):

```yaml
dependencies:
  reusable_reminder_kit:
    path: ..
```

The app imports that package in [reminder_demo/lib/main.dart](reminder_demo/lib/main.dart):

```dart
import 'package:reusable_reminder_kit/reusable_reminder_kit.dart';
```

## Exact paths to verify first on Windows

Add these folders to PATH, not the exe files:

- `C:\Users\Home\AppData\Local\Android\Sdk\platform-tools`
- `C:\Program Files\Git\cmd`
- `C:\Windows\System32`
- `C:\Windows\System32\WindowsPowerShell\v1.0`
- `C:\flutter_windows_3.47.0-stable\flutter\bin`
- `C:\Users\Home\AppData\Local\Programs\Python\Python310\`
- `C:\Users\Home\AppData\Local\Programs\Python\Python310\Scripts\`

## Commands to check every dependency

### Tooling

```powershell
Get-Command adb
adb version
git --version
flutter --version
flutter doctor -v
flutter devices
flutter emulators
```

### Package root

```powershell
flutter pub get
flutter analyze
flutter test
```

### Demo app

```powershell
Set-Location c:\Reminderapp\reminder_demo
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

## What to check if something is missing

1. Is the file or folder present?
2. Is the PATH entry present?
3. Does `flutter doctor -v` mention the missing tool?
4. Does `flutter devices` show an Android target?
5. Does `flutter analyze` report code issues instead of tool issues?
6. Does `flutter test` fail in the package or in the demo app?

## Reuse checklist for a new app

When you start a similar project, copy these together:

- The reusable package folder
- The host app folder
- This bundle file
- The smoke test pattern

## Fast next steps

1. Open the demo app in [reminder_demo/](reminder_demo/).
2. Start or create an Android emulator.
3. Run `flutter devices`.
4. Run `flutter run -d <device-id>`.
5. Add real reminder features one at a time: storage, notifications, permissions, background handling, audio.
