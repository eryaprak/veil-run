extends Node
class_name AdMobManager

# AdMob integration for Veil Run
# Plugin: godot-sdk-integrations/godot-admob v6.0 (Godot 4.6 compatible)
# API source: https://godot-sdk-integrations.github.io/godot-admob/
#
# USAGE:
#   Add this node to your main scene (autoload or scene child).
#   It will try to find an Admob child node (the plugin's scene node).
#   If the plugin is not installed / not on device, it falls back to mock mode.
#
# SCENE SETUP:
#   In main.tscn, add an Admob node as child of this node (or the root scene).
#   The Admob node is provided by the AdmobPlugin addon (addons/AdmobPlugin/Admob.gd).

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

var _admob: Node = null   # The Admob plugin node (v6)
var _rewarded_loaded  := false
var _pending_reward_type := ""
var _plugin_available := false

func _ready() -> void:
	_init_admob()

# ─────────────────────────────────────────────────────────────────
# Initialization
# ─────────────────────────────────────────────────────────────────
func _init_admob() -> void:
	# Try to find Admob node (v6 plugin node-based approach)
	_admob = _find_admob_node()

	if _admob == null:
		push_warning("[AdMob] Admob node not found → mock mode (editor/no plugin)")
		_plugin_available = false
		_rewarded_loaded = true  # In mock mode always "ready"
		return

	_plugin_available = true

	# Connect v6 signals
	_admob.initialization_completed.connect(_on_initialization_completed)
	_admob.rewarded_ad_loaded.connect(_on_rewarded_loaded)
	_admob.rewarded_ad_failed_to_load.connect(_on_rewarded_failed_to_load)
	_admob.rewarded_ad_user_earned_reward.connect(_on_rewarded_earned)
	_admob.rewarded_ad_dismissed_full_screen_content.connect(_on_rewarded_dismissed)
	_admob.rewarded_ad_failed_to_show_full_screen_content.connect(_on_rewarded_show_failed)

	# v6: set is_real flag before initialize()
	_admob.is_real = not is_test_mode

	_admob.initialize()
	print("[AdMob] SDK initializing (is_real=%s)" % str(not is_test_mode))

func _find_admob_node() -> Node:
	# Search siblings or children for an Admob node
	var admob = get_node_or_null("Admob")
	if admob:
		return admob
	# Try parent's child
	if get_parent():
		admob = get_parent().get_node_or_null("Admob")
		if admob:
			return admob
	# ClassDB check (shouldn't be needed for v6 node approach but as fallback)
	if ClassDB.class_exists("Admob"):
		var node = ClassDB.instantiate("Admob")
		add_child(node)
		return node
	return null

# ─────────────────────────────────────────────────────────────────
# Signal handlers
# ─────────────────────────────────────────────────────────────────
func _on_initialization_completed(_status: Variant) -> void:
	print("[AdMob] Initialization complete")
	_load_rewarded_ad()

func _on_rewarded_loaded(_ad_info: Variant, _response_info: Variant) -> void:
	_rewarded_loaded = true
	print("[AdMob] Rewarded ad loaded ✓")
	rewarded_ad_loaded.emit()

func _on_rewarded_failed_to_load(_ad_info: Variant, error: Variant) -> void:
	_rewarded_loaded = false
	push_warning("[AdMob] Rewarded load failed — retrying in 30s")
	await get_tree().create_timer(30.0).timeout
	_load_rewarded_ad()

func _on_rewarded_earned(_ad_info: Variant, _reward_data: Variant) -> void:
	print("[AdMob] Reward earned for '%s'" % _pending_reward_type)
	rewarded_ad_earned.emit(_pending_reward_type)
	_pending_reward_type = ""

func _on_rewarded_dismissed(_ad_info: Variant) -> void:
	print("[AdMob] Rewarded ad dismissed — reloading")
	_rewarded_loaded = false
	_load_rewarded_ad()

func _on_rewarded_show_failed(_ad_info: Variant, _error: Variant) -> void:
	push_warning("[AdMob] Rewarded show failed")
	rewarded_ad_failed.emit(_pending_reward_type)
	_pending_reward_type = ""
	_rewarded_loaded = false
	_load_rewarded_ad()

# ─────────────────────────────────────────────────────────────────
# Load rewarded ad (v6 API)
# ─────────────────────────────────────────────────────────────────
func _load_rewarded_ad() -> void:
	if not _plugin_available or _admob == null:
		return

	_rewarded_loaded = false
	var unit_id := _get_rewarded_unit_id()

	var request := LoadAdRequest.new()
	request.set_ad_unit_id(unit_id)

	_admob.load_rewarded_ad(request)
	print("[AdMob] Requesting rewarded ad unit: ", unit_id)

# ─────────────────────────────────────────────────────────────────
# Show rewarded ad (v6 API)
# ─────────────────────────────────────────────────────────────────
func show_rewarded_ad(reward_type: String) -> bool:
	_pending_reward_type = reward_type

	# Mock mode — simulate grant in editor
	if not _plugin_available:
		print("[AdMob] Mock: granting reward for '%s' in 1s" % reward_type)
		_mock_grant_reward()
		return true

	if not _rewarded_loaded or _admob == null:
		push_warning("[AdMob] Rewarded ad not ready")
		rewarded_ad_failed.emit(reward_type)
		return false

	_admob.show_rewarded_ad()
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
