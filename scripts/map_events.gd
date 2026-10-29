class_name MapEvents
extends Node3D
## Der Map-Effekt, der das Gameplay jeder Map verändert:
##   kanonen (Burg):     Kanonenkugeln fliegen quer über die Arena, vorher warnt ein rotes Ausrufezeichen.
##   wind (Dorf):        Windböen schieben alle Kämpfer zur Seite, vorher zeigen Pfeile die Richtung.
##   geister (Friedhof): weniger Schwerkraft, und Geister schießen aus leuchtenden Stellen hoch.
##   lava (Vulkan):      Lavafontänen schießen aus glühenden Stellen am Boden hoch.
##   wellen (Piratenschiff): Seegang: das Schiff schaukelt und Wellen schieben alle zur Seite.
##   eis (Eiswelt):      glatter Boden, und Eiszapfen fallen auf markierte Stellen.
##   blitze (Wolkentempel): Blitze schlagen an markierten Stellen ein.
##   gong (Tempel):      der Gong schlägt, eine goldene Schockwelle läuft über den Boden – drüberspringen!
##   drohne (Neonstadt): eine Drohne verfolgt einen Kämpfer mit dem Laserpunkt und feuert dann.
##   felsbrocken (Dschungel): ein riesiger Felsbrocken rollt durch die Arena – rauf auf die Plattformen!
##   treibsand (Wüste):  an markierten Stellen wird der Boden zu Treibsand: langsam und kaum Sprungkraft.
##   blasen (Unterwasser): weniger Schwerkraft, Blasen-Geysire schleudern alle nach oben.

## Die Bühne reicht von x = -8 bis 8, die schwebenden Plattformen liegen bei y = 2.6.
const STAGE_HALF_WIDTH := 7.5
const WARN_TIME := 1.5

const CANNON_ATTACK := {"damage": 12.0, "base": 6.0, "scale": 0.17, "angle": Vector2(1, 0.45)}
const CANNON_SPEED := 15.0
const CANNON_RADIUS := 0.9

const WIND_SPEED := 5.0
const WIND_TIME := 4.0

const GHOST_ATTACK := {"damage": 10.0, "base": 8.0, "scale": 0.15, "angle": Vector2(0.15, 1)}
const GHOST_RADIUS := 1.3
const GHOST_GRAVITY := 0.72

const LAVA_ATTACK := {"damage": 12.0, "base": 8.5, "scale": 0.16, "angle": Vector2(0.15, 1)}
const ICICLE_ATTACK := {"damage": 11.0, "base": 6.0, "scale": 0.14, "angle": Vector2(0.6, 0.5)}
const BOLT_ATTACK := {"damage": 13.0, "base": 7.0, "scale": 0.17, "angle": Vector2(0.4, 1)}
const STRIKE_RADIUS := 1.2
## Auf Eis bremst und beschleunigt man nur mit diesem Anteil der normalen Kraft.
const ICE_GRIP := 0.22
const WAVE_SPEED := 4.0
const WAVE_TIME := 3.5

const GONG_ATTACK := {"damage": 8.0, "base": 6.5, "scale": 0.13, "angle": Vector2(0.5, 1)}
const GONG_WAVE_SPEED := 7.0
const DRONE_ATTACK := {"damage": 11.0, "base": 6.5, "scale": 0.15, "angle": Vector2(0.5, 0.8)}
const DRONE_AIM_TIME := 2.0
const BOULDER_ATTACK := {"damage": 13.0, "base": 7.5, "scale": 0.17, "angle": Vector2(1, 0.6)}
const BOULDER_SPEED := 10.0
const BOULDER_RADIUS := 1.1
const SAND_RADIUS := 1.6
const SAND_TIME := 5.0
## Im Treibsand: Anteil der normalen Laufgeschwindigkeit und Sprungkraft.
const SAND_SPEED := 0.35
const SAND_JUMP := 0.55
const BUBBLE_RADIUS := 1.2
const BUBBLE_TIME := 1.4
const BUBBLE_LIFT := 13.0
const WATER_GRAVITY := 0.85

var kind := ""
var players: Array = []
var timer := 0.0
## Laufende Ereignisse: jedes ist ein Dictionary mit "phase", "time" und eigenen Werten.
var events: Array = []
var hud_label: Label
## Treibsand: normale Lauf- und Sprungwerte jedes Kämpfers.
var base_values := {}


func setup(event_kind: String, all_players: Array, label: Label) -> void:
	kind = event_kind
	players = all_players
	hud_label = label
	timer = randf_range(4.0, 6.0)
	if kind == "geister":
		for p in players:
			p.gravity *= GHOST_GRAVITY
	if kind == "eis":
		for p in players:
			p.ground_grip = ICE_GRIP
	if kind == "blasen":
		for p in players:
			p.gravity *= WATER_GRAVITY
	for p in players:
		base_values[p] = [p.speed, p.jump_velocity]


