extends Node2D
## Her bölüm sahnesinin ortak akışı:
## kota dolunca boss arenası aktifleşir -> arenaya girince boss doğar ->
## boss ölünce kapı belirir -> kapıya girince tanrı diyaloğu -> güç kaybı -> sonraki bölüm.

## Hedef okunun renkleri: arena kızıl, açılan kapı yeşil.
const ARENA_ARROW_COLOR := Color(1.0, 0.36, 0.24)
const GATE_ARROW_COLOR := Color(0.42, 1.0, 0.55)

@export var kill_quota: int = 15
## Seviye atlama maliyeti çarpanı: 1'in altı bu bölümde daha sık kart demek.
@export var xp_requirement_mult: float = 1.0
## Düşman hasarı çarpanı: 1'in altı bu bölümde daha az hasar demek.
@export var enemy_damage_mult: float = 1.0
@export var god_name: String = "Zeus"
## Vurgulanacak kelimeler satır metnine BBCode ile yazılır: [shake]ölümsüz[/shake].
@export var dialogue_lines: Array[String] = []
## Bu bölümün sonunda kaybedilecek güç (GameState.Power sırasıyla aynı).
@export_enum("Ölümsüzlük:0", "Uçuş:1", "Tanrısal Güç:2") var power_to_lose: int = 0
## Açıkken diyalog ve güç kaybı boss dövüşünden ÖNCE yaşanır: tanrı arenada
## karşına çıkar, gücü alır, dövüş o güç olmadan geçer. 1. bölümde açık —
## ölümsüzlük gidince can barı açılıyor ve Zeus'un bossuyla ölümlü olarak
## dövüşmek hikâyeyle örtüşüyor.
## Sonraki bölümlerde kapalı olmalı: 3. bölümde kaybedilen güç saldırı gücü,
## onu dövüşten önce almak bossu öldürülemez yapardı.
@export var dialogue_before_boss: bool = false
## Bölüm sonu bossu.
@export var boss_scene: PackedScene

@onready var exit_gate: Area2D = $ExitGate
@onready var boss_arena: Area2D = $BossArena
@onready var dialogue_box: PanelContainer = $UI/DialogueBox
@onready var hud: Control = $UI/HUD
@onready var upgrade_menu: Control = $UI/UpgradeMenu

var _arena_armed: bool = false
## dialogue_before_boss akışında diyalog ve güç kaybı yaşandı mı. Kapıya
## varıldığında ikinci kez diyalog başlamasın diye tutuluyor.
var _power_lost: bool = false
## Bölüm başında hazırlanan, arenaya girilince ağaca eklenen boss.
var _boss: Boss
## Kart menüsü açıkken biriken ek seviye atlamaları (aynı karede çoklu ölüm).
var _pending_level_ups: int = 0

func _ready() -> void:
	get_tree().paused = false
	# Bölümler arasında kaldığı yerden devam eder, baştan başlamaz.
	Music.play_main()
	GameState.setup_level(kill_quota, xp_requirement_mult, enemy_damage_mult)
	GameState.kills_changed.connect(_on_kills_changed)
	GameState.leveled_up.connect(_on_leveled_up)
	upgrade_menu.card_chosen.connect(_on_card_chosen)
	exit_gate.visible = false
	exit_gate.player_entered.connect(_on_gate_entered)
	boss_arena.triggered.connect(_on_arena_triggered)
	dialogue_box.finished.connect(_on_dialogue_finished)
	_apply_camera_limits()
	_prepare_boss()

## Boss'u bölüm başında oluşturur ama ağaca eklemez. Örnekleme maliyeti
## (düğüm kurulumu, script başlatma) arenaya girildiği kareye denk gelince
## gözle görülür bir takılma yapıyordu; artık o kare sadece add_child yapıyor.
func _prepare_boss() -> void:
	if boss_scene == null:
		return
	_boss = boss_scene.instantiate()
	_boss.boss_died.connect(_on_boss_died)

## Arenaya hiç girilmeden bölümden çıkılırsa hazırlanan boss sızmasın.
func _exit_tree() -> void:
	if _boss != null and is_instance_valid(_boss) and _boss.get_parent() == null:
		_boss.free()

