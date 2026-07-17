extends Boss
## Gök Bekçisi (Bölüm 1 bossu): periyodik olarak parlayıp oyuncuya doğru hücum eder.

enum Phase { COOLDOWN, TELEGRAPH, DASH }

@export var dash_speed: float = 750.0
@export var dash_duration: float = 0.55
@export var dash_cooldown: float = 3.0
@export var telegraph_duration: float = 0.4

var _phase: int = Phase.COOLDOWN
var _dash_dir := Vector2.ZERO

@onready var phase_timer: Timer = $PhaseTimer

func _ready() -> void:
	super._ready()
	phase_timer.wait_time = dash_cooldown
	phase_timer.start()

func _physics_process(delta: float) -> void:
	if _phase == Phase.DASH:
		velocity = _dash_dir * dash_speed
		move_and_slide()
		_tick_contact_damage(delta)
		return
	super._physics_process(delta)

func _on_phase_timer_timeout() -> void:
	match _phase:
		Phase.COOLDOWN:
			# Hücum uyarısı: sarı parlama.
			_phase = Phase.TELEGRAPH
			sprite.modulate = Color(1.8, 1.8, 0.6)
			phase_timer.wait_time = telegraph_duration
			phase_timer.start()
		Phase.TELEGRAPH:
			sprite.modulate = Color.WHITE
			if _player != null and is_instance_valid(_player):
				_dash_dir = (_player.global_position - global_position).normalized()
			_phase = Phase.DASH
			phase_timer.wait_time = dash_duration
			phase_timer.start()
		Phase.DASH:
			_phase = Phase.COOLDOWN
			phase_timer.wait_time = dash_cooldown
			phase_timer.start()
