extends Area2D
class_name EnemyBoss

const OFFSCREEN_SPEED_CAP: float = EnemyBasic.OFFSCREEN_SPEED_CAP
const Faction := EnemyBasic.Faction

signal health_changed(current_hp: float, max_hp: float)

@export var max_hp: float = 1600.0
var hp: float = 1600.0
@export var path_follow_speed: float = 190.0
@export var radius: float = 78.0
@export var faction: Faction = EnemyBasic.Faction.VIRUS
@export var virus_color: Color = Color(1.0, 0.15, 0.25, 1.0)
@export var antivirus_color: Color = Color(0.25, 0.85, 1.0, 1.0)
@export var shot_interval: float = 0.35
@export var shot_interval_jitter_ratio: float = 0.35
@export var shot_interval_min_sec: float = 0.1
## Straight-down volleys (normal-style): speed + damage.
@export var normal_bullet_speed: float = 280.0
@export var normal_bullet_damage: float = 20.0
## Three-way spread volleys (tanky-style): slower, harder-hitting.
@export var tank_bullet_speed: float = 200.0
@export var tank_bullet_damage: float = 30.0
@export var tank_spread_angle_degrees: float = 14.0
@export var follow_path_rotation: bool = false
@export var damage_flash_duration_sec: float = 0.1

var playfield_rect: Rect2
var bullet_scene: PackedScene
var bullet_parent: Node
var path_motion: EnemyPathMotion

var _fire_cooldown: float = 0.0
var _pattern_volley: int = 0
var _damage_flash_remaining: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _sprite: Sprite2D = get_node_or_null(^"Sprite2D") as Sprite2D

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
	var boosted: float = minf(base_speed * 2.0, OFFSCREEN_SPEED_CAP)
	return base_speed if boosted < base_speed else boosted


func _with_hit_flash(c: Color) -> Color:
	if _damage_flash_remaining <= 0.0 or damage_flash_duration_sec <= 0.0:
		return c
	var t: float = clampf(_damage_flash_remaining / damage_flash_duration_sec, 0.0, 1.0)
	return c.lerp(Color(1.0, 1.0, 1.0, c.a), t)

func _palette_base_color() -> Color:
	return antivirus_color if faction == EnemyBasic.Faction.ANTIVIRUS else virus_color

func _sync_visuals() -> void:
	if _sprite == null:
		return
	var base: Color = _palette_base_color()
	_sprite.modulate = base
	var mat: ShaderMaterial = _sprite.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("tint_color", base)
		var flash: float = 0.0
		if damage_flash_duration_sec > 0.0 and _damage_flash_remaining > 0.0:
			flash = clampf(_damage_flash_remaining / damage_flash_duration_sec, 0.0, 1.0)
		mat.set_shader_parameter("flash", flash)

func _sync_sprite_scale() -> void:
	if _sprite == null:
		return
	var visible_extent: float = _estimate_visible_extent_px()
	var denom: float = maxf(1.0, visible_extent)
	var target_diameter: float = maxf(1.0, radius * 2.0)
	var s: float = target_diameter / denom
	_sprite.scale = Vector2(s, s)

func _estimate_visible_extent_px(alpha_threshold: float = 0.08) -> float:
	if _sprite == null:
		return 1.0

	var tex: Texture2D = _sprite.texture
	var cache_key: String = ""
	if tex != null:
		cache_key = str(tex.get_instance_id())
		if tex is AtlasTexture:
			var at0: AtlasTexture = tex as AtlasTexture
			if at0.atlas != null:
				cache_key = "%s|%s" % [str(at0.atlas.get_instance_id()), str(at0.region)]

	var fallback: float = 64.0
	var at: AtlasTexture = tex as AtlasTexture
	if at != null:
		fallback = maxf(at.region.size.x, at.region.size.y)
	elif tex != null:
		fallback = maxf(tex.get_size().x, tex.get_size().y)

	if cache_key != "" and _visible_extent_cache.has(cache_key):
		return _variant_to_float(_visible_extent_cache[cache_key], fallback)

	var img: Image = null
	var rect: Rect2i
	if at != null and at.atlas != null:
		img = at.atlas.get_image()
		rect = Rect2i(int(at.region.position.x), int(at.region.position.y), int(at.region.size.x), int(at.region.size.y))
	elif tex != null:
		img = tex.get_image()
		rect = Rect2i(0, 0, int(fallback), int(fallback))

	if img == null:
		if cache_key != "":
			_visible_extent_cache[cache_key] = fallback
		return fallback

	if rect.size.x > 0 and rect.size.y > 0 and (rect.position != Vector2i.ZERO or rect.size != img.get_size()):
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


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY)
	area_entered.connect(_on_area_entered)
	hp = max_hp
	_rng.randomize()
	_fire_cooldown = _rng.randf_range(0.0, shot_interval)
	_sync_collision_radius()
	# Duplicate material per instance so shader uniforms (flash) aren't shared across all bosses/enemies.
	if _sprite != null and _sprite.material is ShaderMaterial:
		_sprite.material = (_sprite.material as ShaderMaterial).duplicate(true)
	_sync_sprite_scale()
	_sync_visuals()
	health_changed.emit(hp, max_hp)


