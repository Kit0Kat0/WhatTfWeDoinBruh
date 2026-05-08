extends Area2D
class_name Player

@export var speed: float = 420.0
@export var focus_speed_multiplier: float = 0.45
@export var boost_speed_multiplier: float = 1.6
@export var fire_interval: float = 0.08
@export var beam_fire_interval: float = 0.6
@export var beam_line_scene: PackedScene = preload("res://scenes/PlayerBeamLine.tscn")
@export var straight_row_spacing: float = 11.0
@export var triple_fan_angle_degrees: float = 17.5
@export var weapon_perk_duration_sec: float = 15.0
@export var i_frames: float = 0.8
@export var max_hp: float = 250.0

enum WeaponMode { SINGLE, DOUBLE_STRAIGHT, TRIPLE_STRAIGHT, BEAM, CROSS_FIRE }
@export var muzzle_flash_scene: PackedScene = preload("res://scenes/VFX/MuzzleFlash.tscn")
@export var move_anim_fps: float = 12.0

signal health_changed(current: float, maximum: float)
signal died(at: Vector2)

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node

var hp: float = 250.0
var _base_max_hp: float = 250.0
var meta_damage_bonus: float = 0.0
var meta_duration_bonus: float = 0.0
var meta_bios_unlocked: bool = false
var meta_rebound_unlocked: bool = false
var meta_bullet_speed_bonus: float = 0.0
var meta_heal_pickup_bonus: float = 0.0
var meta_heat_map_unlocked: bool = false
var meta_additional_core_unlocked: bool = false
var meta_damage_mult: float = 1.0
var weapon_mode: WeaponMode = WeaponMode.SINGLE
var _weapon_perk_time_left: float = 0.0
var _fire_cooldown: float = 0.0
var _invuln: float = 0.0
var _respawn_immunity: float = 0.0
var _last_move_dir: Vector2 = Vector2.ZERO
var _move_anim_t: float = 0.0
var _move_anim_idx: int = 0

@onready var _sprite: Sprite2D = get_node_or_null(^"Sprite") as Sprite2D
@onready var _move_frame_paths: PackedStringArray = PackedStringArray([
	"res://art/player/player_frame_0.png",
	"res://art/player/player_frame_1.png",
	"res://art/player/player_frame_2.png",
	"res://art/player/player_frame_3.png",
])

var _move_frames: Array[Texture2D] = []


func _ready() -> void:
	add_to_group(Defs.GROUP_PLAYER)
	_base_max_hp = max_hp
	area_entered.connect(_on_area_entered)
	hp = clampf(hp, 0.0, max_hp)
	health_changed.emit(hp, max_hp)
	_move_frames = _load_move_frames()
	queue_redraw()


func get_bullet_damage() -> float:
	return (10.0 + meta_damage_bonus) * meta_damage_mult


func _effective_weapon_perk_duration() -> float:
	return maxf(0.01, weapon_perk_duration_sec + meta_duration_bonus)


func apply_meta_progression(m: MetaProgression) -> void:
	if m == null:
		return
	meta_damage_bonus = m.total_damage_bonus
	meta_duration_bonus = m.total_perk_duration_bonus
	meta_bios_unlocked = m.bios_unlocked
	meta_rebound_unlocked = m.rebound_unlocked
	meta_bullet_speed_bonus = m.total_bullet_speed_bonus
	meta_heal_pickup_bonus = m.total_heal_pickup_bonus
	meta_heat_map_unlocked = m.heat_map_unlocked
	meta_additional_core_unlocked = m.additional_core_unlocked
	meta_damage_mult = m.additional_core_damage_mult
	if meta_additional_core_unlocked and weapon_mode == WeaponMode.SINGLE:
		weapon_mode = WeaponMode.DOUBLE_STRAIGHT
		_weapon_perk_time_left = 0.0
	var new_max: float = _base_max_hp + m.total_hp_bonus
	var gained: float = new_max - max_hp
	max_hp = new_max
	hp = clampf(hp + maxf(0.0, gained), 0.0, max_hp)
	health_changed.emit(hp, max_hp)

func _load_move_frames() -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for p in _move_frame_paths:
		var res: Resource = load(p)
		var as_tex: Texture2D = res as Texture2D
		if as_tex != null:
			out.append(as_tex)
			continue
		var img := Image.new()
		if img.load(p) != OK:
			continue
		out.append(ImageTexture.create_from_image(img))
	return out


