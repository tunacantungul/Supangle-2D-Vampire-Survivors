class_name Player
extends CharacterBody2D
## Oyuncu: hareket, can ve hasar alma.
## Ölümsüzlük gücü varken hiçbir hasar işlemez ve karakter altın bir aura ile parlar.

signal health_changed(current: float, max_value: float)
signal died
## Uçuş başlarken/biterken yayılır; HUD göstergesi bunu dinler.
signal flight_changed(flying: bool)
## Her karede bekleme süresini bildirir (kalan, toplam). HUD sayacı için.
signal flight_cooldown_changed(remaining: float, total: float)

@export var move_speed: float = 1100.0
@export var max_health: float = 100.0
## Hasar aldıktan sonraki kısa dokunulmazlık süresi.
@export var invulnerability_time: float = 0.4

## --- Uçuş (sekme) ---
## Havada kalma süresi. Kısa tutuldu: kaçış hamlesi, serbest uçuş değil.
@export var flight_duration: float = 1.1
@export var flight_cooldown: float = 5.0
## Havadayken hız çarpanı; hızlıca yer değiştirebilsin diye küçük bir katkı.
@export var flight_speed_mult: float = 1.25
## Sprite'ın yerden ne kadar yükseleceği (yalnızca görsel; gövde yerde kalır,
## bu yüzden gölge her zaman gerçek iniş noktasını gösterir).
@export var flight_lift: float = 190.0
## Havadayken canavarların önünde çizilsin diye.
@export var flight_z_index: int = 50
## Yükselme/alçalma animasyonunun süresi.
@export var flight_lift_time: float = 0.22
## Bölüm başında uçuşun tetiklenemeyeceği süre. Diyaloglar SPACE ile ilerliyor
## ve oyuncular sahne yüklenirken tuşa basmaya devam ediyor; o basış yeni bölüme
## taşınıp oyun başlar başlamaz uçuşu harcıyordu.
## Perdenin açılma süresinden (0.8 sn) uzun tutuldu: kısa olsaydı koruma ekran
## hâlâ karanlıkken biter ve basış yine boşa giderdi. İlk saniyede düşman
## menzilde olmadığı için kaçış hamlesine ihtiyaç da yok.
@export var input_grace_time: float = 1.0

## "armor" kartı: kademe başına hasar azaltma oranı.
const ARMOR_REDUCTION := [0.0, 0.2, 0.35]

## Uçarken gösterilecek kare: "run_forward"un ilk karesi karakterin öne bakan
## duruşu. Gövde bu duruşta donuyor, kanatlar arkasında çırpınıyor.
const FLIGHT_ANIMATION := "run_forward"
const FLIGHT_FRAME := 0

var health: float
## Havadayken true: hasar almaz, yerdekileri toplayamaz, silahları durur.
var is_flying: bool = false

var _invuln_left: float = 0.0
var _base_max_health: float
var _vitality_applied: int = 0
var _flight_left: float = 0.0
var _flight_cooldown_left: float = 0.0
## Bölüm başındaki girdi koruma süresi; bkz. input_grace_time.
var _input_grace_left: float = 0.0
var _lift_tween: Tween
## Silahlar Player'ın çocuğu; uçuşta hepsi birden durdurulup gizleniyor.
var _weapons: Array[Node] = []
## Boss öldükten sonra silahlar bölüm sonuna kadar kapalı kalır. Uçuş inişi
## onları geri açmasın diye ayrı bir bayrak tutuluyor.
var _weapons_retired: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
## Yalnızca uçarken görünür; sahnede gövde sprite'ından önce geldiği için
## karakterin arkasında çizilir.
@onready var wings: AnimatedSprite2D = $Wings
@onready var divine_aura: Sprite2D = $DivineAura
@onready var landing_shadow: Node2D = $LandingShadow

func _ready() -> void:
	add_to_group("player")
	_base_max_health = max_health
	health = max_health
	health_changed.emit(health, max_health)
	_input_grace_left = input_grace_time
	_refresh_aura()
	_weapons.assign(get_tree().get_nodes_in_group("player_weapons"))
	landing_shadow.visible = false
	# Ölümsüzlük artık bölüm ortasında da kaybedilebiliyor (1. bölümde Zeus onu
	# boss dövüşünden önce alıyor); aura buna anında uymalı.
	GameState.powers_changed.connect(_refresh_aura)
	GameState.upgrades_changed.connect(_on_upgrades_changed)
	GameState.enemy_killed.connect(_on_enemy_killed)
	_on_upgrades_changed()
	flight_cooldown_changed.emit(0.0, flight_cooldown)

## Altın aura yalnızca Ölümsüzlük gücü dururken görünür.
func _refresh_aura() -> void:
	divine_aura.visible = GameState.has_power(GameState.Power.IMMORTALITY)

func _physics_process(delta: float) -> void:
	_tick_flight(delta)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# "speed" kartı: seviye başına %10 hareket hızı.
	var speed_mult := 1.0 + 0.1 * GameState.upgrade_tier("speed")
	if is_flying:
		speed_mult *= flight_speed_mult
	velocity = input_dir * move_speed * speed_mult
	move_and_slide()
	_update_animation(input_dir)
	if _invuln_left > 0.0:
		_invuln_left -= delta

