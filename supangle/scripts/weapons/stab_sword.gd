extends Node2D
## Oyuncunun temel silahı: yakın mesafe kılıç saplaması.
## Bekleme süresi dolunca menzildeki en yakın düşmana doğru kılıç belirip
## ileri uzanır, geri çekilir ve kaybolur.
## "stab" kartları: 1. seviye çift saplama, 2. seviye %50 hasar artışı.

## Temel düşmanı (30 can) tek vuruşta düşürecek şekilde ayarlı.
@export var damage: float = 35.0
@export var cooldown: float = 3.0
## Saplamanın tetiklenmesi için düşmanın bu menzilde olması gerekir.
@export var trigger_range: float = 240.0
## Kılıcın oyuncudan başlangıç uzaklığı ve ileri uzanma mesafesi.
@export var start_offset: float = 26.0
@export var thrust_distance: float = 72.0
## Çift saplamada iki saplama arası bekleme.
@export var double_stab_gap: float = 0.22

var _armed: bool = false
var _stabbing: bool = false
var _hit_this_stab: Dictionary = {}

@onready var sword: Area2D = $Sword
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	sword.visible = false
	sword.monitoring = false
	if not GameState.has_power(GameState.Power.ATTACK):
		set_physics_process(false)
		return
	cooldown_timer.wait_time = cooldown
	cooldown_timer.start()

func _physics_process(_delta: float) -> void:
	if not _armed or _stabbing:
		return
	var target := _nearest_enemy()
	if target == null:
		return
	_armed = false
	_do_stab_sequence(target)

func _on_cooldown_timer_timeout() -> void:
	_armed = true

func _do_stab_sequence(first_target: Node2D) -> void:
	_stabbing = true
	var stab_count := 2 if GameState.upgrade_tier("stab") >= 1 else 1
	for i in stab_count:
		var target := first_target if i == 0 else _nearest_enemy()
		if target == null or not is_instance_valid(target):
			break
		await _stab_at(target)
		if i < stab_count - 1:
			await get_tree().create_timer(double_stab_gap, false).timeout
	_stabbing = false
	cooldown_timer.start()

## Tek bir saplama animasyonu: hedefe dönük çık, uzan, geri çekil.
func _stab_at(target: Node2D) -> void:
	_hit_this_stab.clear()
	var dir := (target.global_position - global_position).normalized()
	sword.rotation = dir.angle() + PI / 2.0
	sword.position = dir * start_offset
	sword.visible = true
	sword.monitoring = true
	var tween := create_tween()
	tween.tween_property(sword, "position", dir * (start_offset + thrust_distance), 0.15)
	tween.tween_property(sword, "position", dir * start_offset, 0.13)
	await tween.finished
	sword.visible = false
	sword.monitoring = false

func _on_sword_body_entered(body: Node2D) -> void:
	if not _stabbing:
		return
	var enemy := body as Enemy
	if enemy == null:
		return
	# Aynı saplamada aynı düşmana bir kez vur.
	var id := enemy.get_instance_id()
	if _hit_this_stab.has(id):
		return
	_hit_this_stab[id] = true
	var dmg := damage * (1.5 if GameState.upgrade_tier("stab") >= 2 else 1.0)
	enemy.take_damage(dmg)

func _nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	# "Savaş Çığlığı" (stab 3. kademe): menzil %50 artar.
	var effective_range := trigger_range * (1.5 if GameState.upgrade_tier("stab") >= 3 else 1.0)
	var best := effective_range * effective_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null:
			continue
		var dist := global_position.distance_squared_to(enemy.global_position)
		if dist < best:
			best = dist
			nearest = enemy
	return nearest
