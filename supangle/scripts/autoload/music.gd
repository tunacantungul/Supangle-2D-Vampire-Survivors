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
const PROLOGUE := preload("res://assets/Sound/Prologue_music.mp3")
const MAIN_THEME := preload("res://assets/Sound/Main_theme.wav")
const BOSS_FIGHT := preload("res://assets/Sound/Boss_fight.mp3")
const EPILOGUE := preload("res://assets/Sound/Epilogue_music.mp3")

## Kazançlar parçaların kendi ses seviyesine göre ayrı ayrı hesaplandı; dosyaların
## kayıt seviyeleri 4 dB'ye varan farklarla değişiyor, bu yüzden hepsine aynı
## sayıyı vermek karışımı bozuyor. Hedef: menü/ana tema/epilog -24 dBFS etkin
## seviyede buluşsun, boss dövüşü -22 ile en öne çıkan parça olsun.
## Referans: vuruş efekti -28.5 dBFS. Müzik bunun altında kalınca oyun sessiz,
## efektler ise gürültülü hissettiriyordu.
const MENU_VOLUME_DB := -3.5
const PROLOGUE_VOLUME_DB := -8.5
const MAIN_VOLUME_DB := -7.5
const BOSS_VOLUME_DB := -5.0
const EPILOGUE_VOLUME_DB := -5.5

## Sönerken inilen seviye. Tam sessizlik (-80) yerine bu: son saniyede duyulur
## bir fark kalmıyor ve iniş daha doğal oluyor.
const SILENCE_DB := -40.0

## Parçalar arası çapraz geçiş süresi. Boss dövüşünün başlaması gecikmiş
## hissettirmeyecek kadar kısa, kesme gibi durmayacak kadar uzun.
const CROSSFADE_TIME := 1.0

var _menu: AudioStreamPlayer
var _prologue: AudioStreamPlayer
var _main: AudioStreamPlayer
var _boss: AudioStreamPlayer
var _epilogue: AudioStreamPlayer
## Duraklatma her seferinde hepsini gezsin diye tek listede tutuluyor;
## yeni parça eklendiğinde başka yeri güncellemek gerekmiyor.
var _players: Array[AudioStreamPlayer] = []
## Sönme sırasında seviyeler geçici olarak düşürülüyor; her parçanın kendi
## ayarlı seviyesi burada saklanıyor ki sonradan geri yazılabilsin.
var _base_volume: Dictionary = {}
var _fade_tween: Tween

func _ready() -> void:
	# Kart menüsü, diyalog ve bölüm geçişi ağacı duraklatıyor; müzik akmalı.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Döngü kurulumu içeriden yapılıyor: içe aktarma ayarlarına dokunmadan
	# parçaların kesintisiz tekrarlanmasını garanti ediyor.
	for stream in [MAIN_MENU, PROLOGUE, MAIN_THEME, BOSS_FIGHT, EPILOGUE]:
		_loop(stream)
	_menu = _make_player(MAIN_MENU, MENU_VOLUME_DB)
	_prologue = _make_player(PROLOGUE, PROLOGUE_VOLUME_DB)
	_main = _make_player(MAIN_THEME, MAIN_VOLUME_DB)
	_boss = _make_player(BOSS_FIGHT, BOSS_VOLUME_DB)
	_epilogue = _make_player(EPILOGUE, EPILOGUE_VOLUME_DB)

## Ana menünün müziği. Menüye her dönüşte kaldığı yerden devam eder.
func play_menu() -> void:
	_switch_to(_menu, false)

## Açılış konuşmasının müziği. Her yeni oyunda baştan başlar.
func play_prologue() -> void:
	_switch_to(_prologue, true)

## Bölümlerin müziği. Zaten çalıyorsa kaldığı yerden devam eder.
func play_main() -> void:
	_switch_to(_main, false)

## Boss arenasına girilince. Her dövüşte baştan başlar.
func play_boss() -> void:
	_switch_to(_boss, true)

