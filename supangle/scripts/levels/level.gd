extends Node2D
## Tek harita akışı: oyuncu kesintisiz seviye atlar; belirli seviyelere gelince
## sırayla üç boss'un arenası belirir. Boss yenildikçe Zeus'un gazabı artar
## (yeni mob türü, daha çok yıldırım, daha sert hasar). Üçüncü boss ölünce
## Olympos'tan kaçış kapısı açılır.
##
## Güç kaybı sırası (boss sırasıyla aynı): ölümsüzlük -> uçuş -> tanrısal güç.
## İlk boss dövüşten ÖNCE konuşup gücü alır (ölümsüz olarak dövüşmek anlamsız),
## diğer ikisi dövüşten SONRA.

## Hedef okunun renkleri: arena kızıl, açılan kapı yeşil.
const ARENA_ARROW_COLOR := Color(1.0, 0.36, 0.24)
const GATE_ARROW_COLOR := Color(0.42, 1.0, 0.55)

## Kaç boss yenildiğine göre düşman hasarı çarpanı (Zeus'un gazabı artıyor).
## 0 boss / 1 boss / 2 boss / (3 boss = oyun bitti).
const DAMAGE_RAMP := [1.0, 1.15, 1.3, 1.3]
## Yıldırım sıklığı [min, max]. İlk boss sonrası başlar, ikinciden sonra sıklaşır.
const LIGHTNING_AFTER_1 := Vector2(2.5, 4.5)
const LIGHTNING_AFTER_2 := Vector2(1.8, 3.5)

## Sırasıyla üç boss sahnesi (Minotaur, Anka, Kyklop).
@export var boss_scenes: Array[PackedScene] = []
## Her boss'un belirdiği oyuncu seviyesi. Ana denge kolu: buradan ayarlanır.
@export var boss_trigger_levels: Array[int] = [8, 18, 30]
## Boss'ların konuşan tanrısı (portre ve ad).
@export var god_names: Array[String] = ["Zeus", "Hermes", "Athena"]
## Üç boss'un diyalogları. 1. dövüşten önce, 2. ve 3. dövüşten sonra oynar.
@export var dialogue_boss_1: Array[String] = []
@export var dialogue_boss_2: Array[String] = []
@export var dialogue_boss_3: Array[String] = []
## Kademeli açılan mob türleri.
@export var enemy_orange: PackedScene
@export var enemy_red: PackedScene
@export var enemy_tank: PackedScene
## Seviye atlama maliyeti çarpanı (1'in altı = daha sık kart).
@export var xp_requirement_mult: float = 1.0

@onready var exit_gate: Area2D = $ExitGate
@onready var dialogue_box: PanelContainer = $UI/DialogueBox
@onready var hud: Control = $UI/HUD
@onready var upgrade_menu: Control = $UI/UpgradeMenu
@onready var _spawner: Node2D = $EnemySpawner
@onready var _lightning: Node2D = $LightningSpawner
@onready var _arenas: Array[Area2D] = [$BossArena1, $BossArena2, $BossArena3]

## Sıradaki boss (0..2); 3 = üçü de yenildi.
var _boss_index: int = 0
## Sıradaki boss'un arenası belirdi mi.
var _arena_armed: bool = false
## Boss sahnede mi (doğdu, henüz ölmedi).
var _boss_active: bool = false
## Arena belirince hazırlanan, girilince ağaca eklenen boss.
var _boss: Boss
## Diyalog bitince ne yapılacağını ayırt eder.
var _dialogue_context: String = ""
## Kart menüsü açıkken biriken ek seviye atlamaları.
var _pending_level_ups: int = 0

func _ready() -> void:
	get_tree().paused = false
	Music.play_main()
	# Tek harita: setup_level bir kez çağrılır ve tüm run'ı sıfırlar.
	GameState.setup_level(0, xp_requirement_mult, DAMAGE_RAMP[0])
	GameState.player_level_changed.connect(_on_player_level_changed)
	GameState.leveled_up.connect(_on_leveled_up)
	upgrade_menu.card_chosen.connect(_on_card_chosen)
	exit_gate.visible = false
	exit_gate.player_entered.connect(_on_gate_entered)
	for i in _arenas.size():
		_arenas[i].triggered.connect(_on_arena_triggered.bind(i))
	dialogue_box.finished.connect(_on_dialogue_finished)
	hud.set_objective("")
	_apply_camera_limits()
	_maybe_arm_next()

## Arenaya hiç girilmeden sahneden çıkılırsa hazırlanan boss sızmasın.
func _exit_tree() -> void:
	if _boss != null and is_instance_valid(_boss) and _boss.get_parent() == null:
		_boss.free()

