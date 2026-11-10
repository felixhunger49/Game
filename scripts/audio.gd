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
## Zweiter Spieler, auf dem das alte Stück ausklingt, während das neue schon beginnt.
var _music_old: AudioStreamPlayer
var _music_name := ""
## Lautstärke-Anteile der Musik (0 bis 1): Einblenden des neuen Stücks, Ausklingen des alten
## und kurzes Leiserwerden bei großen Momenten (K.-o.-Treffer).
const FADE_SECONDS := 0.7
var _fade_in := 1.0
var _fade_out := 0.0
var _duck := 1.0
var _duck_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_music_old = AudioStreamPlayer.new()
	add_child(_music_old)
	# Musik in Dauerschleife (falls ein Stück nicht von selbst wiederholt).
	_music_player.finished.connect(_music_player.play)
	apply_volume()


func _process(delta: float) -> void:
	# Echte Zeit statt Spielzeit, damit die Musik auch in Zeitlupe gleichmäßig überblendet.
	var real := delta / maxf(Engine.time_scale, 0.01)
	_fade_in = minf(_fade_in + real / FADE_SECONDS, 1.0)
	if _fade_out > 0.0:
		_fade_out = maxf(_fade_out - real / FADE_SECONDS, 0.0)
		if _fade_out == 0.0:
			_music_old.stop()
	_duck_time = maxf(_duck_time - real, 0.0)
	_duck = move_toward(_duck, 0.3 if _duck_time > 0.0 else 1.0, real * (6.0 if _duck_time > 0.0 else 1.2))
	_apply_music_volume()


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
	_hand_over()
	if stream == null:
		return
	# Stücke mit eingebauter Schleife wiederholen ohne Lücke.
	if "loop" in stream:
		stream.loop = true
	_music_player.stream = stream
	_fade_in = 0.0
	_apply_music_volume()
	_music_player.play()


## Die Musik klingt aus (weich, kein harter Schnitt).
func stop_music() -> void:
	_music_name = ""
	_hand_over()


## Das laufende Stück an den zweiten Spieler übergeben, dort klingt es aus.
func _hand_over() -> void:
	if not _music_player.playing:
		return
	var at := _music_player.get_playback_position()
	_music_old.stream = _music_player.stream
	_fade_out = _fade_in
	_music_player.stop()
	_apply_music_volume()
	_music_old.play(at)


## Musik für einen Augenblick leiser (z. B. beim K.-o.-Treffer), damit der Knall wirkt.
func duck(seconds: float) -> void:
	_duck_time = maxf(_duck_time, seconds)


func _apply_music_volume() -> void:
	var base := _to_db(Settings.music_volume) - 4.0
	_music_player.volume_db = base + linear_to_db(maxf(_fade_in * _duck, 0.0001))
	_music_old.volume_db = base + linear_to_db(maxf(_fade_out * _duck, 0.0001))


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


func has_music(track: String) -> bool:
	return _music_stream(track) != null


## Neue Musik liegt als MP3 vor, ältere Stücke als WAV.
func _music_stream(track: String) -> AudioStream:
	var stream := _load(MUSIC_DIR + track + ".mp3")
	return stream if stream else _load(MUSIC_DIR + track + ".wav")


func apply_volume() -> void:
	_apply_music_volume()
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
