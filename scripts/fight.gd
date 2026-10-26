extends Node3D
## Der Kampf: lädt die gewählte Map, lässt die Spieler Kämpfer wählen und kämpfen,
## lässt Items erscheinen, startet den Map-Effekt und erkennt den Sieger.

enum State { SELECT, COUNTDOWN, FIGHT, GAME_OVER }

const COUNTDOWN_STEPS := ["3", "2", "1", "KAMPF!"]
const COUNTDOWN_VOICES := ["drei", "zwei", "eins", "kampf"]

var state := State.SELECT
var ready_flags := [false, false]
var item_timer := 0.0
var countdown_time := 0.0
var countdown_step := -1
var map_events: MapEvents
var energy_bars: Array[ProgressBar] = []
## Solo-Modus: der Computer steuert Spieler 2.
var cpu: CpuPlayer
var map_node: Node3D
## Ziele zerstören: Zeit läuft, bis alle Ziele kaputt sind.
var targets_total := 0
var targets_left := 0
var target_time := 0.0
## Endboss: Lebensleiste oben in der Mitte.
const BOSS_HP := 220.0
const BOSS_SIZE := 1.7
var boss_ai: BossAI
var boss_bar: ProgressBar

@onready var players: Array = [$Player1, $Player2]
@onready var labels: Array = [$HUD/P1Label, $HUD/P2Label]
@onready var center_label: Label = $HUD/CenterLabel
@onready var bottom_label: Label = $HUD/BottomLabel
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	var map: Node3D = load(Settings.current_map().scene).instantiate()
	add_child(map)
	move_child(map, 0)
	map_node = map
	# Gemaltes Hintergrundbild für Maps aus fertigen Szenen (die neuen Maps bauen ihres selbst ein).
	if Settings.current_map().has("backdrop"):
		MapLook.backdrop(map, Settings.current_map().backdrop)
	_add_vignette()

	players[0].opponent = players[1]
	players[1].opponent = players[0]
	for i in players.size():
		var p = players[i]
		var spawn: Node3D = map.get_node("Spawn%d" % (i + 1))
		p.position = spawn.position
		p.spawn_position = spawn.position
		p.stocks = Settings.stocks
		p.set_fighter(Settings.choices[i])
		p.fell_off.connect(_on_player_fell_off)
	if Settings.boss_mode:
		# Spieler 2 wird zum Riesen-Kampfroboter und ist sofort bereit.
		var index := Roster.FIGHTERS.map(func(x): return x.name).find("Kampfroboter")
		Settings.choices[1] = maxi(index, 0)
		players[1].set_fighter(Settings.choices[1])
		players[1].make_boss(BOSS_HP, BOSS_SIZE)
		players[1].boss_defeated.connect(_on_boss_defeated)
		ready_flags[1] = true
		_create_boss_bar()
	elif Settings.target_mode:
		# Allein gegen die Uhr: Spieler 2 ist nicht dabei, Leben spielen keine Rolle.
		players[1].visible = false
		players[1].process_mode = Node.PROCESS_MODE_DISABLED
		players[1].position = Vector3(0, -50, 0)
		ready_flags[1] = true
		players[0].stocks = 99
	elif Settings.solo:
		# Der Computer nimmt einen zufälligen anderen Kämpfer und ist sofort bereit.
		Settings.choices[1] = (Settings.choices[0] + randi_range(1, Roster.count() - 1)) % Roster.count()
		players[1].set_fighter(Settings.choices[1])
		ready_flags[1] = true
	center_label.text = "Wählt eure Kämpfer!\nLaufen-Tasten: wechseln   Schwacher Angriff: bereit"
	bottom_label.text = _controls_hint()
	_reset_item_timer()
	_create_energy_bars()
	Audio.music(Settings.current_map().music)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("back"):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	match state:
		State.SELECT:
			_handle_select()
		State.COUNTDOWN:
			_update_countdown(delta)
		State.FIGHT:
			_update_items(delta)
		State.GAME_OVER:
			if Input.is_action_just_pressed("restart"):
				get_tree().reload_current_scene()
	_update_hud()
	_update_camera(delta)


