#!/bin/bash
# setup_admob.sh — Downloads and configures godot-admob plugin
# Run from: /Users/berkeryaprak/Projects/games/veil-run
# Requires: git, internet connection

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADDONS_DIR="$PROJECT_DIR/addons"

echo "=== Veil Run AdMob Setup ==="
echo "Project: $PROJECT_DIR"

# Step 1: Clone plugin
if [ ! -d "$ADDONS_DIR/admob" ]; then
  echo "[1/4] Cloning godot-admob plugin..."
  cd "$ADDONS_DIR"
  git clone --depth=1 https://github.com/godot-sdk-integrations/godot-admob.git admob
  echo "  Plugin cloned."
else
  echo "[1/4] admob plugin already exists, skipping clone."
fi

# Step 2: Check plugin.cfg
if [ -f "$ADDONS_DIR/admob/plugin.cfg" ]; then
  echo "[2/4] plugin.cfg found."
else
  echo "[2/4] WARNING: plugin.cfg not found. Check plugin structure."
fi

# Step 3: Remind about enabling in editor
echo ""
echo "[3/4] MANUAL STEP REQUIRED:"
echo "  Open Godot editor with this project."
echo "  Go to: Project → Project Settings → Plugins"
echo "  Enable: AdMob"
echo ""

# Step 4: Remind about AndroidManifest and Info.plist
echo "[4/4] Post-install reminders:"
echo "  Android: Add to android/build/AndroidManifest.xml:"
echo "    <meta-data android:name='com.google.android.gms.ads.APPLICATION_ID'"
echo "               android:value='ca-app-pub-3940256099942544~3347511713'/>"
echo ""
echo "  iOS: Add to exported Xcode project Info.plist:"
echo "    GADApplicationIdentifier = ca-app-pub-3940256099942544~1458002511"
echo "    (See BUILD_GUIDE.md for full XML snippet)"
echo ""
echo "=== Setup complete. Use TEST IDs until ready for release. ==="
