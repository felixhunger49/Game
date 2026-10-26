extends Node3D
## Hauptmenü mit Optionen. Steuerung: W/S oder Pfeile hoch/runter wählen,
## A/D oder Pfeile links/rechts ändern, F, J oder Enter bestätigen, Esc zurück.

enum Page { MAIN, OPTIONS, CONTROLS }

var page := Page.MAIN
var selected := 0
var time := 0.0
var map_node: Node3D
## Spieler, dessen Tasten gerade auf der Steuerungs-Seite angezeigt werden.
var controls_player := 1
## Aktion, die gerade auf einen Tastendruck wartet ("" = keine).
var waiting_action := ""
## Nach dem Belegen einer Taste wird der Tastendruck nicht gleich als Menü-Eingabe gewertet.
var ignore_input_frames := 0

@onready var camera: Camera3D = $Camera3D
@onready var entries_box: VBoxContainer = $UI/Entries
@onready var info_label: Label = $UI/Info


func _ready() -> void:
	_load_map()
	_refresh()
	Audio.music("menu")


func _process(delta: float) -> void:
	time += delta
	camera.position = Vector3(sin(time * 0.15) * 7.0, 4.0 + sin(time * 0.1), 19.0)
	camera.look_at(Vector3(0, 1.5, 0))

	if waiting_action != "":
		return
	if ignore_input_frames > 0:
		ignore_input_frames -= 1
		return

	var entries := _entries()
	if _pressed(["p1_jump", "p2_jump", "ui_up"]):
		selected = wrapi(selected - 1, 0, entries.size())
		Audio.sfx("menu_move")
		_refresh()
	elif _pressed(["p1_shield", "p2_shield", "ui_down"]):
		selected = wrapi(selected + 1, 0, entries.size())
		Audio.sfx("menu_move")
		_refresh()
	elif _pressed(["p1_left", "p2_left", "ui_left"]):
		_change(entries[selected], -1)
	elif _pressed(["p1_right", "p2_right", "ui_right"]):
		_change(entries[selected], 1)
	elif _pressed(["p1_weak", "p2_weak", "ui_accept"]):
		_activate(entries[selected])
	elif Input.is_action_just_pressed("back") and page != Page.MAIN:
		Audio.sfx("menu_back")
		_open(Page.MAIN)


## Wartet auf die neue Taste für eine Aktion (Tastatur oder Gamepad). Esc bricht ab.
func _input(event: InputEvent) -> void:
	if waiting_action == "" or not event.is_pressed() or event.is_echo():
		return
	var accepted := false
	if event is InputEventKey:
		if event.physical_keycode == KEY_ESCAPE:
			waiting_action = ""
			Audio.sfx("menu_back")
			ignore_input_frames = 2
			_refresh()
			get_viewport().set_input_as_handled()
			return
		var key := InputEventKey.new()
		key.physical_keycode = event.physical_keycode
		Settings.rebind(waiting_action, key)
		accepted = true
	elif event is InputEventJoypadButton:
		var button := InputEventJoypadButton.new()
		button.button_index = event.button_index
		button.device = event.device
		Settings.rebind(waiting_action, button)
		accepted = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		var motion := InputEventJoypadMotion.new()
		motion.axis = event.axis
		motion.axis_value = signf(event.axis_value)
		motion.device = event.device
		Settings.rebind(waiting_action, motion)
		accepted = true
	if accepted:
		waiting_action = ""
		ignore_input_frames = 2
		Audio.sfx("menu_select")
		_refresh()
		get_viewport().set_input_as_handled()


func _entries() -> Array:
	match page:
		Page.OPTIONS:
			return ["items", "rate", "stocks", "map_effects", "special_charge", "music", "sfx", "back"]
		Page.CONTROLS:
			var list := ["player"]
			for a in Settings.BINDABLE:
				list.append("key:" + a)
			list.append_array(["reset", "back"])
			return list
	if Settings.solo:
		return ["play", "mode", "cpu", "targets", "boss", "map", "options", "controls", "quit"]
	return ["play", "mode", "targets", "boss", "map", "options", "controls", "quit"]


