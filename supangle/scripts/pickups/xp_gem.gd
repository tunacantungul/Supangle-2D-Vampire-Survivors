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

## Taşın rengi XP değerinden geliyor ve düşürdüğü canavarın rengiyle eşleşiyor:
## turuncu canavar (1 XP) turuncu, kırmızı (2 XP) kırmızı, mor tank (7 XP) mor
## taş bırakır. Böylece yerdeki taşın değeri uzaktan okunuyor.
## Katsayılar canavar çizimlerinin baskın renginden türetildi; taş görseli mavi
## çizildiği (#4fa8e8) ve modulate çarpma yaptığı için oranlar bu şekilde.
## Liste büyük değerden küçüğe taranır.
const GEM_TIERS: Array = [
	{"min_xp": 5, "modulate": Color(2.35, 0.55, 0.8)},
	{"min_xp": 2, "modulate": Color(2.64, 0.41, 0.3)},
	{"min_xp": 0, "modulate": Color(3.23, 1.1, 0.0)},
]

var _player: Player

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	for tier: Dictionary in GEM_TIERS:
		if xp_value >= tier["min_xp"]:
			sprite.modulate = tier["modulate"]
			break

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or _player.health <= 0.0:
		return
	# Havadayken yerdekiler toplanmaz; taş ne çekilir ne alınır.
	if _player.is_flying:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= collect_radius:
		GameState.gain_xp(xp_value)
		queue_free()
		return
	var tier := mini(GameState.upgrade_tier("magnet"), MAGNET_MULT.size() - 1)
	if dist <= base_magnet_radius * MAGNET_MULT[tier]:
		global_position = global_position.move_toward(_player.global_position, fly_speed * delta)