func _physics_process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		_start_event()
	for e in events.duplicate():
		e.time += delta
		match kind:
			"kanonen": _update_cannon(e, delta)
			"wind": _update_wind(e, delta)
			"geister": _update_ghost(e, delta)
			"lava", "eis", "blitze": _update_strike(e, delta)
			"wellen": _update_wave(e, delta)
			"gong": _update_gong(e, delta)
			"drohne": _update_drone(e, delta)
			"felsbrocken": _update_boulder(e, delta)
			"treibsand": _update_sand(e, delta)
			"blasen": _update_bubbles(e, delta)


func stop() -> void:
	for p in players:
		p.wind_speed = 0.0
	_rock_ship(0.0)
	_free_from_sand()
	for e in events:
		for key in ["warn", "ball", "marker", "ghost", "particles", "strike", "wave", "drone", "beam", "rock", "sand", "column"]:
			if e.has(key) and is_instance_valid(e[key]):
				e[key].queue_free()
	events.clear()
	hud_label.text = ""
	set_physics_process(false)


func _start_event() -> void:
	match kind:
		"kanonen":
			timer = randf_range(6.0, 10.0)
			var side := 1 if randf() < 0.5 else -1
			# Auf Bodenhöhe oder auf Höhe der Plattformen.
			var height := 0.9 if randf() < 0.6 else 3.5
			var warn := _warning_label("!", Color(1, 0.2, 0.15), Vector3(side * STAGE_HALF_WIDTH, height, 0.5))
			events.append({"phase": "warn", "time": 0.0, "side": side, "height": height, "warn": warn, "hit": []})
			hud_label.text = "Kanone von " + ("rechts!" if side > 0 else "links!") + ("  Spring drüber!" if height < 2.0 else "  Bleib unten!")
			Audio.sfx("warning")
		"wind":
			timer = randf_range(9.0, 13.0) + WIND_TIME
			var dir := 1 if randf() < 0.5 else -1
			var arrows := "→ → →" if dir > 0 else "← ← ←"
			var warn := _warning_label(arrows, Color(0.85, 0.95, 1.0), Vector3(0, 5.0, 0))
			events.append({"phase": "warn", "time": 0.0, "dir": dir, "warn": warn})
			hud_label.text = "Wind kommt " + ("von links!" if dir > 0 else "von rechts!")
			Audio.sfx("warning", 0.8)
		"geister":
			timer = randf_range(5.0, 8.0)
			var x := randf_range(-STAGE_HALF_WIDTH + 0.5, STAGE_HALF_WIDTH - 0.5)
			# Meistens taucht der Geist unter einem Kämpfer auf, damit man ausweichen muss.
			var targets := players.filter(func(p): return p.visible and p.is_on_floor())
			if not targets.is_empty() and randf() < 0.7:
				x = clampf(targets.pick_random().position.x, -STAGE_HALF_WIDTH, STAGE_HALF_WIDTH)
			var marker := _ground_marker(x)
			events.append({"phase": "warn", "time": 0.0, "x": x, "marker": marker, "hit": []})
			Audio.sfx("ghost_warn")
		"lava", "eis", "blitze":
			timer = randf_range(4.0, 7.0) if kind != "blitze" else randf_range(3.5, 6.0)
			var x := randf_range(-STAGE_HALF_WIDTH + 0.5, STAGE_HALF_WIDTH - 0.5)
			# Meistens trifft es die Stelle unter einem Kämpfer, damit man ausweichen muss.
			var targets := players.filter(func(p): return p.visible)
			if not targets.is_empty() and randf() < 0.7:
				x = clampf(targets.pick_random().position.x, -STAGE_HALF_WIDTH, STAGE_HALF_WIDTH)
			var colors := {"lava": Color(1.0, 0.4, 0.05, 0.7), "eis": Color(0.6, 0.9, 1.0, 0.7), "blitze": Color(1.0, 0.95, 0.3, 0.7)}
			var marker := _ground_marker(x, colors[kind], STRIKE_RADIUS)
			events.append({"phase": "warn", "time": 0.0, "x": x, "marker": marker, "hit": []})
			Audio.sfx("warning", 1.3 if kind == "blitze" else 1.0)
		"wellen":
			timer = randf_range(8.0, 12.0) + WAVE_TIME
			var dir := 1 if randf() < 0.5 else -1
			var arrows := "~ → ~" if dir > 0 else "~ ← ~"
			var warn := _warning_label(arrows, Color(0.6, 0.85, 1.0), Vector3(0, 5.0, 0))
			events.append({"phase": "warn", "time": 0.0, "dir": dir, "warn": warn})
			hud_label.text = "Welle von " + ("links!" if dir > 0 else "rechts!")
			Audio.sfx("warning", 0.8)
		"gong":
			timer = randf_range(7.0, 10.0)
			var warn := _warning_label("GONG!", Color(1.0, 0.8, 0.3), Vector3(0, 5.5, 0))
			events.append({"phase": "warn", "time": 0.0, "warn": warn, "hit": []})
			hud_label.text = "Der Gong schlägt gleich – spring über die Welle!"
			Audio.sfx("warning", 0.7)
		"drohne":
			timer = randf_range(6.0, 9.0) + DRONE_AIM_TIME
			var targets := players.filter(func(p): return p.visible)
			if targets.is_empty():
				return
			var target: CharacterBody3D = targets.pick_random()
			var drone := _drone()
			drone.position = Vector3(target.position.x, 12.0, 0.4)
			var marker := _ground_marker(target.position.x, Color(1.0, 0.1, 0.1, 0.8), 0.35)
			events.append({"phase": "aim", "time": 0.0, "target": target, "x": target.position.x, "floor": target.position.y,
				"drone": drone, "marker": marker, "hit": []})
			hud_label.text = "Die Drohne zielt auf %s!" % ("Spieler %d" % target.player_id)
			Audio.sfx("warning", 1.2)
		"felsbrocken":
			timer = randf_range(9.0, 13.0)
			var side := 1 if randf() < 0.5 else -1
			var warn := _warning_label("!", Color(1, 0.6, 0.15), Vector3(side * STAGE_HALF_WIDTH, 1.2, 0.5))
			events.append({"phase": "warn", "time": 0.0, "side": side, "warn": warn, "hit": []})
			hud_label.text = "Felsbrocken von " + ("rechts!" if side > 0 else "links!") + "  Rauf auf die Plattformen!"
			Audio.sfx("warning", 0.8)
		"treibsand":
			timer = randf_range(8.0, 11.0)
			var x := randf_range(-STAGE_HALF_WIDTH + 1.5, STAGE_HALF_WIDTH - 1.5)
			var targets := players.filter(func(p): return p.visible and p.is_on_floor())
			if not targets.is_empty() and randf() < 0.7:
				x = clampf(targets.pick_random().position.x, -STAGE_HALF_WIDTH + 1.0, STAGE_HALF_WIDTH - 1.0)
			var marker := _ground_marker(x, Color(0.85, 0.6, 0.25, 0.7), SAND_RADIUS)
			var ground := _ground_y(x)
			marker.position.y = ground + 0.04
			events.append({"phase": "warn", "time": 0.0, "x": x, "ground": ground, "marker": marker})
			hud_label.text = "Treibsand! Weg von der markierten Stelle!"
			Audio.sfx("warning", 0.9)
		"blasen":
			timer = randf_range(5.0, 8.0)
			var x := randf_range(-STAGE_HALF_WIDTH + 0.5, STAGE_HALF_WIDTH - 0.5)
			var targets := players.filter(func(p): return p.visible)
			if not targets.is_empty() and randf() < 0.7:
				x = clampf(targets.pick_random().position.x, -STAGE_HALF_WIDTH, STAGE_HALF_WIDTH)
			var marker := _ground_marker(x, Color(0.5, 0.9, 1.0, 0.7), BUBBLE_RADIUS)
			var ground := _ground_y(x)
			marker.position.y = ground + 0.04
			events.append({"phase": "warn", "time": 0.0, "x": x, "ground": ground, "marker": marker})
			Audio.sfx("warning", 1.4)


