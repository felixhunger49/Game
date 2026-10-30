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
## Kämpferauswahl: je Spieler eine Karte (Name, Spezial, Passive) und was dafür ausgeblendet wird.
var select_cards: Array[Dictionary] = []
var select_shade: MeshInstance3D
var select_hidden: Array[Node3D] = []
## Kampagne: Anzeige "Kampf 3 / 15" und wie lange das Ergebnis schon steht
## (damit ein letzter Schlag nicht sofort "weiter" drückt).
var campaign_label: Label
var game_over_time := 0.0
var campaign_finished := false
## Echtzeit-Sekunden, die die Kamera noch auf den K.-o.-Treffer zoomt, und wohin.
const KO_FOCUS_SECONDS := 0.6
var ko_focus_time := 0.0
var ko_focus: CharacterBody3D

@onready var players: Array = [$Player1, $Player2]
@onready var labels: Array = [$HUD/P1Label, $HUD/P2Label]
@onready var center_label: Label = $HUD/CenterLabel
@onready var bottom_label: Label = $HUD/BottomLabel
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	if Settings.campaign:
		# Der Kampagnen-Kampf bestimmt Modus, Map und Gegner, nicht das Menü.
		var step := Settings.campaign_step()
		Settings.solo = true
		Settings.target_mode = step.type == "ziele"
		Settings.boss_mode = step.type == "boss"
	var map: Node3D = load(Settings.current_map().scene).instantiate()
	add_child(map)
	move_child(map, 0)
	map_node = map
	# Gemaltes Hintergrundbild für Maps aus fertigen Szenen (die neuen Maps bauen ihres selbst ein).
	if Settings.current_map().has("backdrop"):
		MapLook.backdrop(map, Settings.current_map().backdrop)
	_add_vignette()
	_apply_graphics(map)

	players[0].opponent = players[1]
	players[1].opponent = players[0]
	for i in players.size():
		var p = players[i]
		var spawn: Node3D = map.get_node("Spawn%d" % (i + 1))
		p.position = spawn.position
		p.spawn_position = spawn.position
		p.stocks = Settings.stocks
		p.blast_zone = MapLook.blast_zone(map)
		p.set_fighter(Settings.choices[i])
		p.fell_off.connect(_on_player_fell_off)
		p.ko_hit.connect(_on_ko_hit)
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
		# Der Computer nimmt einen anderen Kämpfer und ist sofort bereit.
		# In der Kampagne kommt jedes Mal der nächste Gegner aus der festen Reihenfolge.
		if Settings.campaign:
			Settings.choices[1] = Settings.campaign_opponent(Settings.choices[0])
		else:
			Settings.choices[1] = (Settings.choices[0] + randi_range(1, Roster.count() - 1)) % Roster.count()
		players[1].set_fighter(Settings.choices[1])
		ready_flags[1] = true
	bottom_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_label.add_theme_font_size_override("font_size", 15)
	bottom_label.add_theme_constant_override("outline_size", 6)
	bottom_label.text = _controls_hint()
	center_label.add_theme_font_override("font", UiStyle.TITLE_FONT)
	_create_select_ui()
	_reset_item_timer()
	_create_energy_bars()
	if Settings.campaign:
		_create_campaign_label()
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
			game_over_time += delta
			if Settings.campaign:
				_handle_campaign_continue()
			elif Input.is_action_just_pressed("restart"):
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
			# Kampagne: Wählt man den Kämpfer des Gegners, nimmt der Computer den nächsten.
			if Settings.campaign and Settings.solo and not Settings.boss_mode and not Settings.target_mode:
				var foe := Settings.campaign_opponent(Settings.choices[0])
				if foe != Settings.choices[1]:
					Settings.choices[1] = foe
					players[1].set_fighter(foe)
		if Input.is_action_just_pressed(prefix + "weak"):
			ready_flags[i] = true
			# Wer bereit ist, hört auf sich zu drehen und schaut nach vorne.
			players[i].showcase_spin = false
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
	_remove_select_ui()
	for p in players:
		p.showcase_spin = false
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
	_shrink_campaign_label()
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
		boss_ai.setup(players[1], players[0], 2, map_node)
		return
	if Settings.solo:
		cpu = CpuPlayer.new()
		add_child(cpu)
		cpu.setup(players[1], players[0], Settings.cpu_difficulty(), map_node)
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
	if Settings.campaign:
		_campaign_result(true, "Du hast den Riesen-Kampfroboter besiegt!")


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
	if Settings.campaign:
		_campaign_result(true, text)


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
	var area := MapLook.area_of(map_node)
	item.position = Vector3(randf_range(area.position.x + 1.0, area.end.x - 1.0), area.end.y + 4.0, 0.0)