func _process(delta: float) -> void:
	var prev_respawn_immunity: float = _respawn_immunity
	_invuln = maxf(0.0, _invuln - delta)
	_respawn_immunity = maxf(0.0, _respawn_immunity - delta)
	if prev_respawn_immunity > 0.0 and _respawn_immunity <= 0.0:
		AudioManager.play_sfx("player_respawn_out")
	_update_weapon_perk_timer(delta)
	_update_movement(delta)
	_update_shooting(delta)
	_update_sprite_anim(delta)
	queue_redraw()


func _update_movement(delta: float) -> void:
	var dir: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	_last_move_dir = dir

	var mult: float = 1.0
	var boosting: bool = Input.is_action_pressed("boost")
	var focusing: bool = Input.is_action_pressed("focus")
	# Boost takes priority to avoid accidental slowdown when boost/focus share a key.
	if boosting:
		mult = boost_speed_multiplier
	elif focusing:
		mult = focus_speed_multiplier
	global_position += dir * speed * mult * delta

	if playfield_rect.size != Vector2.ZERO:
		var margin: float = 14.0
		global_position.x = clampf(global_position.x, playfield_rect.position.x + margin, playfield_rect.end.x - margin)
		global_position.y = clampf(global_position.y, playfield_rect.position.y + margin, playfield_rect.end.y - margin)


func _update_sprite_anim(delta: float) -> void:
	if _sprite == null:
		return
	if _move_frames.is_empty():
		return

	# Alternate #1/#2 combined: use pre-cropped frames and instantly swap textures.
	if _last_move_dir.length_squared() < 0.001:
		_move_anim_t = 0.0
		_move_anim_idx = 0
		_sprite.texture = _move_frames[0]
		return

	var fps := maxf(1.0, move_anim_fps)
	var step := 1.0 / fps
	_move_anim_t += delta
	while _move_anim_t >= step:
		_move_anim_t -= step
		_move_anim_idx = (_move_anim_idx + 1) % _move_frames.size()
	_sprite.texture = _move_frames[_move_anim_idx]




func _update_weapon_perk_timer(delta: float) -> void:
	if weapon_mode == WeaponMode.SINGLE:
		_weapon_perk_time_left = 0.0
		return
	if meta_additional_core_unlocked and weapon_mode == WeaponMode.DOUBLE_STRAIGHT and _weapon_perk_time_left <= 0.0:
		_weapon_perk_time_left = 0.0
		return
	# When no enemies are active, let power-up timers tick much slower.
	var tree: SceneTree = get_tree()
	if tree != null:
		var enemies: Array[Node] = tree.get_nodes_in_group(Defs.GROUP_ENEMY)
		if enemies.is_empty():
			delta *= 0.1
	_weapon_perk_time_left -= delta
	if _weapon_perk_time_left <= 0.0:
		_weapon_perk_time_left = 0.0
		weapon_mode = WeaponMode.SINGLE


func _fire_interval_for_weapon() -> float:
	if weapon_mode == WeaponMode.BEAM:
		return beam_fire_interval
	return fire_interval