# --- Burg: Kanonenkugeln -------------------------------------------------------

func _update_cannon(e: Dictionary, delta: float) -> void:
	if e.phase == "warn":
		e.warn.modulate.a = 1.0 if int(e.time * 8.0) % 2 == 0 else 0.35
		if e.time >= WARN_TIME:
			e.warn.queue_free()
			hud_label.text = ""
			e.phase = "fly"
			e.time = 0.0
			e.ball = _cannonball()
			e.ball.position = Vector3(e.side * 20.0, e.height, 0)
			Audio.sfx("cannon")
		return
	var ball: Node3D = e.ball
	ball.position.x -= e.side * CANNON_SPEED * delta
	ball.rotation.z += e.side * 8.0 * delta
	for p in players:
		if not p.visible or p in e.hit:
			continue
		if (p.global_position + Vector3(0, 0.9, 0)).distance_to(ball.global_position) < CANNON_RADIUS:
			e.hit.append(p)
			var dir := Vector3(-e.side * CANNON_ATTACK.angle.x, CANNON_ATTACK.angle.y, 0).normalized()
			p.take_hit(CANNON_ATTACK, dir)
	if absf(ball.position.x) > 21.0:
		ball.queue_free()
		events.erase(e)


func _cannonball() -> MeshInstance3D:
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.9
	ball.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.14)
	mat.metallic = 0.6
	mat.roughness = 0.35
	ball.material_override = mat
	add_child(ball)
	return ball


# --- Dorf: Windböen --------------------------------------------------------------

func _update_wind(e: Dictionary, _delta: float) -> void:
	if e.phase == "warn":
		e.warn.modulate.a = 1.0 if int(e.time * 6.0) % 2 == 0 else 0.35
		if e.time >= WARN_TIME:
			e.warn.queue_free()
			e.phase = "blow"
			e.time = 0.0
			e.particles = _wind_particles(e.dir)
			hud_label.text = ""
			Audio.sfx("wind")
		return
	# Die Böe wird stärker und lässt dann wieder nach.
	var strength := sin(clampf(e.time / WIND_TIME, 0.0, 1.0) * PI)
	for p in players:
		p.wind_speed = e.dir * WIND_SPEED * strength
	if e.time >= WIND_TIME:
		for p in players:
			p.wind_speed = 0.0
		e.particles.emitting = false
		var particles: Node = e.particles
		get_tree().create_timer(2.0).timeout.connect(particles.queue_free)
		events.erase(e)


