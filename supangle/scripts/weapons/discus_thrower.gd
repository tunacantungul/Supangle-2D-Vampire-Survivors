extends Node2D
## "discus" kartı: Olimpiyat Diski — en yakın düşmana doğru gidip geri dönen
## disk fırlatır. Kart seviyeleri: 1 = açılır (6 sn), 2 = 4 sn, 3 = hasar %60 ve hız artar.

@export var discus_scene: PackedScene
@export var base_interval: float = 6.0
@export var fast_interval: float = 4.0
@export var damage: float = 20.0
@export var strong_multiplier: float = 1.6
@export var discus_speed: float = 550.0
@export var strong_speed: float = 700.0
@export var throw_range: float = 700.0

@onready var throw_timer: Timer = $ThrowTimer

func _ready() -> void:
	GameState.upgrades_changed.connect(_refresh)
	GameState.powers_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var tier := GameState.upgrade_tier("discus")
	if tier <= 0 or not GameState.has_power(GameState.Power.ATTACK):
		throw_timer.stop()
		return
	throw_timer.wait_time = fast_interval if tier >= 2 else base_interval
	if throw_timer.is_stopped():
		throw_timer.start()

func _on_throw_timer_timeout() -> void:
	var target := _nearest_enemy()
	if target == null:
		return
	var tier := GameState.upgrade_tier("discus")
	var discus: Discus = discus_scene.instantiate()
	discus.position = global_position
	discus.direction = (target.global_position - global_position).normalized()
	discus.damage = damage * (strong_multiplier if tier >= 3 else 1.0)
	discus.speed = strong_speed if tier >= 3 else discus_speed
	get_tree().current_scene.add_child(discus)

func _nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best := throw_range * throw_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < best:
			best = dist
			nearest = enemy
	return nearest
