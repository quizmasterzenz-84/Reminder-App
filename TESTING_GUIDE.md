# Reminder App Testing Guide

This guide explains how to install the required tools, test the reusable package, and run the demo app on Windows, Linux, or a Codespace.

## 1. Understand the project

`Reminder-App` is a reusable Flutter package/library. It is not a complete standalone mobile application.

This means:

- `flutter test` runs directly in this repository.
- `flutter run` must be run from a separate demo application.
- The demo application imports this repository as a local package.
- Android testing is optional for testing the core package logic.

The package contains date helpers, recurrence logic, and reusable Flutter widgets.

The browser demo also contains a complete in-memory reminder UI smoke test. It
does not yet provide voice recording, audio playback, persistent storage, or
Android notification delivery. Those requirements need a full host app and
local Android testing, as described below.

## 2. Required dependencies

### Required for package tests

Install only these tools:

1. Flutter SDK. Dart is included with Flutter.
2. Git, if cloning the repository from GitHub.
3. A terminal such as PowerShell on Windows or Bash on Linux.

This package has no third-party runtime dependencies. Its `pubspec.yaml` uses only:

```yaml
dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Required for a Windows desktop demo

Install:

1. Flutter for Windows.
2. Visual Studio 2022.
3. The Visual Studio workload **Desktop development with C++**.

Official Flutter guide:

<https://docs.flutter.dev/get-started/install/windows>

### Required for a Linux desktop demo

Install:

1. Flutter for Linux.
2. Linux desktop build dependencies.
3. A graphical Linux desktop session.

Official Flutter guide:

<https://docs.flutter.dev/get-started/install/linux>

### Required for a Web demo

Install:

1. Flutter SDK.
2. A modern browser such as Chrome, Edge, or Firefox.
3. No Android SDK, emulator, Visual Studio, or Linux desktop is required.

### Required for Android testing

Install:

1. Android Studio.
2. Android SDK.
3. Android SDK Platform Tools.
4. An Android phone with USB debugging enabled, or an Android emulator.

The emulator also needs hardware virtualization. A real Android phone is often easier than an emulator.

## 3. Download the repository

### Windows PowerShell

```powershell
git clone https://github.com/quizmasterzenz-84/Reminder-App.git
cd Reminder-App
```

### Linux or Codespace Bash

```bash
git clone https://github.com/quizmasterzenz-84/Reminder-App.git
cd Reminder-App
```

If the repository is already open in VS Code, just open a terminal in the repository folder.

## 4. Check Flutter installation

Run this command first:

```text
flutter doctor
```

The command reports which platforms are ready. Warnings about platforms you do not plan to use can be ignored.

Then confirm Flutter is available:

```text
flutter --version
```

## 5. Test the package logic

This step works on Windows, Linux, macOS, and Codespaces. It does not require Linux, Android, an emulator, or a phone.

From the `Reminder-App` folder, run these commands one at a time:

```text
flutter pub get
```

Expected result: Flutter resolves the package dependencies.

```text
flutter test
```

Expected result:

```text
00:14 +14: All tests passed!
```

The exact time may differ. The important part is `All tests passed!`.

Then check the Dart and Flutter code:

```text
flutter analyze
```

Expected result:

```text
No issues found!
```

The tests cover:

- yearly recurrence, including leap-year February 29
- monthly recurrence with end-of-month clamping
- fixed interval recurrence in days
- stopping recurrence at a `notAfter` date
- date formatting helpers

To run only the recurrence tests:

```text
flutter test test/recurrence_engine_test.dart
```

## 6. Create the demo application

The package does not have an application entrypoint, so create a separate host app beside it.

From the parent directory of `Reminder-App`:

```text
flutter create --platforms=windows,linux,android reminder_demo
cd reminder_demo
```

If you already have the demo folder, do not create it again. Instead, add any missing desktop host with one of these commands from inside the demo folder:

```text
flutter create --platforms=windows .
```

or:

```text
flutter create --platforms=linux .
```

## 7. Connect the demo to this package

Open the demo app's `pubspec.yaml` and add this dependency:

### Windows/Linux when the folders are beside each other

```yaml
dependencies:
  flutter:
    sdk: flutter
  reusable_reminder_kit:
    path: ../Reminder-App
```

### Windows with an absolute path

Use a forward-slash path in YAML, or quote a Windows path:

```yaml
dependencies:
  reusable_reminder_kit:
    path: C:/Users/YourName/Projects/Reminder-App
```

Then run:

```text
flutter pub get
```

The demo must import the package in `lib/main.dart`:

```dart
import 'package:reusable_reminder_kit/reusable_reminder_kit.dart';
```

## 8. Run the complete demo in a browser

Web is the easiest way to see the demo in this Codespace or on a computer that
does not have Linux, Android, or Visual Studio installed. The demo is an
in-memory smoke-test application: created reminders are available while the
demo is open, but are not saved to a database after the app closes.

From the demo folder, add the Web host if it does not already exist:

```text
flutter create --platforms=web .
```

Install the local package and run the web server:

```text
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Open the URL shown by Flutter. In a VS Code Codespace, forward port `8080` in
the **Ports** panel and open the forwarded browser URL. On a local computer,
open:

```text
http://localhost:8080
```

The complete web demo supports these actions:

1. Select an existing category.
2. Use **Add new category** in the category dropdown.
3. Click **New reminder** or the add-reminder icon.
4. Enter a reminder title.
5. Click the calendar button and select the date for the reminder.
6. Click the clock button and select the time for the reminder.
7. Choose a category.
8. Choose High, Medium, or Low importance.
9. Choose Does not repeat, Every 7 days, Monthly, or Yearly.
10. Click **Create reminder** and confirm the new row shows the selected date.
11. Click a reminder row or its edit icon to change its date, time, title, or recurrence.
12. Click its delete icon and confirm the destructive dialog.
13. Use the Next 1 week, Next 2 weeks, and Next month filters.
14. Choose a narrow filter to see the empty state when no reminders match.

The demo's widget tests verify the initial dashboard and reminder creation:

```text
flutter test
00:04 +2: All tests passed!
```

To stop the web server, return to its terminal and press `q` or `Ctrl+C`.

## 9. Run the demo on Windows

Use this on your Windows computer after installing Visual Studio with the C++ workload:

```powershell
cd C:\path\to\reminder_demo
flutter devices
flutter run -d windows
```

The Windows demo displays and exercises:

- category selection
- adding a category
- filter chips
- importance color tags
- reminder list tiles
- recurrence calculation
- reminder row tap feedback

If Windows is not listed by `flutter devices`, run:

```powershell
flutter doctor -v
```

Then install or repair the missing Visual Studio desktop components.

## 10. Run the demo on Linux

On a normal Linux desktop:

```bash
cd /path/to/reminder_demo
flutter devices
flutter run -d linux
```

The Linux target requires a visible graphical desktop. A remote Linux container may build the application but still be unable to show a window.

## 11. Run the demo in this Codespace

This Codespace has Linux Flutter support but no visible graphical `DISPLAY`. The demo can be built and started through a virtual display.

Install the virtual display once:

```bash
sudo apt-get update
sudo apt-get install -y xvfb
```

Run the demo headlessly:

```bash
cd /workspaces/reminder_demo
export PATH="$PATH:$HOME/flutter/bin"
xvfb-run -a flutter run -d linux
```

This verifies that the Linux Flutter application starts, but it does not create a window that you can click from the Codespace UI.

The Android emulator in this Codespace is also blocked by KVM/hardware virtualization permissions. That is an environment limitation, not a package-code failure.

Codespace can test Dart logic, widget behavior, and the browser flow. It cannot
prove real microphone access, Android notification delivery while the app is
closed, exact alarms, locked-screen audio, or Android background execution.

## 12. Run the demo on Android

First connect a real Android phone:

1. Enable Developer options on the phone.
2. Enable USB debugging.
3. Connect the phone with a USB cable.
4. Accept the debugging permission prompt on the phone.
5. Run:

```text
flutter devices
```

6. Start the demo:

```text
cd path/to/reminder_demo
flutter run -d <device-id>
```

Replace `<device-id>` with the ID shown by `flutter devices`.

For an emulator:

1. Open Android Studio.
2. Open Device Manager.
3. Create or start an Android Virtual Device.
4. Run `flutter devices`.
5. Run `flutter run -d <device-id>`.

If an emulator reports KVM, hardware acceleration, or virtualization errors, use a real phone or a local computer with virtualization enabled.

## 13. Run the demo widget test

The demo also has its own widget smoke test. From the demo folder:

```text
flutter test
flutter analyze
```

Expected result:

```text
00:04 +2: All tests passed!
No issues found!
```

## 14. Audio and Android integration status

The requirements document calls for a voice reminder flow:

1. Record a voice message, limited to 20 seconds.
2. Preview and replay the recording before saving.
3. Store the audio file locally with the reminder.
4. Schedule an offline Android notification for the selected date and time.
5. Play the voice message when the reminder triggers.
6. Support snooze, completion, and deletion of the audio file after completion.

These features are not implemented in this reusable package yet. They require a
complete Flutter host app and Android-specific integration, typically including
microphone recording, audio playback, local notification scheduling, local file
storage, runtime permissions, notification channels, and exact-alarm handling.

Use Codespace to develop and test the service interfaces with fake services.
Use a local Android Studio installation with a real phone or working emulator to
test actual microphone permissions, notifications, background execution, and
audio playback. A fake service in a Codespace can verify application control
flow, but it cannot prove that Android will play audio at a scheduled time.

## 15. Recommended order for a Windows computer

Follow these steps in order:

1. Install Flutter for Windows.
2. Install Visual Studio 2022 with **Desktop development with C++**.
3. Open PowerShell.
4. Run `flutter doctor`.
5. Clone the repository.
6. Run `cd Reminder-App`.
7. Run `flutter pub get`.
8. Run `flutter test`.
9. Run `flutter analyze`.
10. Create or open the sibling `reminder_demo` app.
11. Confirm its dependency path points to `../Reminder-App`.
12. Run `flutter pub get` inside `reminder_demo`.
13. Run `flutter devices`.
14. Run `flutter run -d windows` for a Windows desktop smoke test.
15. Connect an Android phone and run `flutter run -d <device-id>` for mobile testing.

## 16. What has been verified in the development Codespace

The following checks pass:

```text
Reminder-App: 14 tests passed
reminder_demo: 2 widget tests passed
Reminder-App: flutter analyze reports no issues
reminder_demo: flutter analyze reports no issues
```

The Windows host files have been generated for the demo. The Codespace cannot execute a Windows desktop binary because it runs Linux, so the final Windows desktop launch must be performed on a Windows computer.
