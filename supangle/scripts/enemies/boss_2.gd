extends Boss
## Fırtına Habercisi (Bölüm 2 bossu): mesafesini korur ve oyuncuya 3'lü mermi yelpazesi atar.

@export var bolt_scene: PackedScene
@export var fire_cooldown: float = 2.0
@export var bolt_damage: float = 12.0
## Oyuncuyla korumaya çalıştığı mesafe.
@export var preferred_distance: float = 380.0

@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	super._ready()
	fire_timer.wait_time = fire_cooldown
	fire_timer.start()

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var to_player := _player.global_position - global_position
	var direction := to_player.normalized()
	if to_player.length() < preferred_distance:
		direction = -direction
	velocity = direction * move_speed
	move_and_slide()
	_tick_contact_damage(delta)

func _on_fire_timer_timeout() -> void:
	if bolt_scene == null or _player == null or not is_instance_valid(_player):
		return
	var base_angle := (_player.global_position - global_position).angle()
	for offset in [-0.25, 0.0, 0.25]:
		var bolt: Node2D = bolt_scene.instantiate()
		bolt.position = global_position
		bolt.direction = Vector2.from_angle(base_angle + offset)
		bolt.damage = bolt_damage
		get_parent().add_child(bolt)
