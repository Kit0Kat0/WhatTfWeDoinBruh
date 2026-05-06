extends Area2D
class_name EnemyBasic

const OFFSCREEN_SPEED_CAP: float = 300.0

enum Faction { VIRUS, ANTIVIRUS }

@export var hp: float = 80.0
@export var speed: float = 220.0
@export var horizontal_speed: float = 80.0
@export var shot_interval: float = 0.85
## Randomizes each gap between shots: next interval is `shot_interval` ± this fraction (keeps groups from firing in lockstep after the first volley).
@export var shot_interval_jitter_ratio: float = 0.45
@export var shot_interval_min_sec: float = 0.08
@export var bullet_speed: float = 220.0
@export var bullet_damage: float = 20.0
@export var use_wave_bullets: bool = false
@export var wave_amplitude: float = 26.0
@export var wave_frequency: float = 7.0
@export var radius: float = 14.0
@export var faction: Faction = Faction.VIRUS
@export var virus_color: Color = Color(0.95, 0.2, 0.85, 1.0)
@export var antivirus_color: Color = Color(0.25, 0.95, 1.0, 1.0)
@export var shot_sfx_id: String = "enemy_normal_shot"
@export var follow_path_rotation: bool = false
@export var damage_flash_duration_sec: float = 0.1
@export var run_fps: float = 10.0
@export var hit_shake_enabled: bool = true
@export var hit_shake_strength_px: float = 7.0
@export var hit_shake_duration_sec: float = 0.16

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node
var path_motion: EnemyPathMotion

var _fire_cooldown: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _damage_flash_remaining: float = 0.0
var _hit_shake_time_left: float = 0.0
var _hit_shake_duration: float = 0.0
var _hit_shake_strength_px_live: float = 0.0
var _hit_shake_dir: Vector2 = Vector2.ZERO
var _sprite_base_pos: Vector2 = Vector2.ZERO

@onready var _sprite_node: Node2D = (
	get_node_or_null(^"AnimatedSprite2D") as Node2D
	if get_node_or_null(^"AnimatedSprite2D") != null
	else get_node_or_null(^"Sprite2D") as Node2D
)
@onready var _sprite_item: CanvasItem = _sprite_node as CanvasItem
@onready var _anim_sprite: AnimatedSprite2D = get_node_or_null(^"AnimatedSprite2D") as AnimatedSprite2D
@onready var _static_sprite: Sprite2D = get_node_or_null(^"Sprite2D") as Sprite2D

static var _visible_extent_cache: Dictionary = {}

static func _variant_to_float(v: Variant, fallback: float) -> float:
	match typeof(v):
		TYPE_FLOAT:
			return v as float
		TYPE_INT:
			return float(v as int)
		TYPE_BOOL:
			return 1.0 if (v as bool) else 0.0
		_:
			return fallback


func _is_on_screen(margin: float = 24.0) -> bool:
	if playfield_rect.size == Vector2.ZERO:
		return true
	return playfield_rect.grow(margin).has_point(global_position)

func _offscreen_speed(base_speed: float) -> float:
	# Offscreen speed-up rule:
	# - doubled
	# - set to OFFSCREEN_SPEED_CAP
	# - or unchanged
	# Choose the lowest value that does not reduce current speed.
	var boosted: float = minf(base_speed * 2.0, OFFSCREEN_SPEED_CAP)
	return base_speed if boosted < base_speed else boosted


func _with_hit_flash(c: Color) -> Color:
	if _damage_flash_remaining <= 0.0 or damage_flash_duration_sec <= 0.0:
		return c
	var t: float = clampf(_damage_flash_remaining / damage_flash_duration_sec, 0.0, 1.0)
	return c.lerp(Color(1.0, 1.0, 1.0, c.a), t)

func _palette_base_color() -> Color:
	return antivirus_color if faction == Faction.ANTIVIRUS else virus_color

func _sync_collision_radius() -> void:
	var cs: CollisionShape2D = get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is CircleShape2D:
		(cs.shape as CircleShape2D).radius = radius

func _sync_sprite_scale() -> void:
	if _sprite_node == null:
		return

	var visible_extent: float = _estimate_visible_extent_px()
	var denom: float = maxf(1.0, visible_extent)
	var target_diameter: float = maxf(1.0, radius * 2.0)
	var s: float = target_diameter / denom
	_sprite_node.scale = Vector2(s, s)