func _reset_item_timer() -> void:
	var interval: Vector2 = Settings.ITEM_INTERVALS[Settings.item_rate]
	item_timer = randf_range(interval.x, interval.y)


func _update_hud() -> void:
	for i in players.size():
		var p = players[i]
		var text: String = p.fighter.get("name", "")
		if state == State.SELECT:
			_update_select_card(i)
			labels[i].text = ""
			energy_bars[i].visible = false
			continue
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
		parts.append("%s+%s greifen" % [key.call("shield"), key.call("weak")])
		lines.append("Spieler %d: %s" % [p, ", ".join(parts)])
	return "\n".join(lines) + "   |   Esc: Menü"


## Die Kamera folgt beiden Spielern und zoomt heraus, wenn sie weit auseinander sind.
## Dunkelt die Bildränder leicht ab (unter der Anzeige oben).
## Grafik-Einstellung: "Hoch" glättet Kanten (MSAA), "Niedrig" spart Schatten und Glühen für schwache PCs.
func _apply_graphics(map: Node3D) -> void:
	var high := Settings.graphics > 0
	get_viewport().msaa_3d = Viewport.MSAA_2X if high else Viewport.MSAA_DISABLED
	if high:
		return
	for light in map.find_children("*", "DirectionalLight3D", true, false):
		light.shadow_enabled = false
	var we: WorldEnvironment = map.get_node_or_null("WorldEnvironment")
	if we and we.environment:
		# Kopie, damit die Map-Datei im Speicher unverändert bleibt.
		we.environment = we.environment.duplicate()
		we.environment.glow_enabled = false


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


## Ein Treffer schleudert eine Figur gleich aus der Arena: Zeitlupe und Zoom auf sie, wie bei Smash Bros.
func _on_ko_hit(player: CharacterBody3D) -> void:
	if state != State.FIGHT:
		return
	ko_focus = player
	ko_focus_time = KO_FOCUS_SECONDS
	SpecialFX.ko_moment(player, KO_FOCUS_SECONDS)


func _update_camera(delta: float) -> void:
	var visible_players := players.filter(func(p): return p.visible)
	if visible_players.is_empty():
		return
	if ko_focus_time > 0.0 and is_instance_valid(ko_focus):
		# Während der Zeitlupe läuft delta langsamer, die Kamera soll aber in Echtzeit heranfahren.
		var real_delta := delta / maxf(Engine.time_scale, 0.01)
		ko_focus_time -= real_delta
		var zoom_target := ko_focus.position + Vector3(0, 1.0, 7.5)
		camera.position = camera.position.lerp(zoom_target, minf(8.0 * real_delta, 1.0))
		return
	var min_pos: Vector3 = visible_players[0].position
	var max_pos: Vector3 = min_pos
	for p in visible_players:
		min_pos = min_pos.min(p.position)
		max_pos = max_pos.max(p.position)
	var mid := (min_pos + max_pos) / 2.0
	var spread := maxf(max_pos.x - min_pos.x, (max_pos.y - min_pos.y) * 1.6)
	# Wie weit die Kamera wandern und herauszoomen darf, hängt von der Größe der Bühne ab.
	var area := MapLook.area_of(map_node)
	var side := maxf(area.size.x / 2.0 - 1.5, 6.0)
	var center_x := area.get_center().x
	var target := Vector3(
		clampf(mid.x * 0.6 + center_x * 0.4, center_x - side, center_x + side),
		clampf(mid.y * 0.5 + 2.2, area.position.y + 1.8, area.end.y + 2.0),
		clampf(9.0 + spread * 0.9, 14.0, 26.0 + maxf(area.size.x - 15.0, 0.0) * 0.45))
	if state == State.SELECT:
		target = Vector3(clampf(mid.x, -8.0, 8.0), mid.y + 1.5, 8.5 + maxf(spread - 5.0, 0.0) * 0.8)
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
	if Settings.campaign:
		var won: bool = winner.player_id == 1
		_campaign_result(won, "Sieg!" if won else ("Der Riesen-Kampfroboter hat gewonnen!" if Settings.boss_mode else "Der Computer gewinnt!"))