func _handle_select() -> void:
	for i in players.size():
		var prefix := "p%d_" % (i + 1)
		if ready_flags[i] or (Settings.solo and i == 1):
			continue
		var step := 0
		if Input.is_action_just_pressed(prefix + "left"):
			step = -1
		elif Input.is_action_just_pressed(prefix + "right"):
			step = 1
		if step != 0:
			Settings.choices[i] = wrapi(Settings.choices[i] + step, 0, Roster.count())
			players[i].set_fighter(Settings.choices[i])
			Audio.sfx("menu_move")
		if Input.is_action_just_pressed(prefix + "weak"):
			ready_flags[i] = true
			Audio.sfx("menu_select")
			players[i].say("auswahl", "ha")
	if ready_flags[0] and ready_flags[1]:
		_start_fight()


## Beide sind bereit: erst der Countdown "3, 2, 1, Kampf!", dann geht es los.
func _start_fight() -> void:
	Settings.save()
	state = State.COUNTDOWN
	countdown_time = 0.0
	countdown_step = -1
	bottom_label.text = ""
	for p in players:
		# Kurz zur Seite drehen, damit man sieht, wer gegen wen kämpft.
		p.facing = p.start_facing


func _update_countdown(delta: float) -> void:
	countdown_time += delta
	var step := int(countdown_time / 0.8)
	if step != countdown_step and step < COUNTDOWN_STEPS.size():
		countdown_step = step
		center_label.text = COUNTDOWN_STEPS[step]
		center_label.add_theme_font_size_override("font_size", 110 if step < 3 else 90)
		Audio.voice(COUNTDOWN_VOICES[step])
		if step == COUNTDOWN_STEPS.size() - 1:
			_begin_fight()


func _begin_fight() -> void:
	state = State.FIGHT
	for p in players:
		p.controls_enabled = true
		# Der Bereit-Tastendruck soll nicht gleich als Schlag zählen.
		p.attack_timer = 0.3
	get_tree().create_timer(0.7).timeout.connect(func():
		if state == State.FIGHT:
			center_label.text = ""
			center_label.remove_theme_font_size_override("font_size"))
	if Settings.target_mode:
		_spawn_targets()
		return
	if Settings.boss_mode:
		boss_ai = BossAI.new()
		add_child(boss_ai)
		boss_ai.setup(players[1], players[0], 2)
		return
	if Settings.solo:
		cpu = CpuPlayer.new()
		add_child(cpu)
		cpu.setup(players[1], players[0], Settings.cpu_level)
	if Settings.map_effects:
		map_events = MapEvents.new()
		add_child(map_events)
		map_events.setup(Settings.current_map().event, players, bottom_label)


func _create_boss_bar() -> void:
	boss_bar = ProgressBar.new()
	boss_bar.max_value = BOSS_HP
	boss_bar.value = BOSS_HP
	boss_bar.show_percentage = false
	boss_bar.size = Vector2(440, 26)
	boss_bar.position = Vector2(400, 24)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.1, 0.1)
	fill.set_corner_radius_all(8)
	boss_bar.add_theme_stylebox_override("background", bg)
	boss_bar.add_theme_stylebox_override("fill", fill)
	labels[1].get_parent().add_child(boss_bar)


func _on_boss_defeated() -> void:
	if state != State.FIGHT:
		return
	state = State.GAME_OVER
	if boss_ai:
		boss_ai.queue_free()
		boss_ai = null
	var b = players[1]
	b.controls_enabled = false
	SpecialFX.impact(b, b.global_position + Vector3(0, 2.0, 0), Color(1, 0.5, 0.2))
	SpecialFX.slow_motion(b, 0.3, 0.8)
	var tween: Tween = b.create_tween()
	tween.tween_property(b.model_root, "scale", b.model_root.scale * 0.01, 1.2).set_delay(0.6)
	tween.tween_callback(func(): b.visible = false)
	players[0].cheer()
	Audio.jingle("sieg")
	center_label.text = "Du hast den Riesen-Kampfroboter besiegt!
