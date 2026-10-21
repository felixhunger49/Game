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

var kind := ""
var players: Array = []
var timer := 0.0
## Laufende Ereignisse: jedes ist ein Dictionary mit "phase", "time" und eigenen Werten.
var events: Array = []
var hud_label: Label


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


func stop() -> void:
	for p in players:
		p.wind_speed = 0.0
	_rock_ship(0.0)
	for e in events:
		for key in ["warn", "ball", "marker", "ghost", "particles", "strike"]:
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
			Audio.sfx({"lava": "explosion", "eis": "shield_break", "blitze": "cannon"}[kind])
		return
	var node: Node3D = e.strike
	var atk: Dictionary = {}
	var hit_zone := false
	match kind:
		"lava":
			# Die Fontäne schießt hoch und wird dabei breiter.
			node.scale = Vector3(1.0 + e.time, minf(e.time * 6.0, 1.0), 1.0 + e.time)
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
	var light := OmniLight3D.new()
	light.omni_range = 5.0
	light.light_energy = 3.0
	match kind:
		"lava":
			var column := CylinderMesh.new()
			column.top_radius = 0.9
			column.bottom_radius = 0.6
			column.height = 7.0
			body.mesh = column
			body.position.y = 3.5
			mat.albedo_color = Color(1.0, 0.45, 0.05, 0.85)
			light.light_color = Color(1, 0.45, 0.1)
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
	body.material_override = mat
	root.add_child(body)
	light.position.y = 1.0
	root.add_child(light)
	add_child(root)
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
			Audio.sfx("wind", 0.7)
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