## Kämpferauswahl aufbauen: oben die Überschrift, links und rechts je eine Karte mit umbrechendem Text.
## Die Map wird hinter den Figuren abgedunkelt, alles was vor ihnen steht (Geländer, Kanonen, Masten) ausgeblendet.
func _create_select_ui() -> void:
	center_label.text = ""
	var hud: Node = center_label.get_parent()
	var title := UiStyle.label("WÄHLT EURE KÄMPFER!", 46, UiStyle.GOLD, true, 16)
	if Settings.campaign:
		title.text = "KAMPF %d / %d · %s" % [Settings.campaign_stage + 1, Settings.CAMPAIGN.size(), Settings.current_map().name.to_upper()]
	title.add_theme_color_override("font_outline_color", Color(0.22, 0.07, 0.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 2)
	title.size = Vector2(1280, 60)
	hud.add_child(title)
	var help := HBoxContainer.new()
	help.alignment = BoxContainer.ALIGNMENT_CENTER
	help.add_theme_constant_override("separation", 28)
	help.position = Vector2(0, 62)
	help.size = Vector2(1280, 28)
	for h in [["Laufen", "Kämpfer wechseln"], ["Schwacher Angriff", "Bereit"], ["Esc", "Menü"]]:
		help.add_child(UiStyle.key_hint(h[0], h[1]))
	hud.add_child(help)
	# Dunkler Streifen unten, damit die Tastenliste gut lesbar ist.
	var bottom_shade := TextureRect.new()
	bottom_shade.texture = UiStyle.gradient(PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.7)]), PackedFloat32Array([0.0, 0.45]), true)
	bottom_shade.stretch_mode = TextureRect.STRETCH_SCALE
	bottom_shade.position = Vector2(0, 610)
	bottom_shade.size = Vector2(1280, 110)
	hud.add_child(bottom_shade)
	hud.move_child(bottom_shade, 0)
	select_cards.append({"node": title})
	select_cards.append({"node": help})
	select_cards.append({"node": bottom_shade})
	for i in players.size():
		if Settings.target_mode and i == 1:
			continue
		var panel := PanelContainer.new()
		panel.position = Vector2(24 if i == 0 else 1280 - 24 - 440, 100)
		panel.custom_minimum_size = Vector2(440, 0)
		panel.size = Vector2(440, 0)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		panel.add_child(box)
		# Kopfzeile: farbiges P1/P2-Schild, Spielername und rechts das "BEREIT!"-Zeichen.
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		box.add_child(head)
		var badge := PanelContainer.new()
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = players[i].color
		badge_style.skew = Vector2(0.25, 0)
		badge_style.set_corner_radius_all(4)
		badge_style.content_margin_left = 12
		badge_style.content_margin_right = 12
		badge.add_theme_stylebox_override("panel", badge_style)
		badge.add_child(UiStyle.label("P%d" % (i + 1), 24, UiStyle.INK, true, 0))
		head.add_child(badge)
		var who := UiStyle.label("", 19, players[i].color, false, 5)
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(who)
		var ready_label := UiStyle.label("BEREIT!", 26, Color(0.45, 1, 0.45), true, 8)
		ready_label.rotation = deg_to_rad(-4)
		head.add_child(ready_label)
		var fighter_name := UiStyle.label("", 42, Color.WHITE, true, 12)
		box.add_child(fighter_name)
		var special := _select_tag(box, "SPEZIAL", Color(1, 0.62, 0.2))
		var passive := _select_tag(box, "PASSIV", Color(0.35, 0.7, 1))
		hud.add_child(panel)
		var card := {"node": panel, "who": who, "name": fighter_name, "special": special, "passive": passive,
			"ready": ready_label, "player": i}
		select_cards.append(card)
	# Dunkle Wand direkt hinter den Figuren: die Map bleibt zu ahnen, lenkt aber nicht ab.
	select_shade = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(120, 60)
	select_shade.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.02, 0.02, 0.06, 0.75)
	# Nach allen anderen durchsichtigen Dingen (Wasser, Nebel) zeichnen, sonst übermalen sie die Wand.
	mat.render_priority = 100
	mat.disable_fog = true
	select_shade.material_override = mat
	select_shade.position = Vector3(0, 5, -1.2)
	add_child(select_shade)
	# Was den Figuren im Weg steht (Kisten, Kanonen, Seile), während der Auswahl ausblenden.
	# Böden bleiben: was nicht über die Füße reicht, verdeckt niemanden.
	for node in map_node.find_children("*", "GeometryInstance3D", true, false):
		var g := node as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var bounds := g.global_transform * g.get_aabb()
		if bounds.size.length() > 60.0 or bounds.end.z < -0.6:
			continue
		for p in players:
			if not p.visible:
				continue
			var body := AABB(p.position + Vector3(-0.9, 0.25, -0.6), Vector3(1.8, 2.4 * p.size_scale, 50.0))
			if bounds.intersects(body):
				g.visible = false
				select_hidden.append(g)
				break
	# Namensschilder über den Köpfen vor der dunklen Wand zeichnen.
	# Alle Figuren drehen sich, bis ihr Spieler bereit ist (Computer und Boss drehen sich weiter).
	for p in players:
		p.showcase_spin = true
		p.get_node("Tag").render_priority = 120
		p.get_node("Tag").outline_render_priority = 119


