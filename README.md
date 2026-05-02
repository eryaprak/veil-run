# Veil Run 🌙☀️

**A mystical endless runner where shadows and light collide**

Solo indie game | Godot 4.6 | iOS + Android | Rewarded ads monetization

---

## 🎮 Game Concept

**Veil Run** is an endless runner with a unique dimension-shifting mechanic. Players control Zara, a shadow hunter navigating through mystical corridors where two dimensions (Light and Shadow) coexist.

### Core Mechanic: Veil Shift
- Switch between **Light** and **Shadow** dimensions
- Obstacles exist in both planes but at different positions
- Power-ups and coins are dimension-specific
- Strategic dimension switching is key to survival

### Unique Selling Points
1. **2.5D Silhouette + Neon Glow aesthetic** — visually striking, low poly count
2. **Middle East mythology-inspired** — appeals to both Western and MENA markets
3. **Dimension-switching twist** — not just another Temple Run clone
4. **Rewarded ads as power-ups** — optional, player-friendly monetization

---

## 🛠️ Tech Stack

- **Engine:** Godot 4.6.2 (GDScript)
- **Platforms:** iOS (App Store: WCVY2XHTVR) + Android (Google Play: 5027337559639862807)
- **Ads:** AdMob (godot-admob plugin) or AppLovin MAX
- **Backend:** Firebase (Analytics, Crashlytics, Leaderboard)
- **Art:** Silhouette sprites + procedural neon glow shaders

---

## 📁 Project Structure

```
veil-run/
├── project.godot           # Godot project config
├── scenes/
│   └── main.tscn           # Main game scene
├── scripts/
│   ├── main.gd             # Game orchestrator
│   ├── player.gd           # Player controller + Veil Shift
│   ├── track_manager.gd    # Procedural track generation
│   └── ui.gd               # UI controller
├── assets/
│   ├── textures/
│   ├── sounds/
│   └── shaders/
└── addons/                 # Third-party plugins (AdMob, Firebase)
```

---

## 🎯 MVP Features (7-Day Sprint)

### Day 1-2: Core Mechanics ✅
- [x] Godot 4 project setup
- [x] Player movement (3 lanes)
- [x] Veil Shift dimension switching
- [x] Procedural track generation
- [x] Basic obstacle system
- [x] Coin collection

### Day 3-4: Visual Polish + Meta Layer
- [ ] Neon glow shader (post-processing)
- [ ] 3 costumes (1 free, 2 unlockable)
- [ ] Silhouette sprites for player + obstacles
- [ ] Particle effects (Veil Shift, coin collection)
- [ ] Background music + SFX
- [ ] Meta progression (coins → costumes)

### Day 5: Monetization
- [ ] AdMob integration (godot-admob)
- [ ] Rewarded ads: "Continue Run"
- [ ] Rewarded ads: "2x Coins"
- [ ] Rewarded ads: "Daily Bonus 3x"
- [ ] Firebase Analytics + Crashlytics

### Day 6: Build + Test
- [ ] iOS export template + build
- [ ] Android export template + build
- [ ] TestFlight beta (iOS)
- [ ] Internal Testing track (Android)
- [ ] Bug fixes + crash-free %99+ target

### Day 7: Store Submission
- [ ] App Store Connect submission
- [ ] Google Play Console submission
- [ ] ASO (App Store Optimization)
- [ ] Screenshots + preview video
- [ ] Privacy Policy + Terms

---

## 🎮 Controls

### Desktop (Testing)
- **A / Left Arrow:** Move left
- **D / Right Arrow:** Move right
- **Space / Click:** Jump
- **W / Up Arrow:** Veil Shift (dimension switch)

### Mobile
- **Swipe Left/Right:** Change lane
- **Tap:** Jump
- **Swipe Up:** Veil Shift

---

## 💰 Monetization Strategy

### Rewarded Ads (Primary)
Following market research data (see `/game-research/market-analysis-report.md`):
- **eCPM target:** $16–20 (US iOS, rewarded video)
- **Opt-in target:** 60–80%
- **ARPDAU target:** $0.06–$0.15 (endless runner category)

### Ad Placements
1. **"Continue Run" (post-death):** 2 chances per run, highest opt-in
2. **"2x Coins" (run end):** Multiplies session coins
3. **"Daily Bonus 3x" (login):** Encourages daily habit
4. **Checkpoint rewards:** Optional boost offers

### IAP (Secondary, v1.1+)
- Costume packs
- Ad removal (optional, not pushed)
- Coin bundles

---

## 📊 Success Metrics (DoD)

| Metric | Target |
|--------|--------|
| D1 retention | ≥ 30% |
| D7 retention | ≥ 15% |
| Rewarded ad opt-in ("continue") | ≥ 60% |
| Rewarded ad opt-in ("2x coins") | ≥ 45% |
| ARPDAU (first month, low DAU) | ≥ $0.04 |
| Crash-free rate | ≥ 99% |
| App Store rating (target) | ≥ 4.2 |

---

## 🚀 Development Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| **Setup + Core Mechanics** | Day 1-2 | 🚧 In Progress |
| **Visual + Meta** | Day 3-4 | ⏳ Pending |
| **Ads + Backend** | Day 5 | ⏳ Pending |
| **Build + Test** | Day 6 | ⏳ Pending |
| **Store Submission** | Day 7 | ⏳ Pending |

---

## 🧪 Testing

### Local Testing
```bash
# Open project in Godot editor
godot project.godot

# Or run directly (headless mode for server testing)
godot --headless
```

### Mobile Testing
- iOS: TestFlight (requires Apple Developer account)
- Android: Internal Testing track (Google Play Console)

---

## 📝 Notes

- **No Unity Asset Store templates** — custom-built for flexibility
- **Godot 4 export templates** — download via Godot editor (Project > Export)
- **AdMob test IDs** — use test ad unit IDs until production
- **iOS ATT (App Tracking Transparency)** — handled by AdMob plugin
- **GDPR consent** — required for EU users (AdMob CMP)

---

## 👤 Developer

**Berko** (Solo dev + AI)
- Apple Developer: WCVY2XHTVR
- Google Play: 5027337559639862807
- Experience: Expo/EAS, mobile dev

---

## 📄 License

Proprietary — All rights reserved.
Code for portfolio/demo purposes only.
