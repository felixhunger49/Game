extends Node
## Spieleinstellungen, die zwischen Menü und Kampf geteilt und auf der Festplatte gespeichert werden.

const SAVE_PATH := "user://settings.cfg"

## event: der Map-Effekt (siehe MapEvents), effect: Beschreibung im Menü,
## backdrop: gemaltes Hintergrundbild weit hinter der Arena (optional).
const MAPS := [
	{"name": "Burg", "scene": "res://scenes/maps/burg.tscn", "music": "burg", "event": "kanonen",
		"backdrop": "res://assets/maps/burg/hintergrund.png",
		"effect": "Kanonenkugeln fliegen quer durch die Burg.\nAchte auf das rote Ausrufezeichen!"},
	{"name": "Dorf", "scene": "res://scenes/maps/dorf.tscn", "music": "dorf", "event": "wind",
		"backdrop": "res://assets/maps/dorf/hintergrund.png",
		"effect": "Windböen schieben alle Kämpfer zur Seite.\nDie Pfeile zeigen die Richtung."},
	{"name": "Friedhof", "scene": "res://scenes/maps/friedhof.tscn", "music": "friedhof", "event": "geister",
		"backdrop": "res://assets/maps/friedhof/hintergrund.png",
		"effect": "Weniger Schwerkraft: man springt höher.\nGeister schießen aus leuchtenden Stellen hoch."},
	{"name": "Vulkan", "scene": "res://scenes/maps/vulkan.tscn", "music": "vulkan", "event": "lava",
		"effect": "Lavafontänen schießen aus dem Boden.\nWeg von den glühenden Stellen!"},
	{"name": "Piratenschiff", "scene": "res://scenes/maps/piratenschiff.tscn", "music": "piratenschiff", "event": "wellen",
		"effect": "Seegang: Das Schiff schaukelt und Wellen\nschieben alle zur Seite."},
	{"name": "Eiswelt", "scene": "res://scenes/maps/eiswelt.tscn", "music": "eiswelt", "event": "eis",
		"effect": "Spiegelglatter Boden: man rutscht!\nEiszapfen fallen auf die blauen Stellen."},
	{"name": "Wolkentempel", "scene": "res://scenes/maps/wolkentempel.tscn", "music": "wolkentempel", "event": "blitze",
		"effect": "Blitze schlagen ein.\nGelbe Kreise zeigen, wo es gleich kracht."},
]
const ITEM_RATES := ["Selten", "Normal", "Oft"]
## Sekunden zwischen zwei Items je Häufigkeit (zufällig zwischen den beiden Werten).
const ITEM_INTERVALS := [Vector2(12, 18), Vector2(6, 10), Vector2(3, 5)]

## Aktionen, die man in den Optionen neu belegen kann (ohne "p1_"/"p2_").
const BINDABLE := ["left", "right", "jump", "shield", "weak", "strong", "kick", "special"]
const ACTION_NAMES := {
	"left": "Links", "right": "Rechts", "jump": "Springen", "shield": "Abwehren",
	"weak": "Schwacher Angriff", "strong": "Starker Angriff", "kick": "Tritt", "special": "Spezialattacke",
}

var items_enabled := true
var item_rate := 1
var stocks := 3
var map_index := 0
var choices := [0, 1]
var map_effects := true
var special_charge := true
var music_volume := 7
var sfx_volume := 8

## Standardbelegung aus project.godot, damit man sie wiederherstellen kann.
var _default_events := {}


