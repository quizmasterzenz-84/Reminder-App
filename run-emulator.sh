#!/usr/bin/env bash
# Boots a headless, hardware-accelerated Android emulator in a container and
# installs the most recently built debug APK from container-artifacts/.
# Requires only Docker + /dev/kvm on the host.
set -euo pipefail
cd "$(dirname "$0")"

docker compose -f docker-compose.test.yml build emulator
docker compose -f docker-compose.test.yml up emulator
