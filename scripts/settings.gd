extends Node
## Spieleinstellungen, die zwischen Menü und Kampf geteilt und auf der Festplatte gespeichert werden.

const SAVE_PATH := "user://settings.cfg"

const MAPS := [
	{"name": "Burg", "scene": "res://scenes/maps/burg.tscn"},
	{"name": "Dorf", "scene": "res://scenes/maps/dorf.tscn"},
	{"name": "Friedhof", "scene": "res://scenes/maps/friedhof.tscn"},
]
const ITEM_RATES := ["Selten", "Normal", "Oft"]
## Sekunden zwischen zwei Items je Häufigkeit (zufällig zwischen den beiden Werten).
const ITEM_INTERVALS := [Vector2(12, 18), Vector2(6, 10), Vector2(3, 5)]

var items_enabled := true
var item_rate := 1
var stocks := 3
var map_index := 0
var choices := [0, 1]


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	items_enabled = cfg.get_value("game", "items_enabled", items_enabled)
	item_rate = cfg.get_value("game", "item_rate", item_rate)
	stocks = cfg.get_value("game", "stocks", stocks)
	map_index = cfg.get_value("game", "map_index", map_index)
	choices = cfg.get_value("game", "choices", choices)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "items_enabled", items_enabled)
	cfg.set_value("game", "item_rate", item_rate)
	cfg.set_value("game", "stocks", stocks)
	cfg.set_value("game", "map_index", map_index)
	cfg.set_value("game", "choices", choices)
	cfg.save(SAVE_PATH)


func current_map() -> Dictionary:
	return MAPS[wrapi(map_index, 0, MAPS.size())]