R: nochmal   Esc: Menü"


func _spawn_targets() -> void:
	var targets := Target.place(map_node, self, players[0].position.x)
	targets_total = targets.size()
	targets_left = targets_total
	target_time = 0.0
	for t in targets:
		t.destroyed.connect(_on_target_destroyed)


func _on_target_destroyed() -> void:
	targets_left -= 1
	if targets_left > 0 or state != State.FIGHT:
		return
	state = State.GAME_OVER
	players[0].controls_enabled = false
	players[0].cheer()
	Audio.jingle("sieg")
	var key := "%s|%s" % [Settings.current_map().name, players[0].fighter.get("name", "")]
	var best: float = Settings.target_records.get(key, INF)
	var text := "Alle Ziele zerstört!
Zeit: %s" % _time_text(target_time)
	if target_time < best:
		Settings.target_records[key] = target_time
		Settings.save()
		text += "   NEUER REKORD!" if best < INF else "   (erster Rekord)"
	else:
		text += "   Rekord: %s" % _time_text(best)
	center_label.text = text + "
R: nochmal   Esc: Menü"


static func _time_text(seconds: float) -> String:
	return "%d:%04.1f" % [int(seconds) / 60, fmod(seconds, 60.0)]


func _update_items(delta: float) -> void:
	if Settings.target_mode and state == State.FIGHT:
		target_time += delta
	if not Settings.items_enabled or Settings.target_mode:
		return
	item_timer -= delta
	if item_timer > 0.0:
		return
	_reset_item_timer()
	var item := Item.new()
	add_child(item)
	item.setup(Item.TYPES.keys().pick_random(), players)
	item.position = Vector3(randf_range(-7.0, 7.0), 9.0, 0.0)


func _reset_item_timer() -> void:
	var interval: Vector2 = Settings.ITEM_INTERVALS[Settings.item_rate]
	item_timer = randf_range(interval.x, interval.y)


func _update_hud() -> void:
	for i in players.size():
		var p = players[i]
		var text: String = p.fighter.get("name", "")
		if state == State.SELECT:
			var special: String = Roster.SPECIALS.get(p.fighter.get("special", ""), "")
			var passive: String = Roster.PASSIVES.get(p.fighter.get("passive", ""), "")
			text = "%s\n◀ %s ▶\n%s" % [_player_name(i), text, "Bereit!" if ready_flags[i] else special + "\n" + passive]
		else:
			text = "%s: %s\n%d %%   %s" % [_player_name(i), text, p.damage, "" if Settings.target_mode else "●".repeat(p.stocks)]
		labels[i].text = text
		if Settings.boss_mode and i == 1:
			labels[1].text = "RIESEN-KAMPFROBOTER
%d / %d" % [ceili(players[1].boss_hp), BOSS_HP]
			boss_bar.value = players[1].boss_hp
			energy_bars[1].visible = false
			continue
		if Settings.target_mode and i == 1:
			var key := "%s|%s" % [Settings.current_map().name, players[0].fighter.get("name", "")]
			var best: float = Settings.target_records.get(key, INF)
			labels[1].text = "Ziele: %d / %d
Zeit: %s
Rekord: %s" % [targets_total - targets_left, targets_total,
				_time_text(target_time), _time_text(best) if best < INF else "–"]
			energy_bars[1].visible = false
			continue
		var bar := energy_bars[i]
		bar.visible = Settings.special_charge and state != State.SELECT
		bar.value = p.special_energy
		# Volle Leiste blinkt: Spezialattacke bereit.
		var full: bool = p.special_energy >= p.SPECIAL_MAX
		bar.modulate = Color(1, 1, 1, 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.008))) if full else Color.WHITE


