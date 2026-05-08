extends RefCounted
class_name MetaProgression

## XP / leveling; meta perk picks. New game → call reset().

enum PerkId {
	FIREWALL,
	ANTIVIRUS,
	BOOSTERS,
	BIOS_SAFE_MODE,
	REVERSE_ENGINEERING,
	REBOUND,
	PATIENCE,
	LATENCY_KILLER,
	ZERO_DAY_CATCHER,
	DECRYPTION,
	JAMMER,
	REDUNDANCY,
	HEAT_MAP,
	STALLER,
	ADDITIONAL_CORE,
}

enum Rarity { COMMON, RARE, LEGENDARY, MYTHICAL }

const RARITY_WEIGHTS: Array[int] = [100, 35, 10, 2]

## Per rarity bands per perk index (Common=0 … Mythical=3).
const _PERK_R_MIN: Array[int] = [0, 0, 0, 2, 1, 3, 1, 0, 1, 1, 2, 0, 1, 2, 3]
const _PERK_R_MAX: Array[int] = [3, 3, 3, 2, 3, 3, 1, 1, 1, 3, 2, 2, 1, 2, 3]

## Stack caps (-1 = infinite). BIOS, Rebound, Zero-Day: one-time.
const _PERK_STACK_LIMIT: Array[int] = [-1, -1, -1, 1, -1, 1, 3, -1, 1, -1, 5, -1, 1, 3, 1]

const PERK_TITLE: Array[String] = [
	"Firewall",
	"Anti-virus",
	"Boosters",
	"BIOS Safe Mode",
	"Reverse-Engineering",
	"Rebound",
	"Patience",
	"Latency Killer",
	"Zero-Day Catcher",
	"Decryption",
	"Jammer",
	"Redundancy",
	"Heat Map",
	"Staller",
	"Additional Core",
]

const RARITY_DISPLAY_NAME: Array[String] = ["Common", "Rare", "Legendary", "Mythical"]

var player_level: int = 0
var xp: float = 0.0
var xp_to_next_level: float = 100.0
var requirement_growth: float = 1.15

var total_hp_bonus: float = 0.0
var total_damage_bonus: float = 0.0
var total_perk_duration_bonus: float = 0.0
var bios_unlocked: bool = false
var rebound_unlocked: bool = false
var zero_day_catcher_unlocked: bool = false
var total_bullet_speed_bonus: float = 0.0
var total_weapon_pickup_chance_bonus: float = 0.0
var total_heal_pickup_bonus: float = 0.0
var heat_map_unlocked: bool = false
var staller_extend_chance: float = 0.0
var additional_core_unlocked: bool = false
var additional_core_damage_mult: float = 1.0
var _reverse_p_layers: Array[float] = []

## Records for game-over UI: duplicate of picks with titles.
var pick_history: Array[Dictionary] = []

var _pick_counts: Dictionary = {}


func _variant_to_int(v: Variant, fallback: int = 0) -> int:
	if v is int:
		return v as int
	if v is float:
		return int(v as float)
	if v is bool:
		return 1 if (v as bool) else 0
	return fallback


func reset() -> void:
	player_level = 0
	xp = 0.0
	xp_to_next_level = 100.0
	requirement_growth = 1.15
	total_hp_bonus = 0.0
	total_damage_bonus = 0.0
	total_perk_duration_bonus = 0.0
	bios_unlocked = false
	rebound_unlocked = false
	zero_day_catcher_unlocked = false
	total_bullet_speed_bonus = 0.0
	total_weapon_pickup_chance_bonus = 0.0
	total_heal_pickup_bonus = 0.0
	heat_map_unlocked = false
	staller_extend_chance = 0.0
	additional_core_unlocked = false
	additional_core_damage_mult = 1.0
	_reverse_p_layers.clear()
	pick_history.clear()
	_pick_counts.clear()


func add_xp(amount: float) -> void:
	if amount <= 0.0:
		return
	xp += amount


func can_level_up() -> bool:
	return xp >= xp_to_next_level - 0.001


func consume_level_up() -> void:
	xp = maxf(0.0, xp - xp_to_next_level)
	xp_to_next_level *= requirement_growth
	player_level += 1


## How many meta level-ups can still be resolved with current XP (includes chained overspill).
func queued_meta_level_up_count() -> int:
	var cx: float = xp
	var cneed: float = xp_to_next_level
	var cgrowth: float = requirement_growth
	var n: int = 0
	while cx >= cneed - 0.001:
		n += 1
		cx = maxf(0.0, cx - cneed)
		cneed *= cgrowth
	return n