func _update_shooting(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if _respawn_immunity > 0.0:
		return
	var wants_to_shoot: bool = Input.is_action_pressed("shoot") or GameSettings.automatic_shooting
	if not wants_to_shoot:
		return
	if _fire_cooldown > 0.0:
		return
	if bullet_scene == null or bullet_parent == null:
		return

	_fire_cooldown = _fire_interval_for_weapon()

	var bullet_speed: float = 900.0 + meta_bullet_speed_bonus
	var base_v: Vector2 = Vector2(0.0, -bullet_speed)
	match weapon_mode:
		WeaponMode.SINGLE:
			_spawn_player_bullet(Vector2.ZERO, base_v)
			if meta_bios_unlocked:
				_spawn_player_bullet(Vector2.ZERO, -base_v)
		WeaponMode.DOUBLE_STRAIGHT:
			_spawn_player_bullet(Vector2(-straight_row_spacing, 0.0), base_v)
			_spawn_player_bullet(Vector2(straight_row_spacing, 0.0), base_v)
			if meta_bios_unlocked:
				_spawn_player_bullet(Vector2(-straight_row_spacing, 0.0), -base_v)
				_spawn_player_bullet(Vector2(straight_row_spacing, 0.0), -base_v)
		WeaponMode.TRIPLE_STRAIGHT:
			var a: float = deg_to_rad(triple_fan_angle_degrees)
			_spawn_player_bullet(Vector2(-straight_row_spacing * 1.4, 0.0), base_v.rotated(-a))
			_spawn_player_bullet(Vector2.ZERO, base_v)
			_spawn_player_bullet(Vector2(straight_row_spacing * 1.4, 0.0), base_v.rotated(a))
			if meta_bios_unlocked:
				_spawn_player_bullet(Vector2(-straight_row_spacing * 1.4, 0.0), (-base_v).rotated(-a))
				_spawn_player_bullet(Vector2.ZERO, -base_v)
				_spawn_player_bullet(Vector2(straight_row_spacing * 1.4, 0.0), (-base_v).rotated(a))
		WeaponMode.BEAM:
			_spawn_beam_line(Vector2.ZERO)
			if meta_bios_unlocked:
				_spawn_player_bullet(Vector2.ZERO, -base_v)
		WeaponMode.CROSS_FIRE:
			if meta_bios_unlocked:
				for i in 8:
					var ang: float = -PI * 0.5 + float(i) * TAU / 8.0
					_spawn_player_bullet(Vector2.ZERO, Vector2.from_angle(ang) * bullet_speed)
			else:
				_spawn_player_bullet(Vector2.ZERO, Vector2(0.0, -bullet_speed))
				_spawn_player_bullet(Vector2.ZERO, Vector2(0.0, bullet_speed))
				_spawn_player_bullet(Vector2.ZERO, Vector2(-bullet_speed, 0.0))
				_spawn_player_bullet(Vector2.ZERO, Vector2(bullet_speed, 0.0))
	var shot_pitch_jitter: float = randf_range(0.94, 1.06)
	AudioManager.play_sfx("player_shot", shot_pitch_jitter)


func _spawn_player_bullet(offset_from_center: Vector2, velocity: Vector2) -> void:
	var b: BulletPlayer = bullet_scene.instantiate() as BulletPlayer
	if b == null:
		return
	b.velocity = velocity
	b.pierce = false
	b.damage = get_bullet_damage()
	if meta_rebound_unlocked:
		b.playfield_bounds = playfield_rect
		b.border_bounces_left = 1
	else:
		b.playfield_bounds = Rect2()
		b.border_bounces_left = 0
	bullet_parent.add_child(b)
	b.global_position = global_position + offset_from_center + Vector2(0.0, -16.0)


func _spawn_beam_line(offset_from_center: Vector2) -> void:
	if beam_line_scene == null:
		return
	var beam: PlayerBeamLine = beam_line_scene.instantiate() as PlayerBeamLine
	if beam == null:
		return
	beam.setup(self, offset_from_center + Vector2(0.0, -16.0))
	bullet_parent.add_child(beam)


func has_active_weapon_perk() -> bool:
	if weapon_mode == WeaponMode.SINGLE:
		return false
	# Additional Core makes Double Straight the baseline, not a timed perk.
	if meta_additional_core_unlocked and weapon_mode == WeaponMode.DOUBLE_STRAIGHT and _weapon_perk_time_left <= 0.0:
		return false
	return true


func get_weapon_perk_kind() -> WeaponPickup.PerkKind:
	match weapon_mode:
		WeaponMode.DOUBLE_STRAIGHT:
			return WeaponPickup.PerkKind.DOUBLE_STRAIGHT
		WeaponMode.TRIPLE_STRAIGHT:
			return WeaponPickup.PerkKind.TRIPLE_STRAIGHT
		WeaponMode.BEAM:
			return WeaponPickup.PerkKind.BEAM
		WeaponMode.CROSS_FIRE:
			return WeaponPickup.PerkKind.CROSS_FIRE
		_:
			return WeaponPickup.PerkKind.DOUBLE_STRAIGHT


func get_weapon_perk_time_ratio() -> float:
	if weapon_mode == WeaponMode.SINGLE:
		return 0.0
	var dur: float = _effective_weapon_perk_duration()
	if dur <= 0.0:
		return 0.0
	return clampf(_weapon_perk_time_left / dur, 0.0, 1.0)


func refresh_weapon_perk_timer() -> void:
	if weapon_mode == WeaponMode.SINGLE:
		return
	_weapon_perk_time_left = maxf(0.0, _effective_weapon_perk_duration())


func add_weapon_perk_time(seconds: float) -> void:
	if weapon_mode == WeaponMode.SINGLE:
		return
	if seconds <= 0.0:
		return
	_weapon_perk_time_left = maxf(0.0, _weapon_perk_time_left + seconds)


func apply_weapon_pickup(kind: WeaponPickup.PerkKind) -> void:
	if meta_additional_core_unlocked and kind == WeaponPickup.PerkKind.DOUBLE_STRAIGHT:
		# Convert Double Straight pickups into small heals instead of a redundant baseline upgrade.
		heal_by_max_hp_fraction(0.05)
		return
	match kind:
		WeaponPickup.PerkKind.DOUBLE_STRAIGHT:
			weapon_mode = WeaponMode.DOUBLE_STRAIGHT
		WeaponPickup.PerkKind.TRIPLE_STRAIGHT:
			weapon_mode = WeaponMode.TRIPLE_STRAIGHT
		WeaponPickup.PerkKind.BEAM:
			weapon_mode = WeaponMode.BEAM
		WeaponPickup.PerkKind.CROSS_FIRE:
			weapon_mode = WeaponMode.CROSS_FIRE
	_weapon_perk_time_left = maxf(0.0, _effective_weapon_perk_duration())


## One-shot hazards (explosion marks, etc.) — respects bullet i-frames.
func receive_damage(amount: float) -> void:
	if _invuln > 0.0 or _respawn_immunity > 0.0:
		return
	_take_damage(amount)


## Continuous hazards (boss laser): chips HP without applying full bullet i-frames each tick.
func receive_hazard_damage(amount: float) -> void:
	if amount <= 0.0 or hp <= 0.0:
		return
	if _respawn_immunity > 0.0:
		return
	hp = maxf(0.0, hp - amount)
	health_changed.emit(hp, max_hp)
	queue_redraw()
	if hp <= 0:
		AudioManager.play_sfx("player_death")
		AudioManager.duck_music(6.0, 0.3, 0.7)
		died.emit(global_position)
		queue_free()


func heal_by_max_hp_fraction(fraction: float) -> void:
	if hp <= 0.0:
		return
	var boosted: float = clampf(fraction * (1.0 + maxf(0.0, meta_heal_pickup_bonus)), 0.0, 1.0)
	var amt: float = max_hp * boosted
	if amt <= 0.001:
		return
	hp = clampf(hp + amt, 0.0, max_hp)
	health_changed.emit(hp, max_hp)
	queue_redraw()


func _spawn_muzzle_flash(local_offset: Vector2) -> void:
	if muzzle_flash_scene == null:
		return
	var fx: Node2D = muzzle_flash_scene.instantiate() as Node2D
	if fx == null:
		return
	# Parent to the player so the flash follows player motion.
	add_child(fx)
	fx.position = local_offset


func _draw() -> void:
	var a: float = 1.0
	if _invuln > 0.0 or _respawn_immunity > 0.0:
		a = 0.35

	# Keep the Nier-style "precision mode" readability: hitbox only on focus.
	if Input.is_action_pressed("focus"):
		draw_circle(Vector2.ZERO, 14.0, Color(1, 1, 1, 0.18 * a))
		draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.1, 0.35, a))


