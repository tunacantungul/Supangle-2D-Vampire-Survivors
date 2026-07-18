class_name Discus
extends Area2D
## Fırlatılan disk: hedefe doğru gider, menzil sonunda oyuncuya geri döner.
## Gidiş ve dönüş bacaklarının her birinde aynı düşmana bir kez hasar verir.

var direction := Vector2.RIGHT
var damage := 20.0
var speed := 550.0

@export var out_distance: float = 420.0
@export var spin_speed: float = 14.0
## Dönüşte oyuncuya bu kadar yaklaşınca kaybolur.
@export var catch_radius: float = 34.0

var _returning: bool = false
var _travelled: float = 0.0
var _hit_this_leg: Dictionary = {}
var _player: Player

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta
	if not _returning:
		var step := speed * delta
		position += direction * step
		_travelled += step
		if _travelled >= out_distance:
			_returning = true
			_hit_this_leg.clear()
		return
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return
	var to_player := _player.global_position - global_position
	if to_player.length() <= catch_radius:
		queue_free()
		return
	global_position += to_player.normalized() * speed * 1.15 * delta

func _on_body_entered(body: Node2D) -> void:
	var enemy := body as Enemy
	if enemy == null:
		return
	var id := enemy.get_instance_id()
	if _hit_this_leg.has(id):
		return
	_hit_this_leg[id] = true
	enemy.take_damage(damage)
