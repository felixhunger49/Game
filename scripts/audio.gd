extends Node
## Spielt Geräusche, Stimmen und Musik. Als Autoload "Audio" überall erreichbar:
##   Audio.sfx("hit_strong")      Audio.voice("kampf")      Audio.music("burg")

const SFX_DIR := "res://assets/audio/sfx/"
const VOICE_DIR := "res://assets/audio/voice/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL_SIZE := 16

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _music_player: AudioStreamPlayer
var _music_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	# Musik in Dauerschleife.
	_music_player.finished.connect(_music_player.play)
	apply_volume()


## Kurzes Geräusch. pitch < 1 klingt tiefer, > 1 höher. Leichte Zufallsabweichung, damit es lebendig klingt.
func sfx(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	_play(SFX_DIR + sound + ".wav", pitch * randf_range(0.94, 1.06), volume_db)


## Stimme (Ansager oder Kampfruf). pitch verändert die Stimmlage, z. B. tiefer für den Barbar.
func voice(line: String, pitch := 1.0, volume_db := 0.0) -> void:
	_play(VOICE_DIR + line + ".wav", pitch, volume_db)


func music(track: String) -> void:
	if track == _music_name and _music_player.playing:
		return
	_music_name = track
	var stream := _music_stream(track)
	if stream == null:
		_music_player.stop()
		return
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_name = ""
	_music_player.stop()


## Eigene Stimme einer Figur (assets/audio/voice/figuren/<Figur>/<Spruch>.wav). Hat die Figur den Spruch nicht,
## kommt die gemeinsame Stimme, in der Stimmlage der Figur verstellt.
func fighter_voice(folder: String, line: String, fallback: String, fallback_pitch: float, pitch := 1.0, volume_db := 0.0) -> void:
	var path := VOICE_DIR + "figuren/%s/%s.wav" % [folder, line]
	if _load(path):
		_play(path, pitch, volume_db)
	else:
		voice(fallback, fallback_pitch * pitch, volume_db)


## Kurzes Musikstück einmal abspielen (z. B. Siegesfanfare); die Hintergrundmusik verstummt dafür.
func jingle(track: String) -> void:
	var stream := _music_stream(track)
	if stream == null:
		return
	stop_music()
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.pitch_scale = 1.0
	p.volume_db = _to_db(Settings.music_volume) - 2.0
	p.play()


## Neue Musik liegt als MP3 vor, ältere Stücke als WAV.
func _music_stream(track: String) -> AudioStream:
	var stream := _load(MUSIC_DIR + track + ".mp3")
	return stream if stream else _load(MUSIC_DIR + track + ".wav")


func apply_volume() -> void:
	_music_player.volume_db = _to_db(Settings.music_volume) - 4.0
	for p in _pool:
		p.volume_db = _to_db(Settings.sfx_volume)


func _play(path: String, pitch: float, volume_db: float) -> void:
	var stream := _load(path)
	if stream == null or Settings.sfx_volume == 0:
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = _to_db(Settings.sfx_volume) + volume_db
	p.play()


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


func _to_db(level: int) -> float:
	return linear_to_db(maxf(level / 10.0, 0.0001))