func _select_label(font_size: int, color: Color, wrap := false) -> Label:
	var label := UiStyle.label("", font_size, color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(400, 0)
	return label


## Zeile auf der Spielerkarte: farbiges Schildchen ("SPEZIAL") und daneben der umbrechende Text.
func _select_tag(box: VBoxContainer, tag: String, color: Color) -> Label:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	box.add_child(line)
	var pill := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	style.content_margin_left = 7
	style.content_margin_right = 7
	pill.add_theme_stylebox_override("panel", style)
	pill.custom_minimum_size = Vector2(84, 0)
	pill.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var tag_label := UiStyle.label(tag, 14, UiStyle.INK, false, 0)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(tag_label)
	line.add_child(pill)
	var text := UiStyle.label("", 17, Color(1, 1, 1, 0.95), false, 4)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(310, 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text)
	return text


func _update_select_card(i: int) -> void:
	for card in select_cards:
		if card.get("player", -1) != i:
			continue
		var f: Dictionary = players[i].fighter
		var is_ready: bool = ready_flags[i]
		card.who.text = _player_name(i)
		card.ready.visible = is_ready and not (Settings.solo and i == 1)
		card.name.text = "◀  %s  ▶" % f.get("name", "") if not is_ready or (Settings.solo and i == 1) else f.get("name", "")
		card.special.text = Roster.SPECIALS.get(f.get("special", ""), "")
		card.passive.text = Roster.PASSIVES.get(f.get("passive", ""), "")
		var style := UiStyle.card(players[i].color)
		style.set_border_width_all(5 if is_ready else 3)
		if is_ready:
			style.bg_color = Color(players[i].color.darkened(0.7), 0.9)
		card.node.add_theme_stylebox_override("panel", style)
		# Die Karte wächst mit dem Text, aber nie über den Bildschirm hinaus.
		card.node.size = Vector2(440, 0)


func _remove_select_ui() -> void:
	for card in select_cards:
		card.node.queue_free()
	select_cards.clear()
	if select_shade:
		select_shade.queue_free()
		select_shade = null
	for g in select_hidden:
		if is_instance_valid(g):
			g.visible = true
	select_hidden.clear()


## "Spieler 1", "Spieler 2" oder im Solo-Modus "Computer (Mittel)".
func _player_name(i: int) -> String:
	if Settings.solo and i == 1:
		return "Computer (%s)" % CpuPlayer.LEVELS[Settings.cpu_difficulty()].name
	return "Spieler %d" % (i + 1)


## Kampagne: oben in der Mitte steht, der wievielte Kampf das ist. Bei der Auswahl darunter
## die kleine Geschichte und der Fortschritt als Punkte.
func _create_campaign_label() -> void:
	campaign_label = _select_label(20, Color(1, 0.85, 0.3))
	campaign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	campaign_label.position = Vector2(0, 540)
	campaign_label.size = Vector2(1280, 90)
	var step := Settings.campaign_step()
	var kind := ""
	match step.type:
		"kampf": kind = "Gegner: %s (%s)" % [Roster.FIGHTERS[Settings.choices[1]].name, CpuPlayer.LEVELS[Settings.cpu_difficulty()].name]
		"ziele": kind = "Bonus-Runde"
		"boss": kind = "Endboss"
	campaign_label.text = "%s\n%s\n%s" % [step.intro, kind, Settings.campaign_dots(Settings.campaign_stage)]
	center_label.get_parent().add_child(campaign_label)


## Nach dem Countdown wird die Anzeige klein und wandert nach oben.
func _shrink_campaign_label() -> void:
	if campaign_label == null:
		return
	campaign_label.add_theme_font_size_override("font_size", 18)
	campaign_label.position = Vector2(0, 56)
	campaign_label.size = Vector2(1280, 28)
	campaign_label.text = "Kampf %d / %d · %s" % [Settings.campaign_stage + 1, Settings.CAMPAIGN.size(), Settings.current_map().name]


## Ergebnis eines Kampagnen-Kampfs: gewonnen geht es weiter, verloren versucht man ihn nochmal.
## Der Fortschritt wird sofort gespeichert, man kann also jederzeit ins Menü.
func _campaign_result(won: bool, headline: String) -> void:
	game_over_time = 0.0
	center_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center_label.add_theme_font_size_override("font_size", 34)
	var total := Settings.CAMPAIGN.size()
	if not won:
		Settings.campaign_losses += 1
		Settings.save()
		center_label.text = "%s\nF oder R: Kampf %d nochmal versuchen   Esc: Menü (Fortschritt bleibt)" % [headline, Settings.campaign_stage + 1]
		return
	if Settings.campaign_stage >= total - 1:
		campaign_finished = true
		Settings.campaign_wins += 1
		center_label.text = "KAMPAGNE GESCHAFFT!\nAlle %d Kämpfe gewonnen   Niederlagen unterwegs: %d\nF: zurück ins Menü" % [total, Settings.campaign_losses]
		center_label.add_theme_font_size_override("font_size", 44)
		Settings.campaign_stage = 0
		Settings.campaign_opponents = []
		Settings.campaign_losses = 0
		Settings.save()
		return
	Settings.campaign_stage += 1
	Settings.save()
	var next := Settings.campaign_step()
	var dots := Settings.campaign_dots(Settings.campaign_stage)
	center_label.text = "%s\nWeiter: Kampf %d / %d – %s\n%s\nF: weiter   Esc: Menü (Fortschritt ist gespeichert)" % [
		headline, Settings.campaign_stage + 1, total, next.map, dots]


func _handle_campaign_continue() -> void:
	if game_over_time < 1.2:
		return
	if not (Input.is_action_just_pressed("p1_weak") or Input.is_action_just_pressed("ui_accept")
			or Input.is_action_just_pressed("restart")):
		return
	Audio.sfx("menu_select")
	if campaign_finished:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	else:
		get_tree().reload_current_scene()