func _on_area_entered(area: Area2D) -> void:
	if _invuln > 0.0 or _respawn_immunity > 0.0:
		return
	if area.is_in_group(Defs.GROUP_ENEMY_BULLET):
		var enemy_bullet: BulletEnemy = area as BulletEnemy
		if enemy_bullet != null:
			_take_damage(enemy_bullet.damage)
		else:
			_take_damage(10.0)
	elif area.is_in_group(Defs.GROUP_ENEMY):
		var enemy_basic: EnemyBasic = area as EnemyBasic
		if enemy_basic != null:
			_take_damage(enemy_basic.body_damage_to_player)
			return
		var enemy_boss: EnemyBoss = area as EnemyBoss
		if enemy_boss != null:
			_take_damage(enemy_boss.body_damage_to_player)
			return
		_take_damage(10.0)


func _take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	_invuln = i_frames
	hp = maxf(0.0, hp - amount)
	health_changed.emit(hp, max_hp)
	queue_redraw()
	if hp <= 0:
		AudioManager.play_sfx("player_death")
		AudioManager.duck_music(6.0, 0.3, 0.7)
		died.emit(global_position)
		queue_free()
	else:
		AudioManager.play_sfx("player_hit")


func reset_for_respawn(respawn_immunity_duration: float) -> void:
	weapon_mode = WeaponMode.DOUBLE_STRAIGHT if meta_additional_core_unlocked else WeaponMode.SINGLE
	_weapon_perk_time_left = 0.0
	hp = max_hp
	_invuln = 0.0
	_respawn_immunity = maxf(0.0, respawn_immunity_duration)
	_fire_cooldown = fire_interval
	health_changed.emit(hp, max_hp)
	queue_redraw()
	AudioManager.play_sfx("player_respawn_in")
