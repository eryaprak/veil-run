# Veil Run — Build & Release Guide

## VERIFIED REQUIREMENTS (as of May 2026)

### Android (Google Play)
- Target SDK: **API 35 (Android 15)** — mandatory from Aug 31 2025
- Min SDK: **24** (Android 7.0 — reaches ~99% of devices)
- Format: **AAB** (Android App Bundle) — required for Play Store
- Architecture: **arm64-v8a only** (64-bit mandatory)
- Custom Build: **enabled** (required for AdMob plugin)
- Source: https://developer.android.com/google/play/requirements/target-sdk

### iOS (App Store)
- Minimum iOS: **14.0** (set in export_presets.cfg)
- Xcode: **16+** required (Xcode 26 required from April 28, 2026)
- Apple Team ID: **WCVY2XHTVR** (already set in export_presets.cfg)
- Bundle ID: **com.voxduru.veilrun**
- Export method: App Store Connect (distribution)
- Source: https://developer.apple.com/news/upcoming-requirements/

---

## PREREQUISITES

### macOS Setup
```bash
# Already installed:
# - Godot 4.5 (use 4.5, NOT 4.6 — AdMob broken on 4.6)
# - Xcode 16+ with Command Line Tools

xcode-select --install
xcrun --version   # verify

# Android Studio (for SDK + keystore)
brew install --cask android-studio

# Java (for keytool)
brew install openjdk@21
echo 'export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Android SDK Setup (via Android Studio)
1. Open Android Studio → SDK Manager
2. Install:
   - **Android SDK Platform 35** (API 35)
   - **Android SDK Build-Tools 35.0.1**
   - **Android SDK Platform-Tools 35.0.0**
   - **NDK r28b** (28.1.13356709)
   - **CMake 3.10.2.4988404**
3. In Godot: Editor → Editor Settings → Export → Android
   - Set `Android Sdk Path` to your SDK location
     (usually: `~/Library/Android/sdk`)

---

## EXPORT TEMPLATES

### Download in Godot Editor
1. Editor menu → Export Templates
2. Download for **Godot 4.5** (match your engine version exactly)
3. Wait for download to complete (~500MB)

---

## ANDROID KEYSTORE

### Generate Release Keystore (one-time)
```bash
cd /Users/berkeryaprak/Projects/games/veil-run

keytool -genkey -v \
  -keystore veil-run-release.keystore \
  -alias veil-run \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Berko, OU=VoxDuru, O=VoxDuru, L=Istanbul, ST=Istanbul, C=TR"

# Enter a strong password — save it securely (1Password / Bitwarden)
# NEVER commit veil-run-release.keystore to git
```

### Set in export_presets.cfg
In Godot editor → Export → Android → Signing:
- Release keystore: `veil-run-release.keystore`
- Release keystore user: `veil-run`
- Release keystore password: your password

Or set directly in export_presets.cfg (use env vars for CI):
```
keystore/release="res://veil-run-release.keystore"
keystore/release_user="veil-run"
keystore/release_password="YOUR_PASSWORD"  # Never hardcode in repo
```

---

## ADMOB PLUGIN SETUP (Godot 4.5)

### Plugin: godot-sdk-integrations/godot-admob v5.3
```bash
# 1. Download plugin
cd /tmp
curl -L "https://github.com/godot-sdk-integrations/godot-admob/releases/download/v5.3.0/godot-admob-v5.3.0.zip" \
  -o godot-admob.zip
unzip godot-admob.zip -d godot-admob-extracted

# 2. Copy to project
cp -r godot-admob-extracted/addons/admob \
  /Users/berkeryaprak/Projects/games/veil-run/addons/

# 3. Enable in Godot Editor
# Project → Project Settings → Plugins → AdMob → Enable

# 4. Android custom build setup
# In Godot: Project → Install Android Build Template
# This creates android/ directory in project
# Then add to android/build/res/values/strings.xml:
# <string name="admob_app_id">ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