func _wind_particles(dir: int) -> CPUParticles3D:
	var parts := CPUParticles3D.new()
	parts.amount = 80
	parts.lifetime = 1.6
	parts.position = Vector3(-dir * 14.0, 3.0, 0.5)
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	parts.emission_box_extents = Vector3(1, 4, 1)
	parts.direction = Vector3(dir, 0, 0)
	parts.spread = 6.0
	parts.gravity = Vector3(0, -0.5, 0)
	parts.initial_velocity_min = 16.0
	parts.initial_velocity_max = 22.0
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.5, 0.06)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0.55)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = mat
	parts.mesh = mesh
	add_child(parts)
	return parts


# --- Friedhof: Geister -----------------------------------------------------------

func _update_ghost(e: Dictionary, delta: float) -> void:
	if e.phase == "warn":
		var pulse := 0.5 + 0.5 * sin(e.time * 14.0)
		e.marker.scale = Vector3.ONE * (0.8 + 0.3 * pulse)
		if e.time >= WARN_TIME * 0.8:
			e.marker.queue_free()
			e.phase = "rise"
			e.time = 0.0
			e.ghost = _ghost(e.x)
			Audio.sfx("ghost")
		return
	var ghost: Node3D = e.ghost
	ghost.position.y += 9.0 * delta
	ghost.scale = Vector3.ONE * (1.0 + e.time)
	var body_mat: StandardMaterial3D = ghost.get_child(0).material_override
	body_mat.albedo_color.a = maxf(0.75 - e.time * 0.7, 0.0)
	for p in players:
		if not p.visible or p in e.hit:
			continue
		var dx: float = p.position.x - e.x
		if absf(dx) < GHOST_RADIUS and p.position.y < ghost.position.y + 0.5 and p.position.y > -1.0:
			e.hit.append(p)
			var dir := Vector3(GHOST_ATTACK.angle.x * signf(dx + 0.01), GHOST_ATTACK.angle.y, 0).normalized()
			p.take_hit(GHOST_ATTACK, dir)
	if e.time > 1.1:
		ghost.queue_free()
		events.erase(e)


func _ground_marker(x: float, color := Color(0.7, 0.4, 1.0, 0.6), radius := GHOST_RADIUS) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.05
	marker.mesh = disc
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	marker.material_override = mat
	marker.position = Vector3(x, 0.04, 0)
	add_child(marker)
	return marker


func _ghost(x: float) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(x, 0.0, 0)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.55
	capsule.height = 1.8
	body.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.85, 0.8, 1.0, 0.75)
	body.material_override = mat
	body.position.y = 0.9
	root.add_child(body)
	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.5, 1.0)
	light.light_energy = 2.5
	light.omni_range = 4.0
	light.position.y = 1.0
	root.add_child(light)
	add_child(root)
	return root


# --- Vulkan, Eiswelt, Wolkentempel: Einschläge an markierten Stellen ---------------

func _update_strike(e: Dictionary, delta: float) -> void:
	if e.phase == "warn":
		var pulse := 0.5 + 0.5 * sin(e.time * 14.0)
		e.marker.scale = Vector3.ONE * (0.8 + 0.3 * pulse)
		if e.time >= WARN_TIME:
			e.marker.queue_free()
			e.phase = "active"
			e.time = 0.0
			e.strike = _strike_node(e.x)
			Audio.sfx({"lava": "lava", "eis": "ice_crack", "blitze": "thunder"}[kind])
		return
	var node: Node3D = e.strike
	var atk: Dictionary = {}
	var hit_zone := false
	match kind:
		"lava":
			# Die Fontäne schießt hoch und wird dabei breiter.
			var grow := minf(e.time * 7.0, 1.0)
			var fade := clampf((1.0 - e.time) * 2.5, 0.0, 1.0)
			var column: Node3D = node.get_node("Body")
			column.scale = Vector3((fade + 0.2) * (1.0 + 0.15 * sin(e.time * 30.0)), grow, fade + 0.2)
			column.position.y = 3.0 * grow
			atk = LAVA_ATTACK
			hit_zone = e.time < 0.5
		"eis":
			# Der Eiszapfen fällt von oben herunter und zerspringt am Boden.
			node.position.y = maxf(12.0 - e.time * 22.0, 0.0)
			atk = ICICLE_ATTACK
			hit_zone = node.position.y > 0.0
		"blitze":
			node.visible = int(e.time * 30.0) % 2 == 0
			atk = BOLT_ATTACK
			hit_zone = e.time < 0.3
	if hit_zone:
		for p in players:
			if not p.visible or p in e.hit:
				continue
			var dx: float = p.position.x - e.x
			var inside: bool = absf(dx) < STRIKE_RADIUS
			if kind == "eis":
				inside = inside and node.position.y < p.position.y + 2.0 and node.position.y > p.position.y - 0.5
			elif kind == "lava":
				inside = inside and p.position.y < 6.0
			if inside:
				e.hit.append(p)
				var dir := Vector3(atk.angle.x * signf(dx + 0.01), atk.angle.y, 0).normalized()
				p.take_hit(atk, dir)
	var duration: float = {"lava": 1.0, "eis": 0.9, "blitze": 0.45}[kind]
	if e.time > duration:
		node.queue_free()
		events.erase(e)