func _estimate_visible_extent_px(alpha_threshold: float = 0.08) -> float:
	# Estimate "body" size by scanning opaque pixels so padded frames don't shrink the sprite.
	# Returns the max(visible_width, visible_height) in pixels, falling back to region size.
	if _sprite_node == null:
		return 1.0

	var tex: Texture2D = null
	if _anim_sprite != null:
		var sf: SpriteFrames = _anim_sprite.sprite_frames
		if sf != null:
			tex = sf.get_frame_texture(_anim_sprite.animation, _anim_sprite.frame)
	elif _static_sprite != null:
		tex = _static_sprite.texture

	var cache_key: String = ""
	if tex != null:
		cache_key = str(tex.get_instance_id())
		if tex is AtlasTexture:
			var at: AtlasTexture = tex as AtlasTexture
			if at.atlas != null:
				cache_key = "%s|%s" % [str(at.atlas.get_instance_id()), str(at.region)]

	var fallback: float = 48.0
	if tex is AtlasTexture:
		var at_fb: AtlasTexture = tex as AtlasTexture
		fallback = maxf(at_fb.region.size.x, at_fb.region.size.y)
	elif tex != null:
		fallback = maxf(tex.get_size().x, tex.get_size().y)

	if cache_key != "" and _visible_extent_cache.has(cache_key):
		return _variant_to_float(_visible_extent_cache[cache_key], fallback)

	var img: Image = null
	var rect: Rect2i
	if tex is AtlasTexture:
		var at2: AtlasTexture = tex as AtlasTexture
		if at2.atlas != null:
			img = at2.atlas.get_image()
			rect = Rect2i(int(at2.region.position.x), int(at2.region.position.y), int(at2.region.size.x), int(at2.region.size.y))
	else:
		img = tex.get_image() if tex != null else null
		rect = Rect2i(0, 0, int(fallback), int(fallback))

	if img == null:
		if cache_key != "":
			_visible_extent_cache[cache_key] = fallback
		return fallback

	# Crop to atlas region if needed.
	if rect.size.x > 0 and rect.size.y > 0 and (rect.position != Vector2i.ZERO or rect.size != img.get_size()):
		# Clamp to image bounds
		var max_w: int = img.get_width()
		var max_h: int = img.get_height()
		rect.position.x = clampi(rect.position.x, 0, max_w - 1)
		rect.position.y = clampi(rect.position.y, 0, max_h - 1)
		rect.size.x = clampi(rect.size.x, 1, max_w - rect.position.x)
		rect.size.y = clampi(rect.size.y, 1, max_h - rect.position.y)
		img = img.get_region(rect)

	if img == null:
		if cache_key != "":
			_visible_extent_cache[cache_key] = fallback
		return fallback

	img.decompress()
	var w: int = img.get_width()
	var h: int = img.get_height()
	var min_x: int = w
	var min_y: int = h
	var max_x: int = -1
	var max_y: int = -1
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > alpha_threshold:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)

	var extent: float = fallback
	if max_x >= min_x and max_y >= min_y:
		var vis_w: int = (max_x - min_x) + 1
		var vis_h: int = (max_y - min_y) + 1
		extent = float(maxi(vis_w, vis_h))

	if cache_key != "":
		_visible_extent_cache[cache_key] = extent
	return extent


func _sync_visuals() -> void:
	if _sprite_item == null:
		return
	var base: Color = _palette_base_color()
	_sprite_item.modulate = base
	var mat: ShaderMaterial = _sprite_item.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("tint_color", base)
		var flash: float = 0.0
		if damage_flash_duration_sec > 0.0 and _damage_flash_remaining > 0.0:
			flash = clampf(_damage_flash_remaining / damage_flash_duration_sec, 0.0, 1.0)
		mat.set_shader_parameter("flash", flash)

func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY)
	area_entered.connect(_on_area_entered)
	_rng.randomize()
	_fire_cooldown = _rng.randf_range(0.0, shot_interval)
	_sync_collision_radius()
	# Duplicate material per instance so shader uniforms (flash) aren't shared across all enemies.
	if _sprite_item != null and _sprite_item.material is ShaderMaterial:
		_sprite_item.material = (_sprite_item.material as ShaderMaterial).duplicate(true)
	if _anim_sprite != null:
		# Ensure animation is actually playing even if the scene was duplicated/loaded in a paused state.
		_anim_sprite.play(&"run")
		var base_speed: float = _anim_sprite.sprite_frames.get_animation_speed(&"run")
		_anim_sprite.speed_scale = 1.0 if run_fps <= 0.0 else (run_fps / maxf(1.0, base_speed))
	if _sprite_node != null:
		_sprite_base_pos = _sprite_node.position
	_sync_sprite_scale()
	_sync_visuals()