### AdMob App IDs (fill from AdMob Console)
```
Android App ID: ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
iOS App ID:     ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX

Rewarded Android Unit: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
Rewarded iOS Unit:     ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
```
Update `scripts/admob_manager.gd` PROD_* constants before release.
Set `is_test_mode = false` for production build.

### GDPR Consent (Required for EU/EEA users)
- AdMob UMP SDK is bundled with the plugin
- Call `UMPConsentForm.loadAndShowConsentFormIfRequired()` before MobileAds.initialize()
- Not calling this = potential policy violation and account suspension

---

## ANDROID EXPORT

### Steps
1. Open Godot → Project → Export → Android
2. Set keystore paths (see above)
3. Verify:
   - Use Custom Build: ✅ ON
   - Gradle Build: ✅ ON
   - Min SDK: 24
   - Target SDK: **35** (mandatory from Aug 2025)
   - Architecture: arm64-v8a only ✅
   - Export Format: AAB ✅
   - Internet permission: ✅ ON
4. Click "Export Project" → choose `.aab` output
5. Output: `builds/android/VeilRun.aab`

### Upload to Google Play
1. Play Console → Create app → Android app
2. Production → Create new release
3. Upload `VeilRun.aab`
4. Fill store listing (see checklist below)
5. Content rating: complete questionnaire (game → no violence)
6. Privacy policy URL: required (see Privacy section below)
7. App access: no special permissions needed
8. Submit for review

---

## iOS EXPORT

### Steps
1. Open Godot → Project → Export → iOS
2. Verify:
   - Team ID: `WCVY2XHTVR` ✅
   - Bundle ID: `com.voxduru.veilrun` ✅
   - Min iOS: 14.0 ✅
   - Export method: App Store Connect
3. Click "Export Project" → produces `.xcodeproj`
4. Output: `builds/ios/VeilRun.xcodeproj`

### Xcode Steps
```bash
open builds/ios/VeilRun.xcodeproj
```
In Xcode:
1. Select "VeilRun" target → Signing & Capabilities
2. Team: WCVY2XHTVR → Auto-managed signing
3. Bundle Identifier: `com.voxduru.veilrun`
4. Build destination: "Any iOS Device (arm64)"
5. Product → Archive
6. Organizer → Distribute App → App Store Connect → Upload

### AdMob iOS Info.plist (REQUIRED)
Add to `ios/Info.plist` (Xcode target → Info tab):
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