func _strike_node(x: float) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(x, 0.0, 0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var body := MeshInstance3D.new()
	body.name = "Body"
	var light := OmniLight3D.new()
	light.omni_range = 5.0
	light.light_energy = 3.0
	match kind:
		"lava":
			# Säule aus fließender Lava, dazu spritzende Lavabrocken, Spritzer am Boden und Rauch.
			var column := CylinderMesh.new()
			column.top_radius = 0.7
			column.bottom_radius = 0.45
			column.height = 6.0
			column.radial_segments = 16
			body.mesh = column
			body.position.y = 3.0
			var lava := MapFX.lava_material(MapFX.tex("lava"), 4.0)
			lava.set_shader_parameter("vertical", true)
			lava.set_shader_parameter("tiling", 0.6)
			body.material_override = lava
			root.add_child(_lava_burst())
			light.light_color = Color(1, 0.45, 0.1)
			light.light_energy = 5.0
			light.omni_range = 7.0
		"eis":
			var cone := CylinderMesh.new()
			cone.top_radius = 0.45
			cone.bottom_radius = 0.0
			cone.height = 1.8
			body.mesh = cone
			body.position.y = 0.9
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			mat.albedo_color = Color(0.7, 0.92, 1.0, 0.9)
			mat.roughness = 0.1
			light.light_color = Color(0.6, 0.85, 1.0)
			light.light_energy = 1.0
			root.position.y = 12.0
		"blitze":
			var bolt := BoxMesh.new()
			bolt.size = Vector3(0.35, 30.0, 0.35)
			body.mesh = bolt
			body.position.y = 15.0
			mat.albedo_color = Color(1.0, 1.0, 0.75, 0.95)
			light.light_color = Color(1, 1, 0.7)
			light.light_energy = 6.0
			light.omni_range = 9.0
	if body.material_override == null:
		body.material_override = mat
	root.add_child(body)
	light.position.y = 1.0
	root.add_child(light)
	add_child(root)
	return root


## Lavabrocken, die hochspritzen und im Bogen zurückfallen, ein Spritzring am Boden und Rauch.
func _lava_burst() -> Node3D:
	var root := Node3D.new()
	var blob_mat := StandardMaterial3D.new()
	blob_mat.albedo_color = Color(1.0, 0.45, 0.05)
	blob_mat.emission_enabled = true
	blob_mat.emission = Color(1.0, 0.5, 0.1)
	blob_mat.emission_energy_multiplier = 4.0
	var blob := SphereMesh.new()
	blob.radius = 0.16
	blob.height = 0.32
	blob.material = blob_mat
	var blobs := CPUParticles3D.new()
	blobs.mesh = blob
	blobs.amount = 45
	blobs.lifetime = 1.3
	blobs.explosiveness = 0.35
	blobs.direction = Vector3.UP
	blobs.spread = 22.0
	blobs.initial_velocity_min = 9.0
	blobs.initial_velocity_max = 15.0
	blobs.gravity = Vector3(0, -22.0, 0)
	blobs.scale_amount_min = 0.5
	blobs.scale_amount_max = 1.4
	blobs.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	blobs.emission_sphere_radius = 0.4
	root.add_child(blobs)
	var splash := blobs.duplicate() as CPUParticles3D
	splash.amount = 30
	splash.lifetime = 0.6
	splash.spread = 80.0
	splash.initial_velocity_min = 3.0
	splash.initial_velocity_max = 6.0
	splash.scale_amount_max = 0.8
	root.add_child(splash)
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke_mat.albedo_color = Color(0.25, 0.22, 0.2, 0.6)
	# Weiche, runde Rauchwolke statt eines Quadrats.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var soft := GradientTexture2D.new()
	soft.gradient = gradient
	soft.fill = GradientTexture2D.FILL_RADIAL
	soft.fill_from = Vector2(0.5, 0.5)
	soft.fill_to = Vector2(0.5, 0.0)
	smoke_mat.albedo_texture = soft
	var puff := QuadMesh.new()
	puff.size = Vector2(1.2, 1.2)
	puff.material = smoke_mat
	var smoke := CPUParticles3D.new()
	smoke.mesh = puff
	smoke.amount = 14
	smoke.lifetime = 1.5
	smoke.position.y = 5.5
	smoke.direction = Vector3.UP
	smoke.spread = 30.0
	smoke.initial_velocity_min = 1.5
	smoke.initial_velocity_max = 3.0
	smoke.gravity = Vector3.ZERO
	smoke.scale_amount_min = 0.8
	smoke.scale_amount_max = 1.8
	root.add_child(smoke)
	return root


# --- Piratenschiff: Seegang --------------------------------------------------------

func _update_wave(e: Dictionary, _delta: float) -> void:
	if e.phase == "warn":
		e.warn.modulate.a = 1.0 if int(e.time * 6.0) % 2 == 0 else 0.35
		if e.time >= WARN_TIME:
			e.warn.queue_free()
			e.phase = "push"
			e.time = 0.0
			hud_label.text = ""
			Audio.sfx("waves")
		return
	var strength := sin(clampf(e.time / WAVE_TIME, 0.0, 1.0) * PI)
	for p in players:
		p.wind_speed = e.dir * WAVE_SPEED * strength
	_rock_ship(e.dir * strength)
	if e.time >= WAVE_TIME:
		for p in players:
			p.wind_speed = 0.0
		_rock_ship(0.0)
		events.erase(e)


# --- Tempel: Gong und Schockwelle ----------------------------------------------------

func _update_gong(e: Dictionary, delta: float) -> void:
	var gong: Node3D = _map_node("Gong")
	if e.phase == "warn":
		e.warn.modulate.a = 1.0 if int(e.time * 6.0) % 2 == 0 else 0.35
		if gong:
			gong.rotation_degrees.x = sin(e.time * 3.0) * 6.0 * e.time
		if e.time >= WARN_TIME:
			e.warn.queue_free()
			e.phase = "wave"
			e.time = 0.0
			e.wave = _gong_wave()
			hud_label.text = ""
			Audio.sfx("gong")
			Audio.sfx("explosion", 0.6, -6.0)
		return
	if gong:
		gong.rotation_degrees.x = sin(e.time * 18.0) * 10.0 * maxf(1.0 - e.time, 0.0)
	var reach: float = e.time * GONG_WAVE_SPEED
	var wave: Node3D = e.wave
	for i in wave.get_child_count():
		var half: Node3D = wave.get_child(i)
		var x := reach * (1.0 if i == 0 else -1.0)
		half.position = Vector3(x, _ground_y(x), 0)
		half.scale = Vector3.ONE * maxf(1.0 - e.time * 0.25, 0.3)
	for p in players:
		if not p.visible or p in e.hit:
			continue
		var dx: float = absf(p.position.x) - reach
		var ground := _ground_y(p.position.x)
		if absf(dx) < 0.5 and p.position.y < ground + 0.7 and p.position.y > ground - 1.0:
			e.hit.append(p)
			var dir := Vector3(GONG_ATTACK.angle.x * signf(p.position.x + 0.01), GONG_ATTACK.angle.y, 0).normalized()
			p.take_hit(GONG_ATTACK, dir)
	if reach > STAGE_HALF_WIDTH + 2.0:
		wave.queue_free()
		events.erase(e)


## Zwei goldene Wellen, die vom Mittelpunkt nach links und rechts laufen.
func _gong_wave() -> Node3D:
	var root := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.8, 0.3, 0.75)
	for side in [1, -1]:
		var half := Node3D.new()
		var ring := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.15
		mesh.bottom_radius = 0.5
		mesh.height = 0.9
		ring.mesh = mesh
		ring.material_override = mat
		ring.position.y = 0.45
		ring.scale = Vector3(0.6, 1, 4.0)
		half.add_child(ring)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.8, 0.3)
		light.light_energy = 2.0
		light.omni_range = 3.0
		light.position.y = 0.6
		half.add_child(light)
		root.add_child(half)
	add_child(root)
	return root


