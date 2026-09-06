#!/usr/bin/env bash
set -euo pipefail

cd /workspace/reminder_demo

flutter pub get
flutter analyze
flutter test

if [[ "${BUILD_APK:-0}" == "1" ]]; then
  export GRADLE_OPTS="-Xmx1536M -XX:MaxMetaspaceSize=384M"
  # Container hosts (e.g. small Codespaces) are often 2-core/low-memory, so
  # keep the daemon off and work single-threaded to avoid OOM kills.
  sed -i \
    's/^org.gradle.jvmargs=.*/org.gradle.jvmargs=-Xmx1536M -XX:MaxMetaspaceSize=384M -XX:+HeapDumpOnOutOfMemoryError/' \
    android/gradle.properties
  sed -i 's/^org.gradle.daemon=.*/org.gradle.daemon=false/' android/gradle.properties
  if ! grep -q '^org.gradle.workers.max=' android/gradle.properties; then
    echo 'org.gradle.workers.max=1' >> android/gradle.properties
  fi
  if ! grep -q '^kotlin.daemon.jvm.options=' android/gradle.properties; then
    echo 'kotlin.daemon.jvm.options=-Xmx768M' >> android/gradle.properties
  fi
  flutter build apk --debug --android-skip-build-dependency-validation
  flutter build apk --release --android-skip-build-dependency-validation
fi
