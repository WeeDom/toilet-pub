#!/usr/bin/env bash
#
# setup-arm.sh — Guard-e-Loo Raspberry Pi environment setup helper
# Enables ARM emulation, verifies Docker & camera connectivity, and checks video device info.
#

set -e

echo "🔧 [Guard-e-Loo Setup] Initializing environment..."
echo

# --- 1️⃣ Ensure Docker is running ---
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker Desktop or your Docker daemon."
  exit 1
fi

# --- 2️⃣ Register QEMU for ARM/ARM64 ---
echo "⚙️  Registering QEMU multi-architecture support..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes >/dev/null
echo "✅ QEMU emulators registered."

if ls /proc/sys/fs/binfmt_misc/qemu-* >/dev/null 2>&1; then
  echo "🔍 Available QEMU emulators:"
  ls /proc/sys/fs/binfmt_misc/qemu-* | sed 's/^/   • /'
else
  echo "⚠️  No QEMU emulators detected — please rerun this script as sudo."
fi
echo

# --- 3️⃣ Verify ARM emulation works ---
echo "🧪 Testing ARM64 emulation..."
docker run --rm --platform linux/arm64 arm64v8/ubuntu uname -m || {
  echo "❌ ARM64 emulation test failed!"
  exit 1
}
echo "✅ ARM64 emulation operational."
echo

# --- 4️⃣ Camera device detection ---
echo "🎥 Checking for camera device..."
if [ -e /dev/video0 ]; then
  echo "✅ Found camera device at /dev/video0"
  ls -l /dev/video0 | sed 's/^/   /'
  echo

  # --- 5️⃣ Check v4l2 device info ---
  if command -v v4l2-ctl >/dev/null 2>&1; then
    echo "🔍 Querying camera information (v4l2-ctl)..."
    sudo v4l2-ctl --all --device=/dev/video0 | sed 's/^/   /'
  else
    echo "⚠️  v4l2-ctl not found on host."
    echo "   You can install it with: sudo apt install v4l-utils"
    echo "   Once installed, rerun this script to see camera capabilities."
  fi
else
  echo "⚠️  No camera detected at /dev/video0."
  echo "   • If using a laptop webcam, ensure it’s not locked by another app."
  echo "   • If using a USB cam, replug it and run: sudo modprobe v4l2loopback"
fi
echo

# --- 6️⃣ Docker permission sanity check ---
echo "👥 Checking Docker group membership..."
if id -nG "$USER" | grep -qw docker; then
  echo "✅ User '$USER' is in the 'docker' group."
else
  echo "⚠️  User '$USER' is NOT in the 'docker' group."
  echo "   Run: sudo usermod -aG docker $USER"
  echo "   Then log out and back in."
fi
echo

# --- 7️⃣ Summary ---
echo "🎯 Setup complete!"
echo "You can now build and run your Raspberry Pi environment with:"
echo
echo "   docker compose build --no-cache"
echo "   docker compose up"
echo
echo "✅ Guard-e-Loo ARM & camera environment ready!"