func _sync_collision_radius() -> void:
	var cs: CollisionShape2D = get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape is CircleShape2D:
		(cs.shape as CircleShape2D).radius = radius


func _process(delta: float) -> void:
	if _damage_flash_remaining > 0.0:
		_damage_flash_remaining = maxf(0.0, _damage_flash_remaining - delta)
		_sync_visuals()
	elif _sprite != null and _sprite.modulate != _palette_base_color():
		_sync_visuals()

	var effective_speed: float = path_follow_speed
	if not _is_on_screen(48.0):
		effective_speed = _offscreen_speed(path_follow_speed)
	if path_motion != null:
		path_motion.advance(delta, effective_speed)
		path_motion.apply_to(self, follow_path_rotation)

	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		var span: float = shot_interval * shot_interval_jitter_ratio
		var next_interval: float = shot_interval + _rng.randf_range(-span, span)
		_fire_cooldown = maxf(shot_interval_min_sec, next_interval)
		if _is_on_screen(48.0):
			_fire_mixed_pattern_volley()


func _fire_mixed_pattern_volley() -> void:
	if bullet_scene == null or bullet_parent == null:
		return

	if _pattern_volley % 2 == 0:
		_fire_normal_forward()
	else:
		_fire_tanky_spread()
	_pattern_volley += 1
	AudioManager.play_sfx("boss_shot")


func _fire_normal_forward() -> void:
	var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
	if b == null:
		return
	bullet_parent.add_child(b)
	b.global_position = global_position + Vector2(0.0, radius * 0.35)
	b.velocity = Vector2.DOWN * normal_bullet_speed
	b.damage = maxf(1.0, normal_bullet_damage)


func _fire_tanky_spread() -> void:
	var spread_radians: float = deg_to_rad(tank_spread_angle_degrees)
	var dirs: Array[Vector2] = [
		Vector2.DOWN,
		Vector2.DOWN.rotated(spread_radians),
		Vector2.DOWN.rotated(-spread_radians),
	]
	for d in dirs:
		var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
		if b == null:
			continue
		bullet_parent.add_child(b)
		b.global_position = global_position + d * (radius * 0.35)
		b.velocity = d * tank_bullet_speed
		b.damage = maxf(1.0, tank_bullet_damage)


func apply_beam_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	hp -= amount
	if hp <= 0:
		hp = 0
		health_changed.emit(hp, max_hp)
		AudioManager.play_sfx("boss_death")
		AudioManager.duck_music(6.0, 0.3, 0.7)
		for n in get_tree().get_nodes_in_group("game_controller"):
			if n.has_method("try_spawn_weapon_pickup"):
				n.call("try_spawn_weapon_pickup", global_position, true)
				break
		queue_free()
	else:
		health_changed.emit(hp, max_hp)
		_damage_flash_remaining = damage_flash_duration_sec
		_sync_visuals()
		if int(hp) % 50 == 0:
			AudioManager.play_sfx("boss_hit")


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(Defs.GROUP_PLAYER_BULLET):
		var dmg: float = 10.0
		var pb: BulletPlayer = area as BulletPlayer
		if pb != null:
			dmg = maxf(1.0, pb.damage)
		hp -= dmg
		if hp <= 0:
			hp = 0
			health_changed.emit(hp, max_hp)
			AudioManager.play_sfx("boss_death")
			AudioManager.duck_music(6.0, 0.3, 0.7)
			for n in get_tree().get_nodes_in_group("game_controller"):
				if n.has_method("try_spawn_weapon_pickup"):
					n.call("try_spawn_weapon_pickup", global_position, true)
					break
			queue_free()
		else:
			health_changed.emit(hp, max_hp)
			_damage_flash_remaining = damage_flash_duration_sec
			_sync_visuals()
			if int(hp) % 50 == 0:
				AudioManager.play_sfx("boss_hit")
