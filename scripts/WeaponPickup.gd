extends Area2D
class_name WeaponPickup

enum PerkKind { DOUBLE_STRAIGHT, TRIPLE_STRAIGHT, BEAM, CROSS_FIRE }

@export var fall_speed: float = 55.0
@export var life_seconds: float = 14.0

var perk_kind: PerkKind = PerkKind.DOUBLE_STRAIGHT

var _life: float = 0.0
var _playfield_rect: Rect2 = Rect2()


func _ready() -> void:
	add_to_group(Defs.GROUP_WEAPON_PICKUP)
	area_entered.connect(_on_area_entered)
	_life = life_seconds
	monitoring = true
	monitorable = true
	queue_redraw()


func setup(kind: PerkKind, playfield: Rect2) -> void:
	perk_kind = kind
	_playfield_rect = playfield


func _process(delta: float) -> void:
	global_position.y += fall_speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if _playfield_rect.size != Vector2.ZERO and global_position.y > _playfield_rect.end.y + 40.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group(Defs.GROUP_PLAYER):
		return
	var p: Player = area as Player
	if p == null:
		return
	p.apply_weapon_pickup(perk_kind)
	queue_free()


func _draw() -> void:
	var col: Color = Color(0.45, 0.95, 1.0, 0.95)
	match perk_kind:
		PerkKind.TRIPLE_STRAIGHT:
			col = Color(0.95, 0.45, 1.0, 0.95)
		PerkKind.BEAM:
			col = Color(1.0, 0.82, 0.25, 0.95)
		PerkKind.CROSS_FIRE:
			col = Color(0.35, 1.0, 0.45, 0.95)
	draw_circle(Vector2.ZERO, 12.0, col)
	draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0, true)
