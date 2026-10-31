extends Node
## Test gegen hängende Zeitlupe: Computer gegen Computer kämpfen, und die Zeit (Engine.time_scale)
## muss nach jedem Treffer wieder auf 1.0 zurück. Misst, wie lange sie am Stück unter 1.0 bleibt.
## Aufruf: godot --headless res://tests/zeitlupe_test.tscn -- map=0 fighters=4 seconds=60

var args := {}
var fight: Node
var t := 0.0
var slow_since := -1
var longest := 0
var slow_count := 0
var finished := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	seed(int(args.get("seed", "7")))
	Settings.map_index = int(args.get("map", "0"))
	Settings.fighters = int(args.get("fighters", "2"))
	Settings.solo = false
	Settings.campaign = false
	Settings.teams = false
	Settings.target_mode = false
	Settings.boss_mode = false
	Settings.stocks = 3
	Settings.music_volume = 0
	Settings.sfx_volume = 0
	fight = load("res://scenes/fight.tscn").instantiate()
	get_tree().root.add_child.call_deferred(fight)
	await get_tree().process_frame
	await get_tree().process_frame
	for i in fight.ready_flags.size():
		fight.ready_flags[i] = true


func _process(_delta: float) -> void:
	if fight == null or not fight.is_inside_tree() or fight.state < 2 or finished:
		return
	var now := Time.get_ticks_msec()
	if Engine.time_scale < 0.999:
		if slow_since < 0:
			slow_since = now
			slow_count += 1
		longest = maxi(longest, now - slow_since)
	else:
		slow_since = -1
	t += get_process_delta_time() / maxf(Engine.time_scale, 0.01)
	if fight.state == 2:
		var controlled: Array = fight.cpus.map(func(c): return c.me)
		for p in fight.players:
			if p.visible and not controlled.has(p):
				var cpu := CpuPlayer.new()
				fight.add_child(cpu)
				cpu.setup(p, fight.players[1] if p == fight.players[0] else fight.players[0], 2, fight.map_node)
				fight.cpus.append(cpu)
	if t >= float(args.get("seconds", "60")) or fight.state == 3:
		finished = true
		print("RESULT map=%d zeitlupen=%d laengste=%d ms rest_time_scale=%.2f" % [Settings.map_index, slow_count, longest, Engine.time_scale])
		get_tree().quit(1 if longest > 1500 else 0)
