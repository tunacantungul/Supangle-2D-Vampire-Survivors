extends Node2D
## Her bölüm sahnesinin ortak akışı:
## kota dolunca boss arenası aktifleşir -> arenaya girince boss doğar ->
## boss ölünce kapı belirir -> kapıya girince tanrı diyaloğu -> güç kaybı -> sonraki bölüm.

@export var kill_quota: int = 15
@export var god_name: String = "Zeus"
@export var dialogue_lines: Array[String] = []
## Bu bölümün sonunda kaybedilecek güç (GameState.Power sırasıyla aynı).
@export_enum("Ölümsüzlük:0", "Uçuş:1", "Atak:2") var power_to_lose: int = 0
## Bölüm sonu bossu.
@export var boss_scene: PackedScene

@onready var exit_gate: Area2D = $ExitGate
@onready var boss_arena: Area2D = $BossArena
@onready var dialogue_box: PanelContainer = $UI/DialogueBox
@onready var hud: Control = $UI/HUD

var _arena_armed: bool = false

func _ready() -> void:
	get_tree().paused = false
	GameState.setup_level(kill_quota)
	GameState.kills_changed.connect(_on_kills_changed)
	exit_gate.visible = false
	exit_gate.player_entered.connect(_on_gate_entered)
	boss_arena.triggered.connect(_on_arena_triggered)
	dialogue_box.finished.connect(_on_dialogue_finished)

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