## --- Boss sırası ---

## Sıradaki boss'un tetik seviyesine gelindiyse arenasını belirtir.
## Hem seviye atlayınca hem de bir boss yenilince çağrılır (oyuncu bir sonraki
## eşiği çoktan geçmiş olabilir).
func _maybe_arm_next() -> void:
	if _boss_index >= _arenas.size():
		return
	if _arena_armed or _boss_active:
		return
	if GameState.player_level < boss_trigger_levels[_boss_index]:
		return
	_arena_armed = true
	_prepare_boss()
	_arenas[_boss_index].arm()
	hud.set_objective("Bir tanrı seni bekliyor!")
	hud.point_to(_arenas[_boss_index], ARENA_ARROW_COLOR)

func _on_player_level_changed(_level: int) -> void:
	_maybe_arm_next()

## Boss'u önceden oluşturur ama ağaca eklemez: girildiği kare sadece add_child
## yapsın, örnekleme takılması olmasın.
func _prepare_boss() -> void:
	if _boss != null and is_instance_valid(_boss):
		return
	if _boss_index >= boss_scenes.size() or boss_scenes[_boss_index] == null:
		return
	_boss = boss_scenes[_boss_index].instantiate()
	_boss.boss_died.connect(_on_boss_died)

func _on_arena_triggered(index: int) -> void:
	if index != _boss_index or _boss_active:
		return
	hud.clear_arrow()
	if _boss_index == 0:
		# Zeus önce konuşup ölümsüzlüğü alır, dövüş ölümlü olarak geçer.
		hud.set_objective("")
		_dialogue_context = "boss1_before"
		get_tree().paused = true
		dialogue_box.start(god_names[0], dialogue_boss_1)
	else:
		_spawn_boss()

## Bossu arenaya koyar ve dövüş müziğini başlatır.
func _spawn_boss() -> void:
	_prepare_boss()
	if _boss == null or not is_instance_valid(_boss):
		return
	_boss.position = _arenas[_boss_index].position
	add_child(_boss)
	_boss_active = true
	Music.play_boss()
	hud.set_objective("Boss'u yen!")

func _on_boss_died() -> void:
	_boss_active = false
	Music.play_main()
	match _boss_index:
		0:
			# Diyalog dövüşten önce yaşandı; şimdi Zeus'un gazabı başlar.
			_start_phase(1)
			_advance_to_next_boss()
		1:
			_dialogue_context = "boss2_after"
			get_tree().paused = true
			dialogue_box.start(god_names[1], dialogue_boss_2)
		2:
			_dialogue_context = "boss3_after"
			get_tree().paused = true
			dialogue_box.start(god_names[2], dialogue_boss_3)

## Bir boss yenilince sıradakine geçer ve gerekirse hemen belirtir.
func _advance_to_next_boss() -> void:
	_boss_index += 1
	_arena_armed = false
	_boss = null
	hud.set_objective("")
	_maybe_arm_next()

## Boss yenildikçe zorluk kademesi: yeni mob türü, daha sert hasar, yıldırım.
func _start_phase(phase: int) -> void:
	GameState.enemy_damage_mult = DAMAGE_RAMP[phase]
	if phase == 1:
		var pool: Array[PackedScene] = [enemy_orange, enemy_red]
		var weights: Array[float] = [3.0, 2.0]
		_spawner.enemy_scenes = pool
		_spawner.spawn_weights = weights
		_lightning.set_frequency(LIGHTNING_AFTER_1.x, LIGHTNING_AFTER_1.y)
		_lightning.begin()
	elif phase == 2:
		var pool: Array[PackedScene] = [enemy_orange, enemy_red, enemy_tank]
		var weights: Array[float] = [4.0, 3.0, 1.5]
		_spawner.enemy_scenes = pool
		_spawner.spawn_weights = weights
		_lightning.set_frequency(LIGHTNING_AFTER_2.x, LIGHTNING_AFTER_2.y)

## --- Diyalog / güç kaybı ---

func _on_dialogue_finished() -> void:
	match _dialogue_context:
		"boss1_before":
			_lose_power_then(_spawn_boss)
		"boss2_after":
			_lose_power_then(_after_boss2_dialogue)
		"boss3_after":
			_lose_power_then(_end_run)

## Hermes yenilip uçuş gidince: mor tank açılır, yıldırım sıklaşır, sıradaki
## boss'a geçilir.
func _after_boss2_dialogue() -> void:
	_start_phase(2)
	_advance_to_next_boss()

