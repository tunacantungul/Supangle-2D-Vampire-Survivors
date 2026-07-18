extends Node2D
## Her bölüm sahnesinin ortak akışı:
## kota dolunca boss arenası aktifleşir -> arenaya girince boss doğar ->
## boss ölünce kapı belirir -> kapıya girince tanrı diyaloğu -> güç kaybı -> sonraki bölüm.

@export var kill_quota: int = 15
@export var god_name: String = "Zeus"
## Vurgulanacak kelimeler satır metnine BBCode ile yazılır: [shake]ölümsüz[/shake].
@export var dialogue_lines: Array[String] = []
## Bu bölümün sonunda kaybedilecek güç (GameState.Power sırasıyla aynı).
@export_enum("Ölümsüzlük:0", "Uçuş:1", "Atak:2") var power_to_lose: int = 0
## Bölüm sonu bossu.
@export var boss_scene: PackedScene

@onready var exit_gate: Area2D = $ExitGate
@onready var boss_arena: Area2D = $BossArena
@onready var dialogue_box: PanelContainer = $UI/DialogueBox
@onready var hud: Control = $UI/HUD
@onready var upgrade_menu: Control = $UI/UpgradeMenu

var _arena_armed: bool = false
## Kart menüsü açıkken biriken ek seviye atlamaları (aynı karede çoklu ölüm).
var _pending_level_ups: int = 0

func _ready() -> void:
	get_tree().paused = false
	GameState.setup_level(kill_quota)
	GameState.kills_changed.connect(_on_kills_changed)
	GameState.leveled_up.connect(_on_leveled_up)
	upgrade_menu.card_chosen.connect(_on_card_chosen)
	exit_gate.visible = false
	exit_gate.player_entered.connect(_on_gate_entered)
	boss_arena.triggered.connect(_on_arena_triggered)
	dialogue_box.finished.connect(_on_dialogue_finished)
	_apply_camera_limits()

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

func _on_leveled_up() -> void:
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

func _on_arena_triggered() -> void:
	var boss: Boss = boss_scene.instantiate()
	boss.position = boss_arena.position
	add_child(boss)
	boss.boss_died.connect(_on_boss_died)
	hud.set_objective("Boss'u yen!")

func _on_boss_died() -> void:
	exit_gate.visible = true
	exit_gate.activate()
	hud.set_objective("Kapı açıldı! Çıkışa ilerle")

func _on_gate_entered() -> void:
	get_tree().paused = true
	dialogue_box.start(god_name, dialogue_lines)

func _on_dialogue_finished() -> void:
	GameState.lose_power(power_to_lose)
	GameState.advance_level()
