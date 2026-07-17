extends Node
## Kalıcı oyun durumu: güçler, bölüm sırası, canavar sayacı ve sahne geçişleri.
## Autoload olarak her yerden GameState adıyla erişilir.

signal powers_changed
signal kills_changed(current: int, required: int)

## Güçler kayıp sırasına göre: önce kalkan, sonra uçuş, en son atak.
enum Power { SHIELD, FLIGHT, ATTACK }

const LEVEL_SCENES: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
]
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const END_MENU_SCENE := "res://scenes/ui/end_menu.tscn"

var powers: Dictionary = {}
var current_level: int = 0
var kills: int = 0
var kill_quota: int = 0
var victory: bool = false

func _ready() -> void:
	_reset_powers()

func has_power(power: Power) -> bool:
	return powers.get(power, false)

func lose_power(power: int) -> void:
	powers[power] = false
	powers_changed.emit()

## Her bölüm başında bölüm sahnesi tarafından çağrılır.
func setup_level(quota: int) -> void:
	kills = 0
	kill_quota = quota
	kills_changed.emit(kills, kill_quota)

## Düşmanlar ölürken çağırır.
func register_kill() -> void:
	kills += 1
	kills_changed.emit(kills, kill_quota)

func start_new_game() -> void:
	_reset_powers()
	current_level = 0
	victory = false
	_change_scene(LEVEL_SCENES[0])

## Ölünce mevcut bölümü, o ana kadar kaybedilmiş güçlerle yeniden başlatır.
func retry_level() -> void:
	_reset_powers()
	for power in current_level:
		powers[power] = false
	powers_changed.emit()
	victory = false
	_change_scene(LEVEL_SCENES[current_level])

## Bölüm sonu diyaloğu bitince çağrılır.
func advance_level() -> void:
	current_level += 1
	if current_level >= LEVEL_SCENES.size():
		victory = true
		_change_scene(END_MENU_SCENE)
	else:
		_change_scene(LEVEL_SCENES[current_level])

func game_over() -> void:
	victory = false
	_change_scene(END_MENU_SCENE)

func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)

func _reset_powers() -> void:
	powers = {
		Power.SHIELD: true,
		Power.FLIGHT: true,
		Power.ATTACK: true,
	}

func _change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
