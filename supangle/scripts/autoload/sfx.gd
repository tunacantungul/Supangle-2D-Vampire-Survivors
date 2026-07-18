extends Node
## Oyunun ses efektleri. Autoload olduğu için sahne değişiminde kesilmez.
## Her efekt havuzdaki sıradaki oynatıcıya verilir; böylece üst üste binen
## sesler birbirini kesmez.

const HIT_ENEMY := preload("res://assets/Sound/Hit_enemy.wav")
const LEVEL_UP := preload("res://assets/Sound/Level_up.wav")
const PASS_LEVEL := preload("res://assets/Sound/pass_level.wav")

## Aynı anda çalabilecek efekt sayısı.
const VOICE_COUNT := 12

## Vuruş sesi çok sık tetikleniyor (her mermi, her aura tıkırtısı). Aynı karede
## onlarca düşman vurulunca ses duvara dönüşmesin diye iki vuruş arasına asgari
## süre koyuyoruz.
const HIT_MIN_INTERVAL := 0.05

## Vuruş sesi hep aynı perdeden çalınca makineleşiyor; her seferinde hafifçe
## kaydırıyoruz.
const HIT_PITCH_RANGE := Vector2(0.92, 1.08)

var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _hit_cooldown: float = 0.0

func _ready() -> void:
	# Kart menüsü ve bölüm geçişi ağacı duraklattığı için sesler de duraklamamalı.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICE_COUNT:
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_voices.append(player)

func _process(delta: float) -> void:
	if _hit_cooldown > 0.0:
		_hit_cooldown -= delta

## Düşmana vuruldu.
func play_hit_enemy() -> void:
	if _hit_cooldown > 0.0:
		return
	_hit_cooldown = HIT_MIN_INTERVAL
	_play(HIT_ENEMY, -7.0, randf_range(HIT_PITCH_RANGE.x, HIT_PITCH_RANGE.y))

## Seviye atlandı (kart menüsü açılmadan hemen önce).
func play_level_up() -> void:
	_play(LEVEL_UP, -2.0)

## Bölüm tamamlandı, sıradaki bölüme geçiliyor.
func play_level_passed() -> void:
	_play(PASS_LEVEL, -2.0)

func _play(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var player := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
