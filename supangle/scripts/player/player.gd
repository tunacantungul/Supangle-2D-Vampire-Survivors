class_name Player
extends CharacterBody2D
## Oyuncu: hareket, can ve hasar alma.
## Ölümsüzlük gücü varken hiçbir hasar işlemez ve karakter altın bir aura ile parlar.

signal health_changed(current: float, max_value: float)
signal died

@export var move_speed: float = 340.0
@export var max_health: float = 100.0
## Hasar aldıktan sonraki kısa dokunulmazlık süresi.
@export var invulnerability_time: float = 0.4

## "armor" kartı: kademe başına hasar azaltma oranı.
const ARMOR_REDUCTION := [0.0, 0.2, 0.35]

var health: float

var _invuln_left: float = 0.0
var _base_max_health: float
var _vitality_applied: int = 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var divine_aura: Sprite2D = $DivineAura

func _ready() -> void:
	add_to_group("player")
	_base_max_health = max_health
	health = max_health
	health_changed.emit(health, max_health)
	divine_aura.visible = GameState.has_power(GameState.Power.IMMORTALITY)
	GameState.upgrades_changed.connect(_on_upgrades_changed)
	GameState.enemy_killed.connect(_on_enemy_killed)
	_on_upgrades_changed()

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# "speed" kartı: seviye başına %20 hareket hızı.
	var speed_mult := 1.0 + 0.2 * GameState.upgrade_tier("speed")
	velocity = input_dir * move_speed * speed_mult
	move_and_slide()
	_update_animation(input_dir)
	if _invuln_left > 0.0:
		_invuln_left -= delta

## Yön animasyonu: baskın eksene göre seçilir.
## Şimdilik yalnızca "run_forward" (aşağı yürüyüş) gerçek çizim; run_back /
## run_left / run_right aynı kareleri kullanıyor — artist kareleri çizince
## player.tscn'deki SpriteFrames içinde sadece o animasyonların kareleri değişecek.
func _update_animation(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		sprite.play("idle")
		return
	if absf(input_dir.x) > absf(input_dir.y):
		sprite.play("run_right" if input_dir.x > 0.0 else "run_left")
	else:
		sprite.play("run_forward" if input_dir.y > 0.0 else "run_back")

## "vitality" kartı: seviye başına +25 azami can ve aynı miktarda iyileşme.
func _on_upgrades_changed() -> void:
	var tier := GameState.upgrade_tier("vitality")
	if tier == _vitality_applied:
		return
	var gained := (tier - _vitality_applied) * 25.0
	_vitality_applied = tier
	max_health = _base_max_health + tier * 25.0
	health = clampf(health + maxf(gained, 0.0), 0.0, max_health)
	health_changed.emit(health, max_health)

## Düşman temas hasarı.
func take_damage(amount: float) -> void:
	if health <= 0.0 or _invuln_left > 0.0:
		return
	if GameState.has_power(GameState.Power.IMMORTALITY):
		return
	_invuln_left = invulnerability_time
	_flash()
	_apply_damage(amount)

## Tehlikeli zemin hasarı (bulut boşluğu, su). Dokunulmazlık süresini yok sayar.
func take_hazard_damage(amount: float) -> void:
	if health <= 0.0:
		return
	if GameState.has_power(GameState.Power.IMMORTALITY):
		return
	_apply_damage(amount)

## Can küresi vb. toplanınca çağrılır.
func heal(amount: float) -> void:
	if health <= 0.0 or health >= max_health:
		return
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)

func _apply_damage(amount: float) -> void:
	# "armor" kartı: alınan tüm hasarı yüzdesel azaltır.
	var tier := mini(GameState.upgrade_tier("armor"), ARMOR_REDUCTION.size() - 1)
	amount *= 1.0 - ARMOR_REDUCTION[tier]
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_die()

## "bloodprice" kartı: düşman ölümünde şansa bağlı küçük iyileşme.
func _on_enemy_killed() -> void:
	var tier := GameState.upgrade_tier("bloodprice")
	if tier <= 0 or health <= 0.0 or health >= max_health:
		return
	var chance := 0.2 if tier >= 2 else 0.1
	if randf() >= chance:
		return
	var heal_amount := 8.0 if tier >= 2 else 5.0
	health = minf(health + heal_amount, max_health)
	health_changed.emit(health, max_health)

func _flash() -> void:
	sprite.modulate = Color(1.0, 0.35, 0.35)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)

func _die() -> void:
	died.emit()
	hide()
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	GameState.game_over.call_deferred()