### App Tracking Transparency (ATT) — iOS 14+
AdMob plugin handles ATT request automatically.
Add to Info.plist:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to show personalized ads.</string>
```

---

## STORE LISTING

### App Store Connect
- Name: **Veil Run** (30 chars max)
- Subtitle: **Shift dimensions. Survive.** (30 chars max)
- Category: **Games → Action**
- Age Rating: **4+** (no violence/mature content)
- Screenshots required:
  - iPhone 6.9" (1320×2868 or 1290×2796) — **mandatory**
  - iPhone 6.5" (1242×2688) — optional but recommended
  - iPad Pro 12.9" (2048×2732) — if iPad supported
- Preview video: 15-30s, MP4 (optional but increases conversion)
- Privacy Policy URL: **required**
- Keywords (100 chars): endless runner, shadow, dimension, veil, neon, run, arcade, survival

### Google Play Console
- Short description: **60 chars** — "Shift between dimensions. Run. Survive."
- Full description: **4000 chars** max
- Feature graphic: 1024×500 PNG/JPG
- Screenshots: minimum 2, max 8
  - Phone: 1080×1920 PNG/JPG
  - 7" tablet: optional
  - 10" tablet: optional
- Content rating: complete IARC questionnaire
- Privacy policy URL: **required**
- Data safety section: declare AdMob data collection

---

## PRIVACY POLICY

**Required by both stores and AdMob.**

Minimum content:
- App name and developer contact
- What data is collected (AdMob: advertising ID, device info)
- Third parties (Google AdMob)
- Children: not directed at children under 13
- Contact email

Free generator: https://app-privacy-policy-generator.firebaseapp.com/
Host on: GitHub Pages, Notion, or any public URL

---

## SCREENSHOT SIZES (Quick Reference)

| Platform | Size | Required |
|----------|------|----------|
| iPhone 6.9" | 1320×2868 px | **YES** (App Store) |
| iPhone 6.5" | 1242×2688 px | Recommended |
| Android Phone | 1080×1920 px | **YES** (Play Store) |
| Feature Graphic | 1024×500 px | **YES** (Play Store) |

### Screenshot Tips
- Use Godot's built-in screenshot: `get_viewport().get_texture().get_image()`
- Or run on device/simulator and screenshot
- Add frame overlay with device mockup (Canva, AppMockUp)
- Show Veil Shift moment, neon particles, coin collection

---

## CHECKLIST: PRE-SUBMISSION

### Both Platforms
- [ ] Test on real device (not just simulator)
- [ ] Test cold start (no cached data)
- [ ] Test rewarded ads load and reward correctly
- [ ] Test game over → continue → run resumes
- [ ] Test coin persistence across sessions
- [ ] Crash-free rate target: ≥ 99%
- [ ] AdMob test mode: **OFF** for production build
- [ ] Privacy policy URL: published and accessible

### Android Only
- [ ] AAB signed with release keystore
- [ ] Target SDK = 35
- [ ] arm64-v8a only (no 32-bit)
- [ ] Custom build with AdMob plugin included
- [ ] Data safety form filled in Play Console
- [ ] strings.xml has production AdMob App ID

### iOS Only
- [ ] Archive built in Xcode (not debug)
- [ ] Distribution certificate valid
- [ ] Provisioning profile: App Store
- [ ] Info.plist has GADApplicationIdentifier (production ID)
- [ ] Info.plist has NSUserTrackingUsageDescription
- [ ] No private APIs used

---

## ADMOB ACCOUNT SETUP

1. Create AdMob account: https://admob.google.com
2. Add app (Android + iOS separately)
3. Create ad unit: Rewarded → name "Continue Run"
4. Create ad unit: Rewarded → name "2x Coins"
5. Copy App IDs and Ad Unit IDs → update admob_manager.gd PROD_* constants
6. Link AdMob to Google Play app (for better targeting)
7. Enable mediation later (AppLovin, IronSource) for higher eCPM

---

## ENVIRONMENT VARIABLES (CI/CD)

For automated builds, use env vars instead of hardcoded values:
```bash
export ADMOB_APP_ID_ANDROID="ca-app-pub-..."
export ADMOB_APP_ID_IOS="ca-app-pub-..."
export ADMOB_REWARDED_ANDROID="ca-app-pub-..."
export ADMOB_REWARDED_IOS="ca-app-pub-..."
export KEYSTORE_PASSWORD="..."
```

Then in a build script, substitute into export_presets.cfg before building.

---

## QUICK BUILD COMMANDS

```bash
# Android AAB (requires Godot CLI + export templates installed)
godot --headless --export-release "Android" ../builds/android/VeilRun.aab

# iOS .xcodeproj (then open in Xcode for archive + upload)
godot --headless --export-release "iOS" ../builds/ios/VeilRun.xcodeproj

# Create builds directory
mkdir -p ../builds/android ../builds/ios
```

---

## TIMELINE (7-Day Sprint)

| Day | Task | Status |
|-----|------|--------|
| 1-2 | Core mechanics (player, track, Veil Shift) | ✅ Done |
| 3-4 | Visual polish + meta layer + audio | ✅ Done |
| 5   | AdMob integration + plugin install | 🚧 In Progress |
| 6   | iOS + Android build + device test | ⏳ |
| 7   | Store submission | ⏳ |
