extends Node
## Hilfsskript: macht ein Bild vom Hauptmenü mit gewählter Ansturm-Kachel.
## Aufruf (mit Fenster): godot res://tests/menue_bild.tscn -- solo=0 out=/pfad/bild.png

func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	await get_tree().process_frame
	Settings.solo = args.get("solo", "0") == "1"
	Settings.campaign_stage = int(args.get("stage", "0"))
	Settings.map_index = int(args.get("map", "0"))
	Settings.music_volume = 0
	Audio.apply_volume()
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	get_tree().root.add_child.call_deferred(menu)
	await get_tree().create_timer(1.0).timeout
	var rows: Array = menu._rows()
	for r in rows.size():
		if rows[r].has("horde"):
			menu._select(r, rows[r].find("horde"))
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png(args.get("out", "user://menue.png"))
	get_tree().quit()
