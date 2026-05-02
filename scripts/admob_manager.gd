extends Node
class_name AdMobManager

# AdMob integration for Veil Run
# Plugin: godot-sdk-integrations/godot-admob (Godot 4.5 compatible)
#
# VERIFIED API SOURCE:
#   https://poingstudios.github.io/godot-admob-plugin/stable/ad_formats/rewarded/
# KNOWN ISSUE:
#   Poing Studios plugin is broken on Godot 4.6 (Issue #270, archived March 2026).
#   Use Godot 4.5 with godot-sdk-integrations/godot-admob v5.3.
#
# INSTALL STEPS:
#   1. Download: https://github.com/godot-sdk-integrations/godot-admob/releases/tag/v5.3
#   2. Extract → copy addons/admob → res://addons/admob
#   3. Project → Project Settings → Plugins → Enable "AdMob"
#   4. Android: Editor → Export → Android → check "Use Custom Build"
#              Add to android/build/res/values/strings.xml:
#              <string name="admob_app_id">YOUR_ANDROID_APP_ID</string>
#   5. iOS:    Add GADApplicationIdentifier to exported Info.plist
#   6. GDPR:   Implement UMP consent form (required for EU users)

signal rewarded_ad_earned(reward_type: String)
signal rewarded_ad_failed(reward_type: String)
signal rewarded_ad_loaded

# ── Public Google Test Ad Unit IDs (safe to commit, never earn real money) ──
const TEST_APP_ID_ANDROID   := "ca-app-pub-3940256099942544~3347511713"
const TEST_APP_ID_IOS       := "ca-app-pub-3940256099942544~1458002511"
const TEST_REWARDED_ANDROID := "ca-app-pub-3940256099942544/5224354917"
const TEST_REWARDED_IOS     := "ca-app-pub-3940256099942544/1712485313"

# ── Production IDs — set via AdMob Console before release ──
const PROD_APP_ID_ANDROID   := ""  # App ID (tilde ~)
const PROD_APP_ID_IOS       := ""
const PROD_REWARDED_ANDROID := ""  # Ad Unit ID (slash /)
const PROD_REWARDED_IOS     := ""

var is_test_mode := true  # Switch to false for production build

# Internal state
var _rewarded_ad = null       # Holds loaded RewardedAd object
var _rewarded_loaded  := false
var _pending_reward_type := ""
var _plugin_available := false

func _ready() -> void:
	_init_admob()

# ─────────────────────────────────────────────────────────────────
# Initialization
# ─────────────────────────────────────────────────────────────────
func _init_admob() -> void:
	# ClassDB check: MobileAds class only exists when plugin is installed + enabled
	_plugin_available = ClassDB.class_exists("MobileAds")

	if not _plugin_available:
		push_warning("[AdMob] MobileAds class not found → mock mode (editor/simulator)")
		_rewarded_loaded = true  # In mock mode always "ready"
		return

	# VERIFIED: MobileAds.initialize() — no arguments, async init
	MobileAds.initialize()
	print("[AdMob] SDK initialized")
	_load_rewarded_ad()

# ─────────────────────────────────────────────────────────────────
# Load rewarded ad
# VERIFIED API: RewardedAdLoader.new().load(unit_id, AdRequest, callback)
# ─────────────────────────────────────────────────────────────────
func _load_rewarded_ad() -> void:
	if not _plugin_available:
		return

	_rewarded_loaded = false
	var unit_id := _get_rewarded_unit_id()

	# RewardedAdLoadCallback: two function properties, not signals
	var load_callback := RewardedAdLoadCallback.new()

	load_callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_ad    = ad
		_rewarded_loaded = true
		print("[AdMob] Rewarded ad loaded ✓")
		rewarded_ad_loaded.emit()

	load_callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_rewarded_loaded = false
		push_warning("[AdMob] Load failed: " + error.message)
		# Standard retry: 30 s backoff
		await get_tree().create_timer(30.0).timeout
		_load_rewarded_ad()

	RewardedAdLoader.new().load(unit_id, AdRequest.new(), load_callback)
	print("[AdMob] Requesting rewarded ad unit: ", unit_id)

# ─────────────────────────────────────────────────────────────────
# Show rewarded ad
# VERIFIED API: _rewarded_ad.show(OnUserEarnedRewardListener)
#               FullScreenContentCallback for dismiss/fail events
# ─────────────────────────────────────────────────────────────────
func show_rewarded_ad(reward_type: String) -> bool:
	_pending_reward_type = reward_type

	# Mock mode — simulate grant in editor
	if not _plugin_available:
		print("[AdMob] Mock: granting reward for '%s' in 1 s" % reward_type)
		_mock_grant_reward()
		return true

	if not _rewarded_loaded or _rewarded_ad == null:
		push_warning("[AdMob] Rewarded ad not ready")
		rewarded_ad_failed.emit(reward_type)
		return false

	# FullScreenContentCallback: lifecycle events (dismiss, show fail)
	var content_cb := FullScreenContentCallback.new()

	content_cb.on_ad_dismissed_full_screen_content = func() -> void:
		print("[AdMob] Ad dismissed — reloading")
		_rewarded_ad.destroy()
		_rewarded_ad    = null
		_rewarded_loaded = false
		_load_rewarded_ad()

	content_cb.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		push_warning("[AdMob] Show failed: " + error.message)
		rewarded_ad_failed.emit(_pending_reward_type)
		_pending_reward_type = ""
		_rewarded_ad.destroy()
		_rewarded_ad    = null
		_rewarded_loaded = false
		_load_rewarded_ad()

	_rewarded_ad.full_screen_content_callback = content_cb

	# OnUserEarnedRewardListener: fires when user completes the ad
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(reward: RewardItem) -> void:
		print("[AdMob] Reward earned → type=%s amount=%s  reward_type='%s'" % [
			reward.type, str(reward.amount), _pending_reward_type])
		rewarded_ad_earned.emit(_pending_reward_type)
		_pending_reward_type = ""

	_rewarded_ad.show(reward_listener)
	return true

# ─────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────
func _get_rewarded_unit_id() -> String:
	if is_test_mode:
		return TEST_REWARDED_IOS if OS.get_name() == "iOS" else TEST_REWARDED_ANDROID
	return PROD_REWARDED_IOS if OS.get_name() == "iOS" else PROD_REWARDED_ANDROID

func _mock_grant_reward() -> void:
	await get_tree().create_timer(1.0).timeout
	rewarded_ad_earned.emit(_pending_reward_type)
	_pending_reward_type = ""

func is_rewarded_ready() -> bool:
	if not _plugin_available:
		return true  # Mock always ready
	return _rewarded_loaded
