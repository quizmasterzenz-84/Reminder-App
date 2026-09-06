# Container testing

The repository includes a reproducible Flutter test container pinned to Flutter 3.47.0 and Java 17.

## Quality checks

From the repository root:

```bash
docker compose -f docker-compose.test.yml run --rm reminder-test
```

This runs:

- `flutter pub get`
- `flutter analyze`
- `flutter test`

## APK builds

Build debug and release APKs in the same container:

```bash
BUILD_APK=1 docker compose -f docker-compose.test.yml run --rm reminder-test
```

Artifacts are written to `container-artifacts/` on the host.

Build the image directly when preferred:

```bash
docker build -f Dockerfile.test -t reminder-app-test .
docker run --rm -e BUILD_APK=1 reminder-app-test
```

The image generates its own `reminder_demo/android/local.properties`; it does not depend on a host Flutter path.

## What this validates

The container validates Dart analysis, unit/widget tests, dependency resolution, and Android APK compilation. It is suitable for Codemagic-style repeatable checks.

It cannot prove microphone permissions, native notification delivery, exact alarms while the app is killed, lock-screen behavior, OEM battery restrictions, or iOS behavior. Those still require a physical Android device or emulator and macOS/Xcode for iOS.
