extends Node2D
## Menzildeki en yakın düşmana kargı fırlatır (eski "büyü ışını", temaya uysun
## diye kargıya çevrildi). Başlangıçta kapalıdır: "bolt" kartıyla açılır.
## Kart seviyeleri: 1 = açılır (8 sn), 2 = hızlanır (4 sn), 3 = hasar iki katı.

@export var bolt_scene: PackedScene
@export var base_interval: float = 8.0
@export var fast_interval: float = 4.0
@export var bolt_damage: float = 30.0
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
	var tier := GameState.upgrade_tier("bolt")
	# "İkiz Kargı" (4. kademe): aynı anda 2 ayrı hedefe atış.
	var targets := _nearest_enemies(2 if tier >= 4 else 1)
	for target in targets:
		var bolt: Bolt = bolt_scene.instantiate()
		bolt.position = global_position
		bolt.direction = (target.global_position - global_position).normalized()
		bolt.damage = bolt_damage * (2.0 if tier >= 3 else 1.0)
		get_tree().current_scene.add_child(bolt)

## Menzildeki düşmanları yakınlık sırasına dizip ilk `count` tanesini döndürür.
func _nearest_enemies(count: int) -> Array[Node2D]:
	var in_range: Array = []
	var max_dist := attack_range * attack_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < max_dist:
			in_range.append({"enemy": enemy, "dist": dist})
	in_range.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.dist < b.dist)
	var result: Array[Node2D] = []
	for i in mini(count, in_range.size()):
		result.append(in_range[i].enemy)
	return result
