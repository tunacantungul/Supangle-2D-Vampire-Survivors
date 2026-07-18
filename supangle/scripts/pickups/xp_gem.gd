extends Node2D
## Düşmanlardan düşen XP taşı (Vampire Survivors tarzı).
## Oyuncu çekim menziline girince taşa doğru uçar, temas menzilinde toplanır.
## "magnet" kartı (Kehribar Tılsımı) çekim menzilini büyütür.

@export var xp_value: int = 1
@export var base_magnet_radius: float = 360.0
@export var collect_radius: float = 135.0
@export var fly_speed: float = 2200.0

## "magnet" kartı kademelerine göre çekim menzili çarpanı (0 = kart yok).
const MAGNET_MULT := [1.0, 1.1, 2.0]

var _player: Player

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or _player.health <= 0.0:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= collect_radius:
		GameState.gain_xp(xp_value)
		queue_free()
		return
	var tier := mini(GameState.upgrade_tier("magnet"), MAGNET_MULT.size() - 1)
	if dist <= base_magnet_radius * MAGNET_MULT[tier]:
		global_position = global_position.move_toward(_player.global_position, fly_speed * delta)