func _entry_text(entry: String) -> String:
	if entry.begins_with("key:"):
		var action := "p%d_%s" % [controls_player, entry.substr(4)]
		var key := "… Taste drücken (Esc: abbrechen) …" if waiting_action == action else Settings.key_text(action)
		return "%s:  %s" % [Settings.ACTION_NAMES[entry.substr(4)], key]
	match entry:
		"play": return "Kampf starten"
		"targets": return "Ziele zerstören (gegen die Uhr)"
		"boss": return "Endboss: Riesen-Kampfroboter"
		"map": return "Map:  ◀ %s ▶" % Settings.current_map().name
		"mode": return "Modus:  ◀ %s ▶" % ("Solo gegen Computer" if Settings.solo else "Zwei Spieler")
		"cpu": return "Computer:  ◀ %s ▶" % CpuPlayer.LEVELS[Settings.cpu_level].name
		"options": return "Optionen"
		"controls": return "Steuerung anpassen"
		"quit": return "Beenden"
		"items": return "Items:  ◀ %s ▶" % ("An" if Settings.items_enabled else "Aus")
		"rate": return "Item-Häufigkeit:  ◀ %s ▶" % Settings.ITEM_RATES[Settings.item_rate]
		"stocks": return "Leben:  ◀ %d ▶" % Settings.stocks
		"map_effects": return "Map-Effekte:  ◀ %s ▶" % ("An" if Settings.map_effects else "Aus")
		"special_charge": return "Spezial aufladen:  ◀ %s ▶" % ("An" if Settings.special_charge else "Aus")
		"music": return "Musik:  ◀ %s ▶" % _bar(Settings.music_volume)
		"sfx": return "Geräusche & Stimmen:  ◀ %s ▶" % _bar(Settings.sfx_volume)
		"player": return "Spieler:  ◀ %d ▶" % controls_player
		"reset": return "Standard wiederherstellen"
		"back": return "Zurück"
	return entry


func _change(entry: String, step: int) -> void:
	match entry:
		"map":
			Settings.map_index = wrapi(Settings.map_index + step, 0, Settings.MAPS.size())
			_load_map()
		"mode":
			Settings.solo = not Settings.solo
		"cpu":
			Settings.cpu_level = clampi(Settings.cpu_level + step, 0, CpuPlayer.LEVELS.size() - 1)
		"items":
			Settings.items_enabled = not Settings.items_enabled
		"rate":
			Settings.item_rate = clampi(Settings.item_rate + step, 0, Settings.ITEM_RATES.size() - 1)
		"stocks":
			Settings.stocks = clampi(Settings.stocks + step, 1, 9)
		"map_effects":
			Settings.map_effects = not Settings.map_effects
		"special_charge":
			Settings.special_charge = not Settings.special_charge
		"music":
			Settings.music_volume = clampi(Settings.music_volume + step, 0, 10)
			Audio.apply_volume()
		"sfx":
			Settings.sfx_volume = clampi(Settings.sfx_volume + step, 0, 10)
			Audio.apply_volume()
		"player":
			controls_player = 2 if controls_player == 1 else 1
		_:
			return
	Audio.sfx("menu_move")
	Settings.save()
	_refresh()


func _activate(entry: String) -> void:
	if entry.begins_with("key:"):
		waiting_action = "p%d_%s" % [controls_player, entry.substr(4)]
		Audio.sfx("menu_select")
		_refresh()
		return
	match entry:
		"play", "targets", "boss":
			Settings.target_mode = entry == "targets"
			Settings.boss_mode = entry == "boss"
			Audio.sfx("menu_select")
			get_tree().change_scene_to_file("res://scenes/fight.tscn")
		"options":
			Audio.sfx("menu_select")
			_open(Page.OPTIONS)
		"controls":
			Audio.sfx("menu_select")
			_open(Page.CONTROLS)
		"quit":
			get_tree().quit()
		"back":
			Audio.sfx("menu_back")
			_open(Page.MAIN)
		"reset":
			Settings.reset_controls()
			Audio.sfx("menu_select")
			_refresh()
		"map", "mode", "cpu", "items", "rate", "stocks", "map_effects", "special_charge", "player":
			_change(entry, 1)


func _open(new_page: Page) -> void:
	page = new_page
	selected = 0
	_refresh()


func _refresh() -> void:
	for child in entries_box.get_children():
		child.queue_free()
	var entries := _entries()
	var small := page == Page.CONTROLS
	for i in entries.size():
		var label := Label.new()
		label.text = ("▶  " if i == selected else "") + _entry_text(entries[i])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var size := 40 if i == selected else 34
		if small:
			size = 28 if i == selected else 24
		label.add_theme_font_size_override("font_size", size)
		label.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if i == selected else Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		label.add_theme_constant_override("outline_size", 12)
		entries_box.add_child(label)
	entries_box.add_theme_constant_override("separation", 2 if small else 8)
	info_label.offset_top = 620 if page != Page.MAIN else 500
	match page:
		Page.CONTROLS:
			info_label.text = "Eintrag wählen und F drücken, dann die neue Taste drücken.\nIst die Taste schon belegt, tauschen die beiden Aktionen."
		Page.OPTIONS:
			info_label.text = "Spezial aufladen: Die Spezialattacke braucht eine volle Energieleiste.\nSie füllt sich durch Treffen, Getroffenwerden und langsam mit der Zeit."
		_:
			if entries[selected] == "map":
				info_label.text = Settings.current_map().effect + ("" if Settings.map_effects else "\n(Map-Effekte sind in den Optionen ausgeschaltet)")
			else:
				info_label.text = "W/S wählen   A/D ändern   F bestätigen"


func _bar(level: int) -> String:
	return "▮".repeat(level) + "▯".repeat(10 - level)


func _load_map() -> void:
	if map_node:
		map_node.queue_free()
	map_node = load(Settings.current_map().scene).instantiate()
	add_child(map_node)


func _pressed(actions: Array) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			return true
	return false
