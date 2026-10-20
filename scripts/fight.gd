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

@onready var players: Array = [$Player1, $Player2]
@onready var labels: Array = [$HUD/P1Label, $HUD/P2Label]
@onready var center_label: Label = $HUD/CenterLabel
@onready var bottom_label: Label = $HUD/BottomLabel
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	var map: Node3D = load(Settings.current_map().scene).instantiate()
	add_child(map)
	move_child(map, 0)

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
		if ready_flags[i]:
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
			Audio.voice("ha", players[i].voice_pitch())
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
	if Settings.map_effects:
		map_events = MapEvents.new()
		add_child(map_events)
		map_events.setup(Settings.current_map().event, players, bottom_label)


func _update_items(delta: float) -> void:
	if not Settings.items_enabled:
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
			text = "Spieler %d\n◀ %s ▶\n%s" % [i + 1, text, "Bereit!" if ready_flags[i] else special]
		else:
			text = "Spieler %d: %s\n%d %%   %s" % [i + 1, text, p.damage, "●".repeat(p.stocks)]
		labels[i].text = text
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
	Audio.voice("spieler_%d_gewinnt" % winner.player_id)
	center_label.text = "Spieler %d gewinnt!\nR: nochmal   Esc: Menü" % winner.player_id
