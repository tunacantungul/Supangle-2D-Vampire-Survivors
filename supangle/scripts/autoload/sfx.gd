extends Node
## Oyunun ses efektleri. Autoload olduğu için sahne değişiminde kesilmez.
## Her efekt havuzdaki sıradaki oynatıcıya verilir; böylece üst üste binen
## sesler birbirini kesmez.

const HIT_ENEMY := preload("res://assets/Sound/Hit_enemy.wav")
const PLAYER_HURT := preload("res://assets/Sound/Hero_damaged.wav")
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

## Tehlikeli zeminde hasar her fizik karesinde uygulanıyor (saniyede 60); ses
## buna bağlı olduğu için asgari aralık şart. Temas hasarının dokunulmazlık
## süresine (0.4 sn) yakın tutuldu.
const HURT_MIN_INTERVAL := 0.35

## Hasar sesinin kazancı. Kayıt zaten yüksek (RMS -9.8 dBFS); -6 ile etkin
## seviye ~-15.8 dBFS oluyor, yani çarpışma gürültüsünün (~-18) üstünde.
## Tepe değeri -0.1 dBFS olduğu için kırpma da olmuyor (-6.1'de kalıyor).
const HURT_VOLUME_DB := -6.0

var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _hit_cooldown: float = 0.0
var _hurt_cooldown: float = 0.0
## Hasar sesinin kendi kanalı. Paylaşılan havuzda sırası gelen kanal yeniden
## kullanıldığı için vuruş sesleri (saniyede 20'ye kadar) hasar sesini yarıda
## kesebiliyordu; oyuncunun can kaybını duyması bundan önemli.
var _hurt_voice: AudioStreamPlayer

func _ready() -> void:
	# Kart menüsü ve bölüm geçişi ağacı duraklattığı için sesler de duraklamamalı.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICE_COUNT:
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_voices.append(player)
	_hurt_voice = AudioStreamPlayer.new()
	_hurt_voice.process_mode = Node.PROCESS_MODE_ALWAYS
	_hurt_voice.stream = PLAYER_HURT
	_hurt_voice.volume_db = HURT_VOLUME_DB
	add_child(_hurt_voice)

func _process(delta: float) -> void:
	if _hit_cooldown > 0.0:
		_hit_cooldown -= delta
	if _hurt_cooldown > 0.0:
		_hurt_cooldown -= delta

## Düşmana vuruldu.
func play_hit_enemy() -> void:
	if _hit_cooldown > 0.0:
		return
	_hit_cooldown = HIT_MIN_INTERVAL
	_play(HIT_ENEMY, -7.0, randf_range(HIT_PITCH_RANGE.x, HIT_PITCH_RANGE.y))

## Oyuncu hasar aldı. Kendi kanalında ve efekt yığınının üstünde çalıyor:
## çarpışma sırasında 12 vuruş sesi üst üste binince toplamları ~-18 dBFS'e
## çıkıyor ve bunun altındaki her şey duyulmaz oluyordu.
func play_player_hurt() -> void:
	if _hurt_cooldown > 0.0:
		return
	_hurt_cooldown = HURT_MIN_INTERVAL
	_hurt_voice.play()

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
