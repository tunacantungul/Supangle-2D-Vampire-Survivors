extends Node2D
## Tek bir yıldırım düşüşü: önce yerde yarı saydam telegraf çemberi belirir,
## süre dolunca yıldırım düşer ve alandaki oyuncu ile düşmanlara hasar verir.

## Telegraf çemberinin görünme süresi (yıldırım düşmeden önce).
@export var telegraph_time: float = 1.0
@export var damage: float = 30.0

@onready var telegraph: Sprite2D = $Telegraph
@onready var bolt_sprite: Sprite2D = $BoltSprite
@onready var damage_area: Area2D = $DamageArea
@onready var strike_timer: Timer = $StrikeTimer

func _ready() -> void:
	bolt_sprite.visible = false
	strike_timer.wait_time = telegraph_time
	strike_timer.start()
	var tween := create_tween().set_loops()
	tween.tween_property(telegraph, "modulate:a", 0.45, 0.25)
	tween.tween_property(telegraph, "modulate:a", 1.0, 0.25)

func _on_strike_timer_timeout() -> void:
	bolt_sprite.visible = true
	telegraph.modulate = Color(1.6, 1.6, 1.2)
	for body in damage_area.get_overlapping_bodies():
		if body is Player:
			body.take_damage(damage)
		elif body is Enemy:
			body.take_damage(damage)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