## Kavuşma sahnesinin müziği.
func play_epilogue() -> void:
	_switch_to(_epilogue, true)

## Çalan müziği yumuşakça kısıp duraklatır. Sert kesme yerine; kavuşma sahnesi
## bitip oyun sonu ekranına geçerken müziğin bıçakla kesilmesi kötü duruyordu.
## Duraklatma kaldığı yeri koruduğu için parça daha sonra kaldığı yerden devam
## edebilir; ses seviyesi de eski değerine geri yazılıyor.
func fade_out_all(duration: float = 2.0) -> void:
	_kill_fade()
	_fade_tween = create_tween().set_parallel(true)
	for player in _players:
		if player.stream_paused or not player.playing:
			continue
		_fade_tween.tween_property(player, "volume_db", SILENCE_DB, duration)
	_fade_tween.chain().tween_callback(_finish_fade)

## Hedefe çapraz geçiş yapar: çalan parça kısılırken hedef sessizden açılır.
## `restart` false ise duraklamış parça kaldığı yerden devam eder.
## Zaten çalan parça yeniden istenirse hiçbir şey yapılmaz — sesi boşuna
## kısılıp açılmasın.
func _switch_to(target: AudioStreamPlayer, restart: bool) -> void:
	# Yarım kalmış bir geçiş varsa iptal: seviyeler normale döner.
	_kill_fade()

	var outgoing: Array[AudioStreamPlayer] = []
	for player in _players:
		if player != target and player.playing and not player.stream_paused:
			outgoing.append(player)
	var was_silent := not target.playing or target.stream_paused

	target.stream_paused = false
	if restart or not target.playing:
		target.play()

	if outgoing.is_empty() and not was_silent:
		return

	_fade_tween = create_tween().set_parallel(true)
	if was_silent:
		target.volume_db = SILENCE_DB
		_fade_tween.tween_property(target, "volume_db", _base_volume[target], CROSSFADE_TIME)
	for player in outgoing:
		_fade_tween.tween_property(player, "volume_db", SILENCE_DB, CROSSFADE_TIME)
	# Susan parçalar ancak geçiş bitince duraklatılır; erken duraklatmak
	# kısılmayı yarıda keserdi.
	_fade_tween.chain().tween_callback(_finish_switch.bind(outgoing))

## Çapraz geçiş bitti: susan parçaları duraklat ve seviyelerini geri yaz.
func _finish_switch(outgoing: Array) -> void:
	for player: AudioStreamPlayer in outgoing:
		player.stream_paused = true
		player.volume_db = _base_volume.get(player, 0.0)
	_fade_tween = null

## Sönme bitti: sesi kes ve seviyeleri eski hâline al ki sonraki çalışta
## sessiz başlamasınlar.
func _finish_fade() -> void:
	for player in _players:
		player.stream_paused = true
	_restore_volumes()

## Yarıda kalan sönmeyi iptal eder ve seviyeleri geri yükler.
func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
	_restore_volumes()

func _restore_volumes() -> void:
	for player in _players:
		player.volume_db = _base_volume.get(player, 0.0)

func _make_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	_base_volume[player] = volume_db
	# Kaynak üzerindeki döngü bayrağı içe aktarma ayarlarına göre işlemeyebiliyor;
	# bu sinyal yedek olarak parçayı yeniden başlatıyor. Döngü zaten çalışıyorsa
	# parça hiç bitmediği için sinyal gelmez ve bu kod devreye girmez.
	player.finished.connect(_on_stream_finished.bind(player))
	add_child(player)
	_players.append(player)
	return player

func _on_stream_finished(player: AudioStreamPlayer) -> void:
	player.play()

func _loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		stream.loop_begin = 0
		# loop_end örnek (sample) cinsinden; 0 bırakılırsa döngü boşa düşüyor.
		# Süreden hesaplamak sıkıştırma formatından bağımsız olarak doğru.
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		stream.loop = true