## Unter jedem Namen eine Leiste für die Spezial-Energie.
func _create_energy_bars() -> void:
	for i in players.size():
		var bar := ProgressBar.new()
		bar.max_value = players[i].SPECIAL_MAX
		bar.show_percentage = false
		bar.size = Vector2(300, 18)
		bar.position = Vector2(24 if i == 0 else 1280 - 24 - 300, 108)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.55)
		bg.set_corner_radius_all(6)
		var fill := StyleBoxFlat.new()
		fill.bg_color = players[i].color
		fill.set_corner_radius_all(6)
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)
		if i == 1:
			bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		labels[i].get_parent().add_child(bar)
		energy_bars.append(bar)


func _controls_hint() -> String:
	var short := {"jump": "springen", "shield": "abwehren", "weak": "schwach", "strong": "stark",
		"kick": "Tritt", "special": "Spezial"}
	var lines := []
	for p in [1, 2]:
		var key := func(a: String) -> String: return Settings.key_text("p%d_%s" % [p, a])
		var parts := ["%s/%s laufen" % [key.call("left"), key.call("right")]]
		for a in short:
			parts.append("%s %s" % [key.call(a), short[a]])
		lines.append("Spieler %d: %s" % [p, ", ".join(parts)])
	return "\n".join(lines) + "   |   Esc: Menü"


## Die Kamera folgt beiden Spielern und zoomt heraus, wenn sie weit auseinander sind.
## Dunkelt die Bildränder leicht ab (unter der Anzeige oben).
func _add_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/vignette.gdshader")
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


func _update_camera(delta: float) -> void:
	var visible_players := players.filter(func(p): return p.visible)
	if visible_players.is_empty():
		return
	var min_pos: Vector3 = visible_players[0].position
	var max_pos: Vector3 = min_pos
	for p in visible_players:
		min_pos = min_pos.min(p.position)
		max_pos = max_pos.max(p.position)
	var mid := (min_pos + max_pos) / 2.0
	var spread := maxf(max_pos.x - min_pos.x, (max_pos.y - min_pos.y) * 1.6)
	var target := Vector3(
		clampf(mid.x * 0.6, -6.0, 6.0),
		clampf(mid.y * 0.5 + 2.2, 1.8, 7.0),
		clampf(9.0 + spread * 0.9, 14.0, 26.0))
	if state == State.SELECT:
		target = Vector3(0, 1.6, 9)
	camera.position = camera.position.lerp(target, 3.0 * delta)


func _on_player_fell_off(player: CharacterBody3D) -> void:
	if player.stocks > 0 or state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	if map_events:
		map_events.stop()
	var winner: CharacterBody3D = player.opponent
	winner.cheer()
	Audio.jingle("sieg")
	if cpu:
		cpu.queue_free()
		cpu = null
	if boss_ai:
		boss_ai.queue_free()
		boss_ai = null
	if Settings.boss_mode:
		center_label.text = "Der Riesen-Kampfroboter hat gewonnen!
R: nochmal   Esc: Menü"
	elif Settings.solo and winner.player_id == 2:
		center_label.text = "Der Computer gewinnt!\nR: nochmal   Esc: Menü"
	else:
		Audio.voice("spieler_%d_gewinnt" % winner.player_id)
		center_label.text = "%s gewinnt!\nR: nochmal   Esc: Menü" % ("Du" if Settings.solo else "Spieler %d" % winner.player_id)


## "Spieler 1", "Spieler 2" oder im Solo-Modus "Computer (Mittel)".
func _player_name(i: int) -> String:
	if Settings.solo and i == 1:
		return "Computer (%s)" % CpuPlayer.LEVELS[Settings.cpu_level].name
	return "Spieler %d" % (i + 1)
