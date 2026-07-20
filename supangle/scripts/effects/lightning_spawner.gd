extends Node2D
## Zeus'un gazabı: haritaya rastgele yıldırımlar düşürür.
## Tek harita düzeninde ilk boss (Zeus ölümsüzlüğü aldıktan) sonra level
## tarafından begin() ile başlatılır ve ikinci boss'tan sonra sıklaşır.

@export var lightning_scene: PackedScene
@export var min_interval: float = 2.0
@export var max_interval: float = 4.0
## Yıldırımlar oyuncunun etrafında bu yarıçap içinde rastgele bir noktaya düşer
## (tamamen rastgele harita noktası çoğu zaman ekran dışında kalacağı için).
@export var near_player_radius: float = 2900.0
## Düşülebilecek alan sınırı (duvarların içi).
@export var bounds: Rect2 = Rect2(-7000, -4300, 14000, 8600)
## Açıkken sahneye eklenir eklenmez başlar; kapalıyken begin() beklenir.
@export var autostart: bool = true

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	if autostart:
		_schedule_next()

## Yıldırımları başlatır (autostart kapalıysa dışarıdan çağrılır).
func begin() -> void:
	_schedule_next()

## Sıklığı değiştirir; bir sonraki yıldırım yeni aralıkla planlanır.
func set_frequency(new_min: float, new_max: float) -> void:
	min_interval = new_min
	max_interval = new_max

## Yıldırımları durdurur (son boss yenilince).
func stop() -> void:
	spawn_timer.stop()

func _on_spawn_timer_timeout() -> void:
	_spawn_strike()
	_schedule_next()

func _schedule_next() -> void:
	spawn_timer.wait_time = randf_range(min_interval, max_interval)
	spawn_timer.start()

func _spawn_strike() -> void:
	if lightning_scene == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var offset := Vector2.from_angle(randf() * TAU) * randf_range(360.0, near_player_radius)
	var pos := player.global_position + offset
	pos.x = clampf(pos.x, bounds.position.x, bounds.end.x)
	pos.y = clampf(pos.y, bounds.position.y, bounds.end.y)
	var strike: Node2D = lightning_scene.instantiate()
	strike.position = pos
	get_parent().add_child(strike)
