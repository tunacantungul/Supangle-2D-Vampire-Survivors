class_name Bolt
extends Area2D
## Fırlatılan kargı: düz gider, düşmana veya duvara çarpınca yok olur.

var direction := Vector2.RIGHT
var damage := 20.0

@export var speed: float = 900.0

func _ready() -> void:
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.take_damage(damage)
	queue_free()

func _on_life_timer_timeout() -> void:
	queue_free()
