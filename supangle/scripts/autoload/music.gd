extends Node
## Oyunun müziği. Autoload olduğu için sahne değişiminde kesilmez.
##
## Ana tema bölümler boyunca tek parça olarak akar: bölüm değişiminde, diyalogda,
## kart menüsünde ya da boss dövüşünde baştan başlamaz, yalnızca duraklatılıp
## kaldığı yerden devam eder. Boss ve kavuşma müzikleri ise her seferinde baştan
## başlar; onlar tek seferlik olaylar.
##
## Her parçanın kendi oynatıcısı var; `stream_paused` çalma konumunu koruduğu
## için devam ederken `play()` çağırmıyoruz.

const MAIN_MENU := preload("res://assets/Sound/Main_menu.wav")
const MAIN_THEME := preload("res://assets/Sound/Main_theme.wav")
const BOSS_FIGHT := preload("res://assets/Sound/Boss_fight.mp3")
const EPILOGUE := preload("res://assets/Sound/Epilogue_music.mp3")

## Müzik efektlerin altında kalsın diye kısık.
const MENU_VOLUME_DB := -12.0
const MAIN_VOLUME_DB := -14.0
const BOSS_VOLUME_DB := -12.0
const EPILOGUE_VOLUME_DB := -12.0

var _menu: AudioStreamPlayer
var _main: AudioStreamPlayer
var _boss: AudioStreamPlayer
var _epilogue: AudioStreamPlayer
## Duraklatma her seferinde hepsini gezsin diye tek listede tutuluyor;
## yeni parça eklendiğinde başka yeri güncellemek gerekmiyor.
var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	# Kart menüsü, diyalog ve bölüm geçişi ağacı duraklatıyor; müzik akmalı.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Döngü kurulumu içeriden yapılıyor: içe aktarma ayarlarına dokunmadan
	# parçaların kesintisiz tekrarlanmasını garanti ediyor.
	for stream in [MAIN_MENU, MAIN_THEME, BOSS_FIGHT, EPILOGUE]:
		_loop(stream)
	_menu = _make_player(MAIN_MENU, MENU_VOLUME_DB)
	_main = _make_player(MAIN_THEME, MAIN_VOLUME_DB)
	_boss = _make_player(BOSS_FIGHT, BOSS_VOLUME_DB)
	_epilogue = _make_player(EPILOGUE, EPILOGUE_VOLUME_DB)

## Ana menünün müziği. Menüye her dönüşte kaldığı yerden devam eder.
func play_menu() -> void:
	_switch_to(_menu, false)

## Bölümlerin müziği. Zaten çalıyorsa kaldığı yerden devam eder.
func play_main() -> void:
	_switch_to(_main, false)

## Boss arenasına girilince. Her dövüşte baştan başlar.
func play_boss() -> void:
	_switch_to(_boss, true)

## Kavuşma sahnesinin müziği.
func play_epilogue() -> void:
	_switch_to(_epilogue, true)

## Menülerde sessizlik; ana tema kaldığı yerde bekler.
func pause_all() -> void:
	for player in _players:
		player.stream_paused = true

## Hedefi çalar, diğerlerini duraklatır. `restart` false ise duraklamış parça
## kaldığı yerden devam eder.
func _switch_to(target: AudioStreamPlayer, restart: bool) -> void:
	for player in _players:
		if player != target:
			player.stream_paused = true
	target.stream_paused = false
	if restart or not target.playing:
		target.play()

func _make_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	_players.append(player)
	return player

func _loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_begin = 0
		# loop_end örnek (sample) cinsinden; 0 bırakılırsa döngü boşa düşüyor.
		# Süreden hesaplamak sıkıştırma formatından bağımsız olarak doğru.
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		stream.loop = true