# --- Neonstadt: Polizeidrohne mit Laser ----------------------------------------------

func _update_drone(e: Dictionary, delta: float) -> void:
	var drone: Node3D = e.drone
	var target: CharacterBody3D = e.target
	match e.phase:
		"aim":
			# Der Laserpunkt folgt dem Ziel, die Drohne schwebt darüber.
			if is_instance_valid(target) and target.visible:
				e.x = lerpf(e.x, target.position.x, minf(delta * 4.0, 1.0))
				if target.is_on_floor():
					e.floor = target.position.y
			drone.position = drone.position.lerp(Vector3(e.x, e.floor + 6.5, 0.4), minf(delta * 3.0, 1.0))
			e.marker.position = Vector3(e.x, e.floor + 0.05, 0)
			e.marker.scale = Vector3.ONE * (0.9 + 0.2 * sin(e.time * 20.0))
			if e.time >= DRONE_AIM_TIME:
				e.phase = "lock"
				e.time = 0.0
				Audio.sfx("special_start", 1.4, -4.0)
		"lock":
			e.marker.visible = int(e.time * 20.0) % 2 == 0
			e.marker.scale = Vector3.ONE * 2.2
			if e.time >= 0.4:
				e.phase = "fire"
				e.time = 0.0
				e.marker.visible = true
				e.beam = _drone_beam(drone.position, Vector3(e.x, e.floor, 0))
				hud_label.text = ""
				Audio.sfx("laser", 0.8)
		"fire":
			for p in players:
				if not p.visible or p in e.hit:
					continue
				var dx: float = p.position.x - e.x
				if absf(dx) < 0.9 and p.position.y > e.floor - 0.5 and p.position.y < drone.position.y:
					e.hit.append(p)
					var dir := Vector3(DRONE_ATTACK.angle.x * signf(dx + 0.01), DRONE_ATTACK.angle.y, 0).normalized()
					p.take_hit(DRONE_ATTACK, dir)
			e.beam.scale.x = 1.0 + 0.3 * sin(e.time * 60.0)
			if e.time >= 0.35:
				e.beam.queue_free()
				e.marker.queue_free()
				e.phase = "leave"
				e.time = 0.0
		"leave":
			drone.position.y += 12.0 * delta
			if e.time >= 1.0:
				drone.queue_free()
				events.erase(e)
	# Rotoren drehen sich.
	for rotor in drone.get_children():
		if rotor.name.begins_with("Rotor"):
			rotor.rotation.y += delta * 40.0