func get_chain_explosion_chance() -> float:
	if _reverse_p_layers.is_empty():
		return 0.0
	var prod: float = 1.0
	for p in _reverse_p_layers:
		prod *= (1.0 - clampf(p, 0.0, 0.999))
	return 1.0 - prod


## Vertical pickup drift scales by 0.75^stacks (25%% slower per Patience stack).
func get_pickup_fall_speed_scale() -> float:
	var stacks: int = _pick_count(int(PerkId.PATIENCE))
	if stacks <= 0:
		return 1.0
	return pow(0.75, float(stacks))


## Per stack: +10%% shot fail vs normal enemies, +1%% vs bosses (max 5 stacks).
func get_jammer_attack_fail_chance(is_boss: bool) -> float:
	var stacks: int = mini(_pick_count(int(PerkId.JAMMER)), 5)
	if stacks <= 0:
		return 0.0
	if is_boss:
		return clampf(0.01 * float(stacks), 0.0, 1.0)
	return clampf(0.10 * float(stacks), 0.0, 1.0)


func _pick_count(pid: int) -> int:
	return _variant_to_int(_pick_counts.get(pid, 0), 0)


func _at_stack_cap(pid: int) -> bool:
	var cap: int = _PERK_STACK_LIMIT[pid]
	if cap < 0:
		return false
	return _pick_count(pid) >= cap


func _weighted_rarity(rng: RandomNumberGenerator) -> int:
	var total: int = 0
	for w in RARITY_WEIGHTS:
		total += w
	var roll: int = rng.randi() % total
	var acc: int = 0
	for i in RARITY_WEIGHTS.size():
		acc += RARITY_WEIGHTS[i]
		if roll < acc:
			return i
	return 0


func _make_offer(pid: int, r_idx: int) -> Dictionary:
	var r: Rarity = r_idx as Rarity
	var title_base: String = PERK_TITLE[pid] if pid >= 0 and pid < PERK_TITLE.size() else str(pid)
	var rarity_name: String = RARITY_DISPLAY_NAME[r_idx] if r_idx >= 0 and r_idx < RARITY_DISPLAY_NAME.size() else str(r_idx)
	return {
		"id": pid,
		"rarity": r_idx,
		"title": title_base,
		"rarity_name": rarity_name,
		"description": _describe_perk(pid, r),
		"owned": _pick_count(pid),
		"stack_cap": _PERK_STACK_LIMIT[pid],
	}


func _describe_perk(pid: int, r: Rarity) -> String:
	var ri: int = int(r)
	match pid:
		PerkId.FIREWALL:
			var h: float = (2.0 + float(ri)) * 10.0
			return "Increase max HP by %.0f." % h
		PerkId.ANTIVIRUS:
			var d: float = 2.0 + float(ri)
			return "Increase damage by %.0f." % d
		PerkId.BOOSTERS:
			var t: float = 3.0 + 2.0 * float(ri)
			return "Weapon power-ups last an additional %.0f seconds." % t
		PerkId.BIOS_SAFE_MODE:
			return "Shoot backwards. When the Cross-fire weapon is active, fire in 8 directions."
		PerkId.REVERSE_ENGINEERING:
			var p: float = 0.04 + 0.02 * float(ri - int(Rarity.RARE))
			return "%.0f%% chance to make enemies explode for 25%% of their health on death." % (p * 100.0)
		PerkId.REBOUND:
			return "Your bullets bounce off the border once (does not apply to the beam weapon)."
		PerkId.PATIENCE:
			return "Pickups move down 25%% slower."
		PerkId.LATENCY_KILLER:
			var bs: float = 200.0 + 100.0 * float(ri)
			return "Increase your bullet speed by %.0f pixels per second" % bs
		PerkId.ZERO_DAY_CATCHER:
			return "Pickups spawning on the bottom half of the screen rise upward."
		PerkId.DECRYPTION:
			var pct: float = (0.05 + 0.03 * float(ri - int(Rarity.RARE))) * 100.0
			return "Increase the chance of a weapon power-up dropping from an enemy by %.0f%%." % pct
		PerkId.JAMMER:
			return "Add a 10%% chance for enemy attacks to fail (+1%% for bosses)."
		PerkId.REDUNDANCY:
			var pct: float = (0.01 + 0.01 * float(ri)) * 100.0
			return "Health pickups heal for an addiation %.0f%% of your max health." % pct
		PerkId.HEAT_MAP:
			return "Offscreen enemies show an indicator pointing toward them."
		PerkId.STALLER:
			return "25% chance to add 1 second to weapon power-up duration on enemy kill."
		PerkId.ADDITIONAL_CORE:
			return "Base firing mode becomes Double Straight. Double Straight pickups heal instead. -15% damage."
		_:
			return ""