## --- Kamera sınırları ---

## Kamera, $Walls'un çevrelediği alanın dışını göstermez. Oyuncu duvara yaklaşınca
## kamera kenarda durur; oyuncu ekranın o kenarına doğru yürümeye devam eder.
## Sınırdan uzaklaşınca kamera yeniden takibe geçer.
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
## Her duvar, uzun kenarına ve merkeze göre hangi tarafta olduğuna bakılarak
## ilgili sınırı içeri çeker; böylece duvarları taşıyınca kamera da uyum sağlar.
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
			# Yatay duvar: tavanı ya da tabanı belirler.
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

## --- Seviye atlama / kart seçimi ---

## Gizli hile: Y tuşu XP barını doldurup anında seviye atlatır. Test için.
## InputMap'e eklenmedi, doğrudan tuş kodu okunuyor: oyun içinde hiçbir yerde
## görünmesin isteniyor.
## Oyun duraklıyken (kart menüsü, diyalog) girdi buraya ulaşmadığı için kart
## seçiminin ortasında tetiklenemiyor.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode != KEY_Y:
		return
	get_viewport().set_input_as_handled()
	# Eksik kalan miktarı vermek, normal XP toplama yolunu kullanır: seviye
	# atlama, sinyaller ve kart menüsü kendiliğinden devreye girer.
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

func _on_kills_changed(current: int, _required: int) -> void:
	if current >= kill_quota and not _arena_armed:
		_arena_armed = true
		boss_arena.arm()
		hud.set_objective("Boss arenasına git!")
		hud.point_to(boss_arena, ARENA_ARROW_COLOR)

func _on_arena_triggered() -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	hud.clear_arrow()
	# Tanrı önce konuşup gücü alıyor; boss ancak ondan sonra geliyor.
	if dialogue_before_boss and not _power_lost:
		hud.set_objective("")
		get_tree().paused = true
		dialogue_box.start(god_name, dialogue_lines)
		return
	_spawn_boss()

## Bossu arenaya koyar ve dövüş müziğini başlatır.
func _spawn_boss() -> void:
	if _boss == null or not is_instance_valid(_boss):
		return
	_boss.position = boss_arena.position
	add_child(_boss)
	Music.play_boss()
	hud.set_objective("Boss'u yen!")

func _on_boss_died() -> void:
	# Ana tema, boss dövüşünden önce kaldığı yerden devam eder.
	Music.play_main()
	exit_gate.visible = true
	exit_gate.activate()
	hud.set_objective("Kapı açıldı!")
	hud.point_to(exit_gate, GATE_ARROW_COLOR)

func _on_gate_entered() -> void:
	hud.set_objective("")
	hud.clear_arrow()
	# Güç boss öncesi alındıysa söylenecek söz kalmadı: doğrudan sonraki bölüm.
	if _power_lost:
		Sfx.play_level_passed()
		SceneTransition.play_power_loss("", GameState.advance_level)
		return
	get_tree().paused = true
	dialogue_box.start(god_name, dialogue_lines)

## Diyalog biter bitmez güç kaybedilir, sonra siyah ekranda ne kaybedildiği
## yazılır. Perde SceneTransition autoload'unda durduğu için sahne değişimi ekran
## tamamen siyahken yapılır; biten bölüm bir daha görünmez.
func _on_dialogue_finished() -> void:
	if dialogue_before_boss and not _power_lost:
		_lose_power_then_boss()
		return
	GameState.lose_power(power_to_lose)
	Sfx.play_level_passed()
	SceneTransition.play_power_loss(
		GameState.power_loss_text(power_to_lose), GameState.advance_level
	)

## Boss öncesi güç kaybı: sahne değişmiyor, perde inip kalkıyor ve arkasından
## boss beliriyor. Perde kapalıyken oyunun duraklı kalması önemli, yoksa oyuncu
## göremediği bir sırada canavarlardan hasar alırdı.
func _lose_power_then_boss() -> void:
	_power_lost = true
	GameState.lose_power(power_to_lose)
	await SceneTransition.play_power_loss(
		GameState.power_loss_text(power_to_lose), func() -> void: pass
	)
	get_tree().paused = false
	_spawn_boss()