func _drone() -> Node3D:
	var root := Node3D.new()
	var body_mat := MapLook.mat(Color(0.15, 0.16, 0.2), 0.4, 0.7)
	MapLook.sphere(root, 0.35, Vector3.ZERO, body_mat, Vector3(1.3, 0.6, 1.0))
	MapLook.sphere(root, 0.1, Vector3(0, -0.15, 0.25), MapLook.mat(Color(1, 0.1, 0.1), 0.5, 0.0, 5.0))
	for x in [-0.6, 0.6]:
		MapLook.box(root, Vector3(0.5, 0.06, 0.08), Vector3(x * 0.6, 0.05, 0), body_mat)
		var rotor := MapLook.box(root, Vector3(0.6, 0.02, 0.08), Vector3(x, 0.15, 0), MapLook.mat(Color(0.6, 0.6, 0.65, 0.7)))
		rotor.name = "Rotor%d" % (1 if x < 0 else 2)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.2, 0.2)
	light.light_energy = 1.5
	light.omni_range = 3.0
	root.add_child(light)
	add_child(root)
	return root


func _drone_beam(from: Vector3, to: Vector3) -> MeshInstance3D:
	var beam := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.35
	mesh.height = maxf(from.y - to.y, 0.5)
	beam.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.25, 0.3, 0.85)
	beam.material_override = mat
	beam.position = Vector3(to.x, (from.y + to.y) * 0.5, 0.4)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.2, 0.25)
	light.light_energy = 4.0
	light.omni_range = 5.0
	beam.add_child(light)
	add_child(beam)
	return beam


# --- Dschungel: rollender Felsbrocken --------------------------------------------------

func _update_boulder(e: Dictionary, delta: float) -> void:
	if e.phase == "warn":
		e.warn.modulate.a = 1.0 if int(e.time * 6.0) % 2 == 0 else 0.35
		if e.time >= WARN_TIME:
			e.warn.queue_free()
			e.phase = "roll"
			e.time = 0.0
			e.rock = _boulder()
			e.rock.position = Vector3(e.side * (STAGE_HALF_WIDTH + 4.0), _ground_y(e.side * STAGE_HALF_WIDTH) + BOULDER_RADIUS, 0)
			hud_label.text = ""
			Audio.sfx("boulder")
		return
	var rock: Node3D = e.rock
	var dir: float = -e.side
	rock.position.x += dir * BOULDER_SPEED * delta
	rock.position.y = lerpf(rock.position.y, _ground_y(rock.position.x) + BOULDER_RADIUS, minf(delta * 12.0, 1.0))
	rock.rotation.z -= dir * BOULDER_SPEED / BOULDER_RADIUS * delta
	for p in players:
		if not p.visible or p in e.hit:
			continue
		var dx: float = p.position.x - rock.position.x
		var dy: float = p.position.y - (rock.position.y - BOULDER_RADIUS)
		if absf(dx) < BOULDER_RADIUS + 0.4 and dy < BOULDER_RADIUS * 2.0 - 0.2 and dy > -1.0:
			e.hit.append(p)
			p.take_hit(BOULDER_ATTACK, Vector3(BOULDER_ATTACK.angle.x * dir, BOULDER_ATTACK.angle.y, 0).normalized())
			Audio.sfx("hit_strong", 0.7)
	if absf(rock.position.x) > STAGE_HALF_WIDTH + 6.0 and signf(rock.position.x) == dir:
		rock.queue_free()
		events.erase(e)


func _boulder() -> Node3D:
	var root := Node3D.new()
	var stone_tex := MapFX.tex("moosstein")
	var stone: Material = MapFX.textured(stone_tex, MapFX.tex("moosstein_n"), Color(0.85, 0.85, 0.8), 0.6) if stone_tex \
		else MapLook.mat(Color(0.45, 0.45, 0.4))
	var rock := MapLook.sphere(root, BOULDER_RADIUS, Vector3.ZERO, stone, Vector3(1.0, 0.95, 0.9))
	rock.mesh.radial_segments = 10
	rock.mesh.rings = 6
	MapLook.box(root, Vector3(0.5, 0.3, 0.3), Vector3(0.7, 0.5, 0.6), MapLook.mat(Color(0.3, 0.5, 0.2)), Vector3(0, 0, 30))
	MapLook.particles(root, Vector3(0, -BOULDER_RADIUS, 0), Vector3(0.5, 0.1, 0.8), Color(0.6, 0.5, 0.35, 0.7), 30,
		Vector3(0, 2.0, 0), 0.15, 0.8, Vector3(0, -4.0, 0))
	add_child(root)
	return root