func roll_three_offers(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var used: Array[int] = []
	for _i in range(3):
		var offer: Dictionary = _roll_one_offer(rng, used)
		if offer.is_empty():
			break
		out.append(offer)
		used.append(_variant_to_int(offer.get("id", 0), 0))
	return out


func _roll_one_offer(rng: RandomNumberGenerator, used: Array[int]) -> Dictionary:
	for attempt in range(48):
		var r_idx: int = _weighted_rarity(rng)
		var candidates: Array[int] = []
		for pid in range(_PERK_R_MIN.size()):
			if pid in used:
				continue
			if _at_stack_cap(pid):
				continue
			if r_idx < _PERK_R_MIN[pid] or r_idx > _PERK_R_MAX[pid]:
				continue
			candidates.append(pid)
		if candidates.is_empty():
			continue
		var pick: int = candidates[rng.randi() % candidates.size()]
		return _make_offer(pick, r_idx)

	# Fallback: any unused perk with a random allowed rarity.
	var fallback_ids: Array[int] = []
	for pid in range(_PERK_R_MIN.size()):
		if pid in used:
			continue
		if _at_stack_cap(pid):
			continue
		fallback_ids.append(pid)
	if fallback_ids.is_empty():
		return {}
	var pid2: int = fallback_ids[rng.randi() % fallback_ids.size()]
	var rr: int = rng.randi_range(_PERK_R_MIN[pid2], _PERK_R_MAX[pid2])
	return _make_offer(pid2, rr)


func apply_offer(offer: Dictionary) -> void:
	var pid: int = _variant_to_int(offer.get("id", -1), -1)
	var r_idx: int = _variant_to_int(offer.get("rarity", 0), 0)
	if pid < 0 or pid >= _PERK_R_MIN.size():
		return
	var pick_title: String = str(offer.get("title", ""))
	var pick_rn: String = str(offer.get("rarity_name", ""))
	if pick_rn != "":
		pick_title = "%s (%s)" % [pick_title, pick_rn]
	pick_history.append({
		"id": pid,
		"rarity": r_idx,
		"title": pick_title,
		"description": offer.get("description", ""),
	})
	_pick_counts[pid] = _pick_count(pid) + 1

	match pid:
		PerkId.FIREWALL:
			total_hp_bonus += (2.0 + float(r_idx)) * 10.0
		PerkId.ANTIVIRUS:
			total_damage_bonus += 2.0 + float(r_idx)
		PerkId.BOOSTERS:
			total_perk_duration_bonus += 3.0 + 2.0 * float(r_idx)
		PerkId.BIOS_SAFE_MODE:
			bios_unlocked = true
		PerkId.REVERSE_ENGINEERING:
			var p: float = 0.04 + 0.02 * float(r_idx - int(Rarity.RARE))
			_reverse_p_layers.append(clampf(p, 0.001, 0.95))
		PerkId.REBOUND:
			rebound_unlocked = true
		PerkId.PATIENCE:
			pass
		PerkId.LATENCY_KILLER:
			total_bullet_speed_bonus += 200.0 + 100.0 * float(r_idx)
		PerkId.ZERO_DAY_CATCHER:
			zero_day_catcher_unlocked = true
		PerkId.DECRYPTION:
			total_weapon_pickup_chance_bonus += 0.05 + 0.03 * float(r_idx - int(Rarity.RARE))
		PerkId.JAMMER:
			pass
		PerkId.REDUNDANCY:
			# Common→Legendary: +1% / +2% / +3% healing from health pickups (additive; stacks).
			total_heal_pickup_bonus += 0.01 + 0.01 * float(clampi(r_idx, 0, int(Rarity.LEGENDARY)))
		PerkId.HEAT_MAP:
			heat_map_unlocked = true
		PerkId.STALLER:
			# Legendary-only, stack cap 3. Each stack adds 25% chance to extend an active weapon perk by +1s on kill.
			staller_extend_chance = clampf(staller_extend_chance + 0.25, 0.0, 0.95)
		PerkId.ADDITIONAL_CORE:
			# Mythical-only, one-time. Converts the baseline weapon to Double Straight but with a damage penalty.
			additional_core_unlocked = true
			additional_core_damage_mult = 0.85


func format_history_for_display() -> String:
	if pick_history.is_empty():
		return "No meta perks this run."
	var parts: Array[String] = []
	for e in pick_history:
		parts.append("%s — %s" % [str(e.get("title", "?")), str(e.get("description", ""))])
	return "\n".join(parts)
