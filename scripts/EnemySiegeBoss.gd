extends EnemyBoss
class_name EnemySiegeBoss

@export var laser_beam_scene: PackedScene = preload("res://scenes/EnemyBossLaserLine.tscn")
@export var explosion_marker_scene: PackedScene = preload("res://scenes/BossExplosionMarker.tscn")

@export var laser_muzzle_local: Vector2 = Vector2(0.0, 52.0)
@export var laser_damage_per_tick: float = 11.0
@export var laser_damage_tick_interval: float = 0.16

@export var explosion_markers_to_spawn: int = 10
@export var explosion_spawn_margin_px: float = 56.0
@export var explosion_fuse_sec: float = 1.32
@export var explosion_radius_px: float = 74.0
@export var explosion_damage: float = 40.0

@export var fan_shot_count: int = 5
@export var fan_arc_degrees: float = 135.0

var _siege_phase: int = 0


func _fire_mixed_pattern_volley() -> void:
	if bullet_scene == null or bullet_parent == null:
		return
	var jammed: bool = VirusHunterGame.jammer_blocks_enemy_volley(get_tree(), true, _rng)
	if not jammed:
		match _siege_phase % 3:
			0:
				_attack_laser()
			1:
				_attack_explosion_field()
			2:
				_attack_fan_shots()
		AudioManager.play_sfx("boss_shot")
	_siege_phase += 1


func _attack_laser() -> void:
	if laser_beam_scene == null:
		return
	var beam: EnemyBossLaserLine = laser_beam_scene.instantiate() as EnemyBossLaserLine
	if beam == null:
		return
	bullet_parent.add_child(beam)
	beam.setup(self, laser_muzzle_local, laser_damage_per_tick, laser_damage_tick_interval)


func _attack_explosion_field() -> void:
	if explosion_marker_scene == null:
		return
	var rect: Rect2 = playfield_rect
	if rect.size == Vector2.ZERO:
		rect = Rect2(Vector2.ZERO, get_viewport_rect().size)
	var inner := explosion_spawn_margin_px
	var left: float = rect.position.x + inner
	var top: float = rect.position.y + inner
	var right: float = rect.end.x - inner
	var bot: float = rect.end.y - inner
	if right <= left or bot <= top:
		return
	var count: int = clampi(explosion_markers_to_spawn, 1, 24)
	for _i in range(count):
		var mx: float = _rng.randf_range(left, right)
		var my: float = _rng.randf_range(top, bot)
		var mk: BossExplosionMarker = explosion_marker_scene.instantiate() as BossExplosionMarker
		if mk == null:
			continue
		bullet_parent.add_child(mk)
		mk.global_position = Vector2(mx, my)
		mk.setup(explosion_fuse_sec, explosion_radius_px, explosion_damage)


func _attack_fan_shots() -> void:
	var half_fan: float = deg_to_rad(fan_arc_degrees * 0.5)
	var nshots: int = clampi(fan_shot_count, 2, 13)
	var denom: int = maxi(1, nshots - 1)
	for i in range(nshots):
		var t: float = float(i) / float(denom)
		var ang: float = lerpf(-half_fan, half_fan, t)
		var dir: Vector2 = Vector2.DOWN.rotated(ang)
		_spawn_bullet_along_dir(dir)


func _spawn_bullet_along_dir(dir: Vector2) -> void:
	var b: BulletEnemy = bullet_scene.instantiate() as BulletEnemy
	if b == null:
		return
	b.scale_factor = bullet_size_scale
	bullet_parent.add_child(b)
	b.global_position = global_position + Vector2(0.0, radius * 0.38)
	b.velocity = dir * normal_bullet_speed
	b.damage = maxf(1.0, normal_bullet_damage)