# --- Wüste: Treibsand ----------------------------------------------------------------

func _update_sand(e: Dictionary, delta: float) -> void:
	if e.phase == "warn":
		e.marker.scale = Vector3.ONE * (0.8 + 0.3 * (0.5 + 0.5 * sin(e.time * 14.0)))
		if e.time >= WARN_TIME:
			e.marker.queue_free()
			e.phase = "active"
			e.time = 0.0
			e.sand = _sand_pit(e.x)
			e.sand.position.y = e.ground + 0.03
			hud_label.text = ""
			Audio.sfx("sand")
		return
	var pit: Node3D = e.sand
	pit.get_child(0).rotation.y += delta * 1.5
	for p in players:
		var inside: bool = p.visible and absf(p.position.x - e.x) < SAND_RADIUS and p.position.y < e.ground + 0.6 \
			and p.position.y > e.ground - 1.0
		var normal: Array = base_values.get(p, [p.speed, p.jump_velocity])
		p.speed = normal[0] * (SAND_SPEED if inside else 1.0)
		p.jump_velocity = normal[1] * (SAND_JUMP if inside else 1.0)
	if e.time >= SAND_TIME:
		_free_from_sand()
		pit.queue_free()
		events.erase(e)


## Alle Kämpfer bekommen wieder ihre normale Lauf- und Sprungkraft.
func _free_from_sand() -> void:
	for p in base_values:
		if is_instance_valid(p):
			p.speed = base_values[p][0]
			p.jump_velocity = base_values[p][1]


func _sand_pit(x: float) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(x, 0.03, 0)
	var swirl := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = SAND_RADIUS
	disc.bottom_radius = SAND_RADIUS
	disc.height = 0.04
	disc.radial_segments = 24
	swirl.mesh = disc
	var sand_tex := MapFX.tex("sand")
	var mat := MapLook.mat(Color(0.7, 0.52, 0.3))
	if sand_tex:
		mat.albedo_texture = sand_tex
		mat.albedo_color = Color(0.75, 0.6, 0.4)
	swirl.material_override = mat
	root.add_child(swirl)
	MapLook.particles(root, Vector3(0, 0.1, 0), Vector3(SAND_RADIUS * 0.7, 0.05, 0.8), Color(0.9, 0.75, 0.5, 0.8), 40,
		Vector3(0, 1.2, 0), 0.07, 1.0, Vector3(0, -2.0, 0))
	add_child(root)
	return root


# --- Unterwasser: Blasen-Geysire ---------------------------------------------------------

func _update_bubbles(e: Dictionary, _delta: float) -> void:
	if e.phase == "warn":
		e.marker.scale = Vector3.ONE * (0.8 + 0.3 * (0.5 + 0.5 * sin(e.time * 14.0)))
		if e.time >= WARN_TIME:
			e.marker.queue_free()
			e.phase = "active"
			e.time = 0.0
			e.column = _bubble_column(e.x)
			e.column.position.y = e.ground + 0.2
			Audio.sfx("bubbles")
		return
	for p in players:
		if p.visible and absf(p.position.x - e.x) < BUBBLE_RADIUS and p.position.y < e.ground + 7.0 and p.position.y > e.ground - 1.0:
			p.velocity.y = maxf(p.velocity.y, BUBBLE_LIFT)
	if e.time >= BUBBLE_TIME:
		var column: CPUParticles3D = e.column
		column.emitting = false
		get_tree().create_timer(2.0).timeout.connect(column.queue_free)
		events.erase(e)


func _bubble_column(x: float) -> CPUParticles3D:
	var parts := MapLook.particles(self, Vector3(x, 0.2, 0), Vector3(BUBBLE_RADIUS * 0.6, 0.1, 0.5),
		Color(0.8, 0.95, 1.0, 0.75), 120, Vector3(0, 12.0, 0), 0.18, 0.7)
	parts.preprocess = 0.0
	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.9, 1.0)
	light.light_energy = 2.0
	light.omni_range = 4.0
	light.position.y = 1.5
	parts.add_child(light)
	return parts


## Höhe des festen Bodens an der Stelle x (Stufen, Terrassen, Gruben). Kämpfer und Plattformen zählen nicht.
func _ground_y(x: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 8.0, 0), Vector3(x, -6.0, 0), 1)
	var skip: Array[RID] = []
	for p in players:
		skip.append(p.get_rid())
	query.exclude = skip
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position.y if hit else 0.0


## Knoten der Map (z. B. den Gong) finden.
func _map_node(node_name: String) -> Node3D:
	var map: Node = get_parent().get_child(0) if get_parent() else null
	return map.find_child(node_name, true, false) if map else null


## Kippt das Schiff der Map ein wenig (nur das Aussehen, der Boden bleibt gerade).
func _rock_ship(amount: float) -> void:
	var map: Node = get_parent().get_child(0) if get_parent() else null
	var ship: Node3D = map.find_child("Schiff", true, false) if map else null
	if ship:
		ship.rotation_degrees.z = -amount * 3.0


func _warning_label(text: String, color: Color, pos: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.font_size = 140
	label.outline_size = 24
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = pos
	add_child(label)
	return label
