#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_DIR=/artifacts
APK_PATH="${ARTIFACT_DIR}/app-debug.apk"
PACKAGE_ID="com.example.reminder_demo"
ACTIVITY=".MainActivity"

echo "Starting adb server..."
adb start-server

echo "Booting emulator (headless, software rendering)..."
emulator @test \
  -no-window \
  -no-audio \
  -no-boot-anim \
  -gpu swiftshader_indirect \
  -no-snapshot \
  -accel auto \
  -verbose &
EMULATOR_PID=$!

echo "Waiting for device..."
adb wait-for-device

echo "Waiting for boot to complete..."
until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
  sleep 2
done
echo "Emulator booted."

if [[ -f "${APK_PATH}" ]]; then
  echo "Installing ${APK_PATH}..."
  adb install -r "${APK_PATH}"
  echo "Launching ${PACKAGE_ID}${ACTIVITY}..."
  adb shell am start -n "${PACKAGE_ID}/${ACTIVITY}"
else
  echo "No APK found at ${APK_PATH} yet — emulator is running without installing an app."
  echo "Build one first, then: docker compose -f docker-compose.test.yml exec emulator adb install -r ${APK_PATH}"
fi

echo "Emulator ready. Use 'docker compose -f docker-compose.test.yml exec emulator adb <command>' to interact."
wait "${EMULATOR_PID}"
