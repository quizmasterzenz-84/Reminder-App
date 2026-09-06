#!/usr/bin/env bash
# Builds debug + release APKs entirely inside the container image.
# Requires only Docker on the host — no local Flutter/Android SDK install.
# Output: container-artifacts/*.apk
set -euo pipefail
cd "$(dirname "$0")"

docker compose -f docker-compose.test.yml build reminder-test
BUILD_APK=1 docker compose -f docker-compose.test.yml run --rm reminder-test

echo
echo "APKs ready in: $(pwd)/container-artifacts"
ls -la container-artifacts/*.apk 2>/dev/null || true
