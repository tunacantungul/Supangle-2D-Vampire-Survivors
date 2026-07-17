class_name Enemy
extends CharacterBody2D
## Oyuncuya doğru yürüyen ve temasta hasar veren düşman.
## Tüm düşman tipleri bu scripti kullanır; farklar export değerlerinden gelir.

@export var move_speed: float = 120.0
@export var max_health: float = 30.0
@export var contact_damage: float = 10.0
## Oyuncuyla temas hâlindeyken iki hasar arası süre.
@export var damage_interval: float = 0.8

var health: float

var _player: Player
var _damage_cooldown: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var damage_area: Area2D = $DamageArea

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_player = get_tree().get_first_node_in_group("player") as Player

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var direction := (_player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	_tick_contact_damage(delta)

## Temas hasarı sayacı; boss alt sınıfları da hareketten bağımsız kullanır.
func _tick_contact_damage(delta: float) -> void:
	_damage_cooldown -= delta
	if _damage_cooldown <= 0.0 and damage_area.overlaps_body(_player):
		_player.take_damage(contact_damage)
		_damage_cooldown = damage_interval

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	_flash()
	if health <= 0.0:
		_die()

func _flash() -> void:
	sprite.modulate = Color(1.8, 1.8, 1.8)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _die() -> void:
	GameState.register_kill()
	queue_free()
