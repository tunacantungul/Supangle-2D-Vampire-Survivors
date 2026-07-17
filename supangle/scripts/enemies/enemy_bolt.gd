extends Area2D
## Boss mermisi: düz gider, oyuncuya çarpınca hasar verir.

var direction := Vector2.RIGHT
var damage := 12.0

@export var speed: float = 520.0

func _ready() -> void:
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage)
	queue_free()

func _on_life_timer_timeout() -> void:
	queue_free()
