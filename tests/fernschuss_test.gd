extends Node
## Test der Fernkämpfer-Geschosse (Jägerin, Magierin, Hexe): jeder schießt nach vorne, hoch und tief,
## einmal normal und einmal voll aufgeladen, auf einen stillstehenden Gegner. Danach Computer gegen Computer.
## Aufruf: godot --headless res://tests/fernschuss_test.tscn   (Bild: ohne --headless und mit shot=/pfad.png)

const SHOOTERS := {"Hexe": 5, "Jägerin": 6, "Magierin": 10}
const KINDS := ["strong", "strong_hoch", "strong_tief"]

var args := {}
var fight: Node
var fails := 0


func _ready() -> void:
	await get_tree().process_frame
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	Settings.map_index = 0
	Settings.fighters = 2
	Settings.solo = false
	Settings.campaign = false
	Settings.teams = false
	Settings.target_mode = false
	Settings.boss_mode = false
	Settings.items_enabled = false
	Settings.music_volume = 0
	Settings.sfx_volume = 0
	if args.has("shot"):
		await _picture(int(args.get("who", "10")), args.get("kind", "strong"), String(args.shot))
		get_tree().quit()
		return
	for fighter_name in SHOOTERS:
		await _start(SHOOTERS[fighter_name], 0)
		for kind in KINDS:
			var hits := []
			for ladung in [0.0, 1.0]:
				hits.append(await _shoot(kind, ladung))
			var ok: bool = hits[0] > 0.0 and hits[1] > hits[0]
			if not ok:
				fails += 1
			print("%s %s: Schaden normal %.1f, aufgeladen %.1f %s" % [fighter_name, kind, hits[0], hits[1], "OK" if ok else "FEHLER"])
		fight.queue_free()
		await get_tree().process_frame
	for fighter_name in SHOOTERS:
		var shots := await _cpu_match(SHOOTERS[fighter_name])
		if shots == 0:
			fails += 1
		print("Computer %s: %d Geschosse in 40 s %s" % [fighter_name, shots, "OK" if shots > 0 else "FEHLER"])
	print("ERGEBNIS: %s" % ("alles OK" if fails == 0 else "%d Fehler" % fails))
	get_tree().quit(fails)


func _start(shooter: int, foe: int) -> void:
	Settings.choices[0] = shooter
	Settings.choices[1] = foe
	fight = load("res://scenes/fight.tscn").instantiate()
	get_tree().root.add_child.call_deferred(fight)
	await get_tree().process_frame
	await get_tree().process_frame
	for i in fight.ready_flags.size():
		fight.ready_flags[i] = true
	while fight.state < 2:
		await get_tree().physics_frame
	for p in fight.players:
		p.set_physics_process(false)


## Schießt einmal und gibt den Schaden zurück, den der Gegner davon bekommt.
func _shoot(kind: String, ladung: float) -> float:
	var me: CharacterBody3D = fight.players[0]
	var foe: CharacterBody3D = fight.players[1]
	me.global_position = Vector3(-5, 1, 0)
	me.facing = 1
	foe.velocity = Vector3.ZERO
	foe.global_position = Vector3(1.0, 1, 0) if kind != "strong_hoch" else Vector3(-1.5, 6.5, 0)
	foe.damage = 0.0
	await get_tree().create_timer(0.3).timeout
	me._fire_shot(kind, ladung)
	await get_tree().create_timer(1.8).timeout
	return foe.damage


func _cpu_match(shooter: int) -> int:
	Settings.choices[0] = shooter
	Settings.choices[1] = 0
	fight = load("res://scenes/fight.tscn").instantiate()
	get_tree().root.add_child.call_deferred(fight)
	var count := [0]
	var counter := func(n: Node): if n is FernSchuss: count[0] += 1
	get_tree().node_added.connect(counter)
	await get_tree().process_frame
	await get_tree().process_frame
	for i in fight.ready_flags.size():
		fight.ready_flags[i] = true
	while fight.state < 2:
		await get_tree().physics_frame
	for p in fight.players:
		var cpu := CpuPlayer.new()
		fight.add_child(cpu)
		cpu.setup(p, fight.players[1] if p == fight.players[0] else fight.players[0], 2, fight.map_node)
		fight.cpus.append(cpu)
	await get_tree().create_timer(40.0).timeout
	get_tree().node_added.disconnect(counter)
	fight.queue_free()
	await get_tree().process_frame
	return count[0]


## Bild vom Schuss: Figur schießt auf den Gegner, kurz danach Bildschirmfoto.
func _picture(shooter: int, kind: String, path: String) -> void:
	await _start(shooter, 0)
	var me: CharacterBody3D = fight.players[0]
	var foe: CharacterBody3D = fight.players[1]
	me.global_position = Vector3(-4, 1, 0)
	me.facing = 1
	foe.global_position = Vector3(4, 1, 0)
	foe.facing = -1
	await get_tree().create_timer(0.5).timeout
	me.set_physics_process(true)
	me.start_attack(kind)
	me.charge_time = float(args.get("ladung", "1.0")) * me.CHARGE_MAX
	await get_tree().create_timer(float(args.get("wait", "0.55"))).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
