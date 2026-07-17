extends Node2D
## Menzildeki en yakın düşmana otomatik büyü mermisi fırlatır.
## Başlangıçta kapalıdır: "bolt" kartıyla açılır.
## Kart seviyeleri: 1 = açılır (15 sn), 2 = hızlanır (8 sn), 3 = hasar iki katı.

@export var bolt_scene: PackedScene
@export var base_interval: float = 15.0
@export var fast_interval: float = 8.0
## 15 sn'de tek atış olduğu için vuruş başına hasar yüksek tutuldu.
@export var bolt_damage: float = 40.0
@export var attack_range: float = 750.0

@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	GameState.upgrades_changed.connect(_refresh)
	GameState.powers_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var tier := GameState.upgrade_tier("bolt")
	if tier <= 0 or not GameState.has_power(GameState.Power.ATTACK):
		fire_timer.stop()
		return
	fire_timer.wait_time = fast_interval if tier >= 2 else base_interval
	if fire_timer.is_stopped():
		fire_timer.start()

func _on_fire_timer_timeout() -> void:
	var target := _nearest_enemy()
	if target == null:
		return
	var bolt: Bolt = bolt_scene.instantiate()
	bolt.position = global_position
	bolt.direction = (target.global_position - global_position).normalized()
	bolt.damage = bolt_damage * (2.0 if GameState.upgrade_tier("bolt") >= 3 else 1.0)
	get_tree().current_scene.add_child(bolt)

func _nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var best := attack_range * attack_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < best:
			best = dist
			nearest = enemy
	return nearest