## Yön animasyonu: baskın eksene göre seçilir.
## Yatay kareler sola yürüyüş olarak çizildi; sağa giderken aynı kareler
## flip_h ile aynalanıyor. Diğer üç yönün kendi çizimleri var.
func _update_animation(input_dir: Vector2) -> void:
	# Uçarken duruş dondurulmuş durumda; yön animasyonları devreye girmemeli.
	if is_flying:
		return
	if input_dir == Vector2.ZERO:
		# idle karesi öne bakan çizim, aynalanmış hâli tutarsız duruyor.
		sprite.flip_h = false
		sprite.play("idle")
		return
	if absf(input_dir.x) > absf(input_dir.y):
		var going_right := input_dir.x > 0.0
		sprite.flip_h = going_right
		sprite.play("run_right" if going_right else "run_left")
	else:
		sprite.flip_h = false
		sprite.play("run_forward" if input_dir.y > 0.0 else "run_back")

## --- Uçuş (sekme) ---

## Uçuş yalnızca Uçuş gücü henüz kaybedilmemişken kullanılabilir; 2. bölümün
## sonunda güç gidince tuş sessizce işlevsizleşir.
func can_fly() -> bool:
	return (
		GameState.has_power(GameState.Power.FLIGHT)
		and not is_flying
		and _flight_cooldown_left <= 0.0
		and _input_grace_left <= 0.0
		and health > 0.0
	)

func _tick_flight(delta: float) -> void:
	if _input_grace_left > 0.0:
		_input_grace_left = maxf(_input_grace_left - delta, 0.0)
	if _flight_cooldown_left > 0.0:
		_flight_cooldown_left = maxf(_flight_cooldown_left - delta, 0.0)
		flight_cooldown_changed.emit(_flight_cooldown_left, flight_cooldown)
	if is_flying:
		_flight_left -= delta
		# Süre dolunca iniş zorunlu: oyuncu havada kalmayı seçemez.
		if _flight_left <= 0.0:
			_land()
		return
	if Input.is_action_just_pressed("fly") and can_fly():
		_take_off()

func _take_off() -> void:
	is_flying = true
	_flight_left = flight_duration
	# Canavarların önünde çizilsin.
	z_index = flight_z_index
	landing_shadow.visible = true
	_freeze_pose()
	wings.visible = true
	wings.play("flap")
	_set_weapons_active(false)
	_tween_lift(-flight_lift)
	flight_changed.emit(true)

func _land() -> void:
	is_flying = false
	_flight_cooldown_left = flight_cooldown
	flight_cooldown_changed.emit(_flight_cooldown_left, flight_cooldown)
	z_index = 0
	# Boss öldükten sonra silahlar kapalı kalmalı; iniş onları geri açmasın.
	if not _weapons_retired:
		_set_weapons_active(true)
	sprite.play()
	_tween_lift(0.0)
	# Gölge ve kanatlar, karakter yere değene kadar durur: iniş sırasında da
	# çırpınmaya devam etsinler.
	_lift_tween.tween_callback(_on_landed)
	flight_changed.emit(false)

## Sprite yere değdiğinde: iniş göstergeleri kalkar.
func _on_landed() -> void:
	landing_shadow.visible = false
	wings.visible = false
	wings.stop()

## Uçarken gövde, öne bakan duruşun tek karesinde donuyor; hareket hissini
## arkadaki kanatlar veriyor.
func _freeze_pose() -> void:
	sprite.flip_h = false
	sprite.animation = FLIGHT_ANIMATION
	sprite.frame = FLIGHT_FRAME
	sprite.pause()

## Yalnızca görsel yükselme: gövde ve gölge yerde kaldığı için gölge her zaman
## gerçek iniş noktasını gösterir.
func _tween_lift(target_y: float) -> void:
	if _lift_tween != null and _lift_tween.is_valid():
		_lift_tween.kill()
	_lift_tween = create_tween().set_parallel(true)
	_lift_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_lift_tween.tween_property(sprite, "position:y", target_y, flight_lift_time)
	_lift_tween.tween_property(wings, "position:y", target_y, flight_lift_time)
	_lift_tween.tween_property(divine_aura, "position:y", target_y, flight_lift_time)
	# Sonraki tween_callback'lerin paralel değil, ardıl çalışması için.
	_lift_tween.chain()

## Boss ölünce çağrılır: saldırılar susar ve görselleri kaybolur, tıpkı uçarken
## olduğu gibi. Sürü de yok olduğu için vuracak bir şey kalmıyor; dönen kılıçlar
## ve auralar boş sahnede çalışmaya devam edince tuhaf duruyordu.
## Uçuşa dokunmuyor: güç hâlâ duruyorsa oyuncu kapıya uçarak gidebilir.
func retire_weapons() -> void:
	_weapons_retired = true
	_set_weapons_active(false)

## Uçarken saldırılar durur ve görselleri gizlenir; inince kaldıkları yerden
## devam ederler (process_mode durunca içlerindeki Timer'lar da duruyor).
func _set_weapons_active(active: bool) -> void:
	for weapon in _weapons:
		if not is_instance_valid(weapon):
			continue
		weapon.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		if weapon is CanvasItem:
			weapon.visible = active

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
	# Uçuş bir kaçış hamlesi: havadayken temas hasarı işlemez.
	if is_flying:
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
	# Havadayken zemin tehlikesi de (bulut boşluğu, su) işlemez.
	if is_flying:
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
	# Hem temas hem zemin hasarında çalsın diye burada; Sfx tarafında asgari
	# aralık var, zemin hasarı her karede tetiklendiği için gerekli.
	Sfx.play_player_hurt()
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
	# Değerler bilerek küçük: bölüm başına binlerce düşman ölüyor, bu yüzden
	# ölüm başına yarım candan fazlası oyuncuyu pratikte ölümsüz yapıyordu.
	# Şimdi 5 dakikalık bir bölümde 1. kademe ~1.5, 2. kademe ~3.5 can barı verir.
	var chance := 0.12 if tier >= 2 else 0.08
	if randf() >= chance:
		return
	var heal_amount := 3.0 if tier >= 2 else 2.0
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