func _ready() -> void:
	for p in [1, 2]:
		for a in BINDABLE:
			var action := "p%d_%s" % [p, a]
			_default_events[action] = InputMap.action_get_events(action)

	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	items_enabled = cfg.get_value("game", "items_enabled", items_enabled)
	item_rate = cfg.get_value("game", "item_rate", item_rate)
	stocks = cfg.get_value("game", "stocks", stocks)
	map_index = cfg.get_value("game", "map_index", map_index)
	choices = cfg.get_value("game", "choices", choices)
	# Gespeicherte Auswahl kann auf eine inzwischen entfernte Figur zeigen.
	choices = choices.map(func(c): return clampi(c, 0, Roster.FIGHTERS.size() - 1))
	map_effects = cfg.get_value("game", "map_effects", map_effects)
	special_charge = cfg.get_value("game", "special_charge", special_charge)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	if cfg.has_section("controls"):
		for action in cfg.get_section_keys("controls"):
			if action in _default_events:
				_set_events(action, cfg.get_value("controls", action))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "items_enabled", items_enabled)
	cfg.set_value("game", "item_rate", item_rate)
	cfg.set_value("game", "stocks", stocks)
	cfg.set_value("game", "map_index", map_index)
	cfg.set_value("game", "choices", choices)
	cfg.set_value("game", "map_effects", map_effects)
	cfg.set_value("game", "special_charge", special_charge)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	for action in _default_events:
		cfg.set_value("controls", action, InputMap.action_get_events(action))
	cfg.save(SAVE_PATH)


func current_map() -> Dictionary:
	return MAPS[wrapi(map_index, 0, MAPS.size())]


## Belegt eine Aktion neu. Hat eine andere Aktion schon diese Taste, bekommt sie die alte Taste.
func rebind(action: String, event: InputEvent) -> void:
	var old_events := InputMap.action_get_events(action)
	for other in _default_events:
		if other == action:
			continue
		for e in InputMap.action_get_events(other):
			if _same_input(e, event):
				InputMap.action_erase_event(other, e)
				for old in old_events:
					InputMap.action_add_event(other, old)
	_set_events(action, [event])
	save()


func reset_controls() -> void:
	for action in _default_events:
		_set_events(action, _default_events[action])
	save()


## Lesbarer Name der Taste(n) einer Aktion, z. B. "A" oder "Pfeil links".
func key_text(action: String) -> String:
	var names := []
	for e in InputMap.action_get_events(action):
		names.append(event_text(e))
	return " / ".join(names) if names else "—"


func event_text(e: InputEvent) -> String:
	if e is InputEventKey:
		var code: Key = e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
		match code:
			KEY_LEFT: return "Pfeil links"
			KEY_RIGHT: return "Pfeil rechts"
			KEY_UP: return "Pfeil hoch"
			KEY_DOWN: return "Pfeil runter"
			KEY_SPACE: return "Leertaste"
			KEY_SHIFT: return "Umschalt"
			KEY_CTRL: return "Strg"
			KEY_ALT: return "Alt"
			KEY_ENTER: return "Enter"
			KEY_KP_ENTER: return "Ziffernblock Enter"
		var shown := code
		if e.physical_keycode != KEY_NONE and DisplayServer.get_name() != "headless":
			# Zeigt die Taste so, wie sie auf der eigenen Tastatur beschriftet ist (z. B. Z/Y bei QWERTZ).
			shown = DisplayServer.keyboard_get_keycode_from_physical(code)
		return OS.get_keycode_string(shown)
	if e is InputEventJoypadButton:
		return "Pad %d Knopf %d" % [e.device + 1, e.button_index]
	if e is InputEventJoypadMotion:
		return "Pad %d Stick %d%s" % [e.device + 1, e.axis, "+" if e.axis_value > 0 else "-"]
	return e.as_text()


func _set_events(action: String, events: Array) -> void:
	InputMap.action_erase_events(action)
	for e in events:
		if e is InputEvent:
			InputMap.action_add_event(action, e)


func _same_input(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ka: Key = a.physical_keycode if a.physical_keycode != KEY_NONE else a.keycode
		var kb: Key = b.physical_keycode if b.physical_keycode != KEY_NONE else b.keycode
		return ka == kb
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index and a.device == b.device
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value) and a.device == b.device
	return false
