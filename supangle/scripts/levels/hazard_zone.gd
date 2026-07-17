extends Area2D
## Tehlikeli zemin (bulut boşluğu, su vb.).
## Uçuş gücü varken zararsızdır; güç kaybedilince içinde durmak sürekli hasar verir.

@export var damage_per_second: float = 30.0

func _physics_process(delta: float) -> void:
	if GameState.has_power(GameState.Power.FLIGHT):
		return
	for body in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.take_hazard_damage(damage_per_second * delta)
