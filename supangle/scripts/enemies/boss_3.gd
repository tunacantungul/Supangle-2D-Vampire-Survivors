extends Boss
## Savaş Vekili (Bölüm 3 bossu, Athena'nın şampiyonu):
## etrafına asker (minyon) çağırır ve telegraflı alan ezme saldırısı yapar.

enum SlamPhase { COOLDOWN, TELEGRAPH }

@export var minion_scene: PackedScene
@export var summon_count: int = 3
@export var summon_cooldown: float = 6.0
@export var slam_cooldown: float = 4.0
@export var slam_telegraph_time: float = 0.9
@export var slam_radius: float = 1000.0
@export var slam_damage: float = 25.0

var _slam_phase: int = SlamPhase.COOLDOWN

@onready var summon_timer: Timer = $SummonTimer
@onready var slam_timer: Timer = $SlamTimer
@onready var slam_ring: Sprite2D = $SlamRing

func _ready() -> void:
	super._ready()
	slam_ring.visible = false
	summon_timer.wait_time = summon_cooldown
	summon_timer.start()
	slam_timer.wait_time = slam_cooldown
	slam_timer.start()

func _on_summon_timer_timeout() -> void:
	if minion_scene == null:
		return
	for i in summon_count:
		var minion: Node2D = minion_scene.instantiate()
		var angle := TAU * i / summon_count + randf() * 0.5
		minion.position = position + Vector2.from_angle(angle) * 600.0
		get_parent().add_child(minion)
	summon_timer.start()

func _on_slam_timer_timeout() -> void:
	match _slam_phase:
		SlamPhase.COOLDOWN:
			# Uyarı: bossun etrafında hasar alanı halkası belirir.
			_slam_phase = SlamPhase.TELEGRAPH
			slam_ring.visible = true
			slam_ring.modulate = Color(1, 1, 1, 0.7)
			slam_timer.wait_time = slam_telegraph_time
			slam_timer.start()
		SlamPhase.TELEGRAPH:
			slam_ring.visible = false
			if _player != null and is_instance_valid(_player):
				if global_position.distance_to(_player.global_position) <= slam_radius:
					_player.take_damage(GameState.scaled_enemy_damage(slam_damage))
			_slam_phase = SlamPhase.COOLDOWN
			slam_timer.wait_time = slam_cooldown
			slam_timer.start()
