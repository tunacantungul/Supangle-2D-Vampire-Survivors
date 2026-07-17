extends Node2D
## Her bölüm sahnesinin ortak akışı:
## kota dolunca kapı aktifleşir -> kapıya girince tanrı diyaloğu -> güç kaybı -> sonraki bölüm.

@export var kill_quota: int = 15
@export var god_name: String = "Zeus"
@export var dialogue_lines: Array[String] = []
## Bu bölümün sonunda kaybedilecek güç (GameState.Power sırasıyla aynı).
@export_enum("Kalkan:0", "Uçuş:1", "Atak:2") var power_to_lose: int = 0

@onready var exit_gate: Area2D = $ExitGate
@onready var dialogue_box: PanelContainer = $UI/DialogueBox

func _ready() -> void:
	get_tree().paused = false
	GameState.setup_level(kill_quota)
	GameState.kills_changed.connect(_on_kills_changed)
	exit_gate.player_entered.connect(_on_gate_entered)
	dialogue_box.finished.connect(_on_dialogue_finished)

func _on_kills_changed(current: int, _required: int) -> void:
	if current >= kill_quota:
		exit_gate.activate()

func _on_gate_entered() -> void:
	get_tree().paused = true
	dialogue_box.start(god_name, dialogue_lines)

func _on_dialogue_finished() -> void:
	GameState.lose_power(power_to_lose)
	GameState.advance_level()