## Güç kaybını siyah ekranda gösterir, sonra `after` çalışır. Perde boyunca ağaç
## duraklı kalır (çağıran fonksiyon zaten duraklatmıştı); oyuncu göremediği bir
## sırada canavarlardan hasar almasın diye. Kaybedilen güç = boss sırası.
func _lose_power_then(after: Callable) -> void:
	var power := _boss_index
	GameState.lose_power(power)
	Sfx.play_level_passed()
	await SceneTransition.play_power_loss(
		GameState.power_loss_text(power), func() -> void: pass
	)
	get_tree().paused = false
	after.call()

## Son boss yenildi: sürü ve saldırılar susar, kaçış kapısı açılır.
func _end_run() -> void:
	_clear_swarm()
	exit_gate.visible = true
	exit_gate.activate()
	hud.set_objective("Kaç! Kapı açıldı!")
	hud.point_to(exit_gate, GATE_ARROW_COLOR)

## Sahnedeki bütün canavarları yok eder, doğurmayı ve yıldırımı durdurur,
## oyuncunun saldırılarını gizler. Yalnızca son boss sonrası çağrılır.
func _clear_swarm() -> void:
	if _spawner != null:
		_spawner.stop()
	if _lightning != null and _lightning.has_method("stop"):
		_lightning.stop()
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and not (enemy is Boss):
			enemy.vanish()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.retire_weapons()

func _on_gate_entered() -> void:
	hud.set_objective("")
	hud.clear_arrow()
	GameState.go_to_epilogue()

## --- Seviye atlama / kart seçimi ---

## Gizli hile: Y tuşu XP barını doldurup anında seviye atlatır. Test için.
## InputMap'e eklenmedi; oyun içinde hiçbir yerde görünmesin isteniyor.
## Oyun duraklıyken (kart menüsü, diyalog) girdi buraya ulaşmadığı için kart
## seçiminin ortasında tetiklenemiyor.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode != KEY_Y:
		return
	get_viewport().set_input_as_handled()
	GameState.gain_xp(GameState.xp_required() - GameState.xp)

func _on_leveled_up() -> void:
	Sfx.play_level_up()
	if upgrade_menu.visible:
		_pending_level_ups += 1
		return
	_open_upgrade_menu()

func _open_upgrade_menu() -> void:
	var options := GameState.pick_upgrade_options()
	if options.is_empty():
		get_tree().paused = false
		return
	get_tree().paused = true
	upgrade_menu.open(options)

func _on_card_chosen(id: String) -> void:
	GameState.apply_upgrade(id)
	if _pending_level_ups > 0:
		_pending_level_ups -= 1
		_open_upgrade_menu()
	else:
		get_tree().paused = false

## --- Kamera sınırları ---

## Kamera, $Walls'un çevrelediği alanın dışını göstermez. Oyuncu duvara yaklaşınca
## kamera kenarda durur; oyuncu ekranın o kenarına doğru yürümeye devam eder.
func _apply_camera_limits() -> void:
	var walls := get_node_or_null("Walls") as StaticBody2D
	var camera := get_node_or_null("Player/Camera2D") as Camera2D
	if walls == null or camera == null:
		return
	var bounds := _playable_bounds(walls)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.limit_smoothed = true
	camera.reset_smoothing()

## Duvar dikdörtgenlerinin iç yüzlerinden oynanabilir alanı çıkarır.
func _playable_bounds(walls: StaticBody2D) -> Rect2:
	var rects: Array[Rect2] = []
	for child in walls.get_children():
		var shape_node := child as CollisionShape2D
		if shape_node == null:
			continue
		var rect_shape := shape_node.shape as RectangleShape2D
		if rect_shape == null:
			continue
		var wall_size: Vector2 = (rect_shape.size * shape_node.global_scale).abs()
		rects.append(Rect2(shape_node.global_position - wall_size * 0.5, wall_size))
	if rects.is_empty():
		return Rect2()

	var outer: Rect2 = rects[0]
	for rect in rects:
		outer = outer.merge(rect)
	var center := outer.get_center()
	var left := outer.position.x
	var top := outer.position.y
	var right := outer.end.x
	var bottom := outer.end.y
	for rect in rects:
		var rect_center := rect.get_center()
		if rect.size.x >= rect.size.y:
			if rect_center.y < center.y:
				top = maxf(top, rect.end.y)
			else:
				bottom = minf(bottom, rect.position.y)
		else:
			if rect_center.x < center.x:
				left = maxf(left, rect.end.x)
			else:
				right = minf(right, rect.position.x)
	return Rect2(left, top, right - left, bottom - top)