func _process(delta: float) -> void:
	_update_hit_shake(delta)
	if _damage_flash_remaining > 0.0:
		_damage_flash_remaining = maxf(0.0, _damage_flash_remaining - delta)
		_sync_visuals()
	elif _sprite_item != null and _sprite_item.modulate != _palette_base_color():
		_sync_visuals()

	var effective_speed: float = speed
	if not _is_on_screen():
		effective_speed = _offscreen_speed(speed)
	if path_motion != null:
		path_motion.advance(delta, effective_speed)
		path_motion.apply_to(self, follow_path_rotation)
	else:
		# Fallback if spawned without a path (should not happen in normal waves).
		global_position.y += effective_speed * delta

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		var span: float = shot_interval * shot_interval_jitter_ratio
		var next_interval: float = shot_interval + _rng.randf_range(-span, span)
		_fire_cooldown = maxf(shot_interval_min_sec, next_interval)
		if _is_on_screen():
			_fire_forward()


func _fire_forward() -> void:
	if bullet_scene == null or bullet_parent == null:
		return

	var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
	if b == null:
		return

	bullet_parent.add_child(b)
	b.global_position = global_position
	b.velocity = Vector2.DOWN * bullet_speed
	b.damage = maxf(1.0, bullet_damage)
	if use_wave_bullets:
		b.wave_axis = Vector2.RIGHT
		b.wave_amplitude = wave_amplitude
		b.wave_frequency = wave_frequency
		b.wave_phase = _rng.randf_range(0.0, TAU)
	if shot_sfx_id != "":
		AudioManager.play_sfx(shot_sfx_id)


func apply_beam_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	hp -= amount
	if hp <= 0:
		AudioManager.play_sfx("enemy_kill")
		_try_spawn_weapon_pickup_drop(false)
		queue_free()
	else:
		_damage_flash_remaining = damage_flash_duration_sec
		_kick_hit_shake(maxf(1.0, amount) * 0.02)
		_sync_visuals()
		AudioManager.play_sfx("enemy_hit")


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_PLAYER_BULLET):
		var dmg: float = 10.0
		var pb: BulletPlayer = area as BulletPlayer
		if pb != null:
			dmg = maxf(1.0, pb.damage)
		hp -= dmg
		if hp <= 0:
			AudioManager.play_sfx("enemy_kill")
			_try_spawn_weapon_pickup_drop(false)
			queue_free()
		else:
			_damage_flash_remaining = damage_flash_duration_sec
			_kick_hit_shake(dmg * 0.05)
			_sync_visuals()
			AudioManager.play_sfx("enemy_hit")


func _kick_hit_shake(damage_scaled: float) -> void:
	if not hit_shake_enabled or _sprite_node == null:
		return
	var strength: float = hit_shake_strength_px + clampf(damage_scaled, 0.0, hit_shake_strength_px)
	var dur: float = hit_shake_duration_sec
	_hit_shake_strength_px_live = maxf(_hit_shake_strength_px_live, strength)
	_hit_shake_duration = maxf(_hit_shake_duration, dur)
	_hit_shake_time_left = maxf(_hit_shake_time_left, dur)
	var d: Vector2 = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
	_hit_shake_dir = d.normalized() if d.length_squared() > 0.0001 else Vector2.RIGHT


func _update_hit_shake(delta: float) -> void:
	if _sprite_node == null:
		return
	if get_tree().paused:
		_sprite_node.position = _sprite_base_pos
		return
	if _hit_shake_time_left <= 0.0:
		_sprite_node.position = _sprite_base_pos
		return
	_hit_shake_time_left = maxf(0.0, _hit_shake_time_left - delta)
	var t: float = 1.0
	if _hit_shake_duration > 0.0:
		t = clampf(_hit_shake_time_left / _hit_shake_duration, 0.0, 1.0)
	# Linear falloff keeps more "punch" early than quadratic.
	var strength: float = _hit_shake_strength_px_live * t
	var kick: Vector2 = _hit_shake_dir * (strength * 0.55)
	var jitter: Vector2 = Vector2(
		_rng.randf_range(-strength, strength),
		_rng.randf_range(-strength, strength)
	) * 0.45
	_sprite_node.position = _sprite_base_pos + kick + jitter
	if _hit_shake_time_left <= 0.0:
		_hit_shake_strength_px_live = 0.0
		_hit_shake_duration = 0.0


func _try_spawn_weapon_pickup_drop(from_boss: bool) -> void:
	for n in get_tree().get_nodes_in_group("game_controller"):
		if n.has_method("try_spawn_weapon_pickup"):
			n.call("try_spawn_weapon_pickup", global_position, from_boss)
			return
