# Veil Run — Store Submission Checklist

## Google Play Data Safety Section (AdMob)
# Source: https://developers.google.com/admob/android/privacy/play-data-disclosure
#
# Declare these in Play Console → App Content → Data Safety:
#
# DATA COLLECTED:
#   ✅ Device identifiers → Advertising ID (Android Ad ID)
#   ✅ Device identifiers → App Set ID
#   ✅ Location → Approximate location (via IP address — NOT precise GPS)
#   ✅ App activity → App interactions (taps, launches, video views)
#   ✅ App performance → Crash logs, diagnostics
#
# DATA SHARED WITH THIRD PARTIES:
#   ✅ Google (AdMob / Google Play Services) — advertising purposes
#
# DATA SECURITY:
#   ✅ Data is encrypted in transit (TLS)
#   ✅ Users can request deletion (via Android Ad ID reset in Settings)

## App Store Privacy Nutrition Labels
# App Store Connect → App Privacy → Data Types Used:
#
#   Identifiers → Advertising Data → Used for Third-Party Advertising (AdMob)
#   Diagnostics → Crash Data (Firebase Crashlytics if used)
#   Location → Coarse Location (via IP — mark as NOT linked to user)

## Pre-Submission Steps

### Day 7 Morning (Both Platforms)
- [ ] Set is_test_mode = false in admob_manager.gd
- [ ] Set PROD_* ad unit IDs in admob_manager.gd
- [ ] Final build with release keystore (Android)
- [ ] Archive in Xcode (iOS)

### Google Play Console
1. [ ] Create app → Android
2. [ ] Upload VeilRun.aab (signed, API 35)
3. [ ] Fill store listing
   - Title: "Veil Run"
   - Short description (60 chars): "Shift dimensions. Survive."
   - Full description: see STORE_DESCRIPTIONS.md
4. [ ] Upload screenshots (1080×1920, min 2)
5. [ ] Upload feature graphic (1024×500)
6. [ ] Data safety form (see declarations above)
7. [ ] Content rating: complete IARC questionnaire
8. [ ] Privacy policy URL: add hosted URL
9. [ ] App access: all features accessible
10. [ ] Submit for review

### App Store Connect
1. [ ] New app → iOS
2. [ ] Bundle ID: com.voxduru.veilrun
3. [ ] Upload build via Xcode → Organizer → Distribute
4. [ ] Screenshots: 6.9" required (1320×2868 or 1290×2796)
5. [ ] Fill app information
   - Name: "Veil Run"
   - Subtitle: "Shift dimensions. Survive."
   - Keywords: endless runner, shadow, veil, neon, arcade, survive, dimension
6. [ ] Privacy policy URL
7. [ ] Age Rating: 4+
8. [ ] App Privacy → Data types (see above)
9. [ ] Submit for review

## Privacy Policy (Minimal Template)
Host at: https://berkeryaprak.github.io/veil-run-privacy or similar

Content:
  - App: Veil Run, developer: [Name], contact: [email]
  - Data collected: advertising identifier (via Google AdMob)
  - Purpose: personalized advertising to fund free app
  - Third parties: Google AdMob (https://policies.google.com/privacy)
  - Children: app not directed at children under 13
  - Opt-out: reset Advertising ID in Android/iOS settings
  - Last updated: [date]
