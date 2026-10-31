class_name SpecialFX
## Effekte, die Spezialattacken spektakulär machen: Lichtblitze, Funken, Schockwellen,
## Kamerawackeln, kurze Zeitlupe und ein großer Schriftzug.

## Höhe des Kampfroboter-Bauchs über den Füßen (dort kommt der Laser heraus).
const LASER_HEIGHT := 1.0

const NAMES := {"feuerball": "FEUERBALL!", "sturm": "STURMANGRIFF!", "wirbel": "WIRBELSTURM!",
	"aufwaerts": "HIMMELSHIEB!", "justice": "JUSTICE!", "lichtschild": "LICHTSCHILD!", "erdbeben": "ERDBEBEN!", "frost": "FROSTZAUBER!", "schwein": "SCHWEINEZAUBER!",
	"pfeilregen": "PFEILREGEN!", "hundert_faeuste": "HUNDERT FÄUSTE!",
	"breitseite": "BREITSEITE!", "laser": "LASERKANONE!"}


## Beim Auslösen: Schriftzug, Aura-Ring, Lichtblitz und eine kurze Zeitlupe.
static func special_start(player: Node3D, kind: String) -> void:
	var world := player.get_parent()
	var color: Color = player.get("color")
	var center: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	_banner(world, NAMES.get(kind, "SPEZIAL!"), color, player.global_position + Vector3(0, 3.0, 0))
	_ring(world, player.global_position + Vector3(0, 0.1, 0), color, 0.3, 3.2, 0.45)
	_flash_light(world, center, color, 8.0, 6.0, 0.4)
	_sparks(world, center, color, 50, 7.0, 0.6)
	slow_motion(player, 0.35, 0.14)
	shake(player, 0.12, 0.25)


## Großer Treffer: Explosion aus Licht, Funken und Schockwelle, dazu Treffer-Stopp und Wackeln.
static func impact(source: Node3D, pos: Vector3, color: Color) -> void:
	var world := source.get_parent()
	_flash_sphere(world, pos, color, 0.3, 2.2, 0.3)
	_flash_sphere(world, pos, Color(1, 1, 1), 0.2, 1.2, 0.15)
	_ring(world, pos, color, 0.4, 3.5, 0.35, true)
	_sparks(world, pos, color, 90, 12.0, 0.7)
	_sparks(world, pos, Color(1, 0.95, 0.7), 40, 8.0, 0.4)
	_flash_light(world, pos, color, 14.0, 9.0, 0.35)
	Audio.sfx("special_hit")
	hit_stop(source, 0.09)
	shake(source, 0.35, 0.4)


## Wirbelsturm: zwei rotierende Klingenringe und ein Tornado aus Funken um die Figur.
static func whirl(player: Node3D) -> void:
	var color: Color = player.get("color")
	for i in 2:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.5 + i * 0.5
		torus.outer_radius = 1.7 + i * 0.5
		ring.mesh = torus
		ring.material_override = _glow_material(Color(color, 0.8), 3.0)
		ring.position = Vector3(0, 0.6 + i * 0.7, 0)
		ring.rotation.x = 0.25 if i == 0 else -0.25
		player.add_child(ring)
		var tween := ring.create_tween().set_parallel()
		tween.tween_property(ring, "rotation:y", TAU * 3.0 * (1 if i == 0 else -1), 0.6)
		tween.tween_property(ring, "scale", Vector3.ONE * 1.3, 0.6)
		tween.tween_property(ring.material_override, "albedo_color:a", 0.0, 0.6)
		tween.chain().tween_callback(ring.queue_free)
	var tornado := _particles(Color(color, 0.9), 120, 0.7, 0.12)
	tornado.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	tornado.emission_ring_axis = Vector3.UP
	tornado.emission_ring_radius = 1.6
	tornado.emission_ring_inner_radius = 1.2
	tornado.emission_ring_height = 0.3
	tornado.direction = Vector3.UP
	tornado.spread = 10.0
	tornado.initial_velocity_min = 4.0
	tornado.initial_velocity_max = 8.0
	tornado.orbit_velocity_min = 1.5
	tornado.orbit_velocity_max = 2.5
	tornado.gravity = Vector3.ZERO
	tornado.one_shot = false
	tornado.position.y = 0.2
	player.add_child(tornado)
	tornado.emitting = true
	player.get_tree().create_timer(0.55).timeout.connect(func():
		if is_instance_valid(tornado):
			tornado.emitting = false)
	player.get_tree().create_timer(1.4).timeout.connect(tornado.queue_free)


## Himmelshieb: eine Lichtsäule schießt aus dem Boden, Funken fliegen nach oben.
static func pillar(player: Node3D) -> void:
	var world := player.get_parent()
	var color: Color = player.get("color")
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.9
	cyl.bottom_radius = 0.6
	cyl.height = 9.0
	beam.mesh = cyl
	beam.material_override = _glow_material(Color(color, 0.5), 2.2)
	world.add_child(beam)
	beam.global_position = player.global_position + Vector3(0, 4.5, 0)
	beam.scale = Vector3(0.2, 1, 0.2)
	var tween := beam.create_tween()
	tween.tween_property(beam, "scale", Vector3(1.2, 1, 1.2), 0.08)
	tween.tween_property(beam.material_override, "albedo_color:a", 0.0, 0.45)
	tween.tween_callback(beam.queue_free)
	var up := _particles(Color(color, 1.0), 80, 0.8, 0.1)
	up.direction = Vector3.UP
	up.spread = 15.0
	up.initial_velocity_min = 10.0
	up.initial_velocity_max = 18.0
	up.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	up.emission_sphere_radius = 0.6
	world.add_child(up)
	up.global_position = player.global_position + Vector3(0, 0.3, 0)
	up.emitting = true
	player.get_tree().create_timer(1.2).timeout.connect(up.queue_free)
	_ring(world, player.global_position + Vector3(0, 0.1, 0), color, 0.3, 2.5, 0.35)


## Sturmangriff: leuchtende Geschwindigkeits-Spur hinter der Figur.
static func dash_trail(player: Node3D, seconds: float) -> void:
	var trail := _particles(Color(player.get("color"), 0.85), 70, 0.35, 0.2)
	trail.local_coords = false
	trail.one_shot = false
	trail.explosiveness = 0.0
	trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	trail.emission_box_extents = Vector3(0.2, 0.8, 0.2)
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 0.5
	trail.gravity = Vector3.ZERO
	trail.scale_amount_min = 1.5
	trail.scale_amount_max = 2.5
	trail.position.y = 0.9
	player.add_child(trail)
	trail.emitting = true
	player.get_tree().create_timer(seconds).timeout.connect(func():
		if is_instance_valid(trail):
			trail.emitting = false)
	player.get_tree().create_timer(seconds + 0.6).timeout.connect(trail.queue_free)


## Feuer-Spur für den Feuerball (hängt am Feuerball und bleibt als Glut in der Luft).
static func fire_trail(ball: Node3D, color: Color) -> CPUParticles3D:
	var trail := _particles(Color(color, 0.9), 60, 0.4, 0.16)
	trail.local_coords = false
	trail.one_shot = false
	trail.explosiveness = 0.0
	trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 0.3
	trail.initial_velocity_min = 0.5
	trail.initial_velocity_max = 1.5
	trail.gravity = Vector3(0, 1.5, 0)
	ball.add_child(trail)
	trail.emitting = true
	return trail


## Erdbeben: Staubwelle und Schockringe laufen über den Boden zu beiden Seiten.
static func quake(player: Node3D) -> void:
	var world := player.get_parent()
	var color: Color = player.get("color")
	var feet: Vector3 = player.global_position + Vector3(0, 0.05, 0)
	_ring(world, feet, color, 0.5, 5.0, 0.5)
	_ring(world, feet, Color(0.85, 0.7, 0.5), 0.3, 4.0, 0.7)
	for side in [-1, 1]:
		var dust := _particles(Color(0.8, 0.65, 0.45, 0.9), 50, 0.7, 0.3)
		dust.direction = Vector3(side, 1.2, 0)
		dust.spread = 25.0
		dust.initial_velocity_min = 4.0
		dust.initial_velocity_max = 10.0
		dust.gravity = Vector3(0, -12, 0)
		dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		dust.emission_box_extents = Vector3(2.0, 0.1, 0.5)
		world.add_child(dust)
		dust.global_position = feet + Vector3(side * 2.0, 0, 0)
		dust.emitting = true
		world.get_tree().create_timer(1.0).timeout.connect(dust.queue_free)
	_flash_light(world, feet + Vector3(0, 0.5, 0), color, 10.0, 7.0, 0.4)
	Audio.sfx("explosion", 0.7)
	shake(player, 0.5, 0.5)


## Kampfroboter: rote Kugel im Bauch, die anschwillt, während der Laser auflädt.
static func laser_charge(player: Node3D, seconds: float) -> void:
	var red := Color(1, 0.15, 0.1)
	var core := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	core.mesh = s
	core.material_override = _glow_material(Color(red, 0.95), 4.0)
	player.add_child(core)
	core.position = Vector3(0.35 * player.get("facing"), LASER_HEIGHT * player.get("size_scale"), 0)
	core.scale = Vector3.ONE * 0.05
	var tween := core.create_tween()
	tween.tween_property(core, "scale", Vector3.ONE * 0.32, seconds).set_ease(Tween.EASE_IN)
	tween.tween_callback(core.queue_free)
	_flash_light(player.get_parent(), player.global_position + Vector3(0, LASER_HEIGHT * player.get("size_scale"), 0.5), red, 4.0, 3.0, seconds)
	Audio.sfx("laser", 0.7)


## Kampfroboter: dicker roter Laserstrahl aus dem Bauch, mit weißem Kern, Funken am Ende und Lichtblitz.
static func laser(player: Node3D, length: float) -> void:
	var world := player.get_parent()
	var facing: int = player.get("facing")
	var red := Color(1, 0.15, 0.1)
	var start: Vector3 = player.global_position + Vector3(0.35 * facing, LASER_HEIGHT * player.get("size_scale"), 0)
	var middle := start + Vector3(facing * length / 2.0, 0, 0)
	for layer in [[0.32, red, 2.4], [0.12, Color(1, 0.55, 0.45), 2.2]]:
		var beam := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = layer[0]
		c.bottom_radius = layer[0]
		c.height = length
		beam.mesh = c
		beam.material_override = _glow_material(Color(layer[1], 0.95), layer[2])
		world.add_child(beam)
		beam.global_position = middle
		beam.rotation.z = PI / 2.0
		var tween := beam.create_tween().set_parallel()
		tween.tween_property(beam, "scale", Vector3(0.05, 1.0, 0.05), 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(beam.material_override, "albedo_color:a", 0.0, 0.45)
		tween.chain().tween_callback(beam.queue_free)
	_flash_sphere(world, start, red, 0.2, 0.9, 0.25)
	_sparks(world, start + Vector3(facing * length, 0, 0), red, 40, 8.0, 0.5)
	_flash_light(world, middle, red, 6.0, length, 0.4)
	Audio.sfx("laser", 0.55, 4.0)
	shake(player, 0.3, 0.35)


## Final Smash, Aufladen: Lichtkugel wächst um die Figur, Funken werden angesaugt, alles bebt leicht.
static func final_charge(player: Node3D, seconds: float) -> void:
	var world := player.get_parent()
	var color: Color = player.get("color")
	var pos := player.global_position + Vector3(0, 1.0 * player.get("size_scale"), 0)
	_flash_sphere(world, pos, color.lightened(0.4), 0.2, 1.6, seconds)
	_ring(world, pos, color, 3.0, 0.3, seconds, true)
	_ring(world, pos, Color(1, 1, 1), 4.0, 0.5, seconds * 0.8, true)
	_flash_light(world, pos, color, 8.0, 6.0, seconds)
	popup(player, "FINAL SMASH!", color)
	shake(player, 0.15, seconds)
	Audio.sfx("special_start", 0.7)


## Final Smash, der Strahl: riesig, in der Farbe der Figur, quer über die ganze Arena.
static func final_beam(player: Node3D, length: float) -> void:
	var world := player.get_parent()
	var facing: int = player.get("facing")
	var color: Color = player.get("color")
	var start: Vector3 = player.global_position + Vector3(0.5 * facing, 1.1 * player.get("size_scale"), 0)
	var middle := start + Vector3(facing * length / 2.0, 0, 0)
	for layer in [[1.9, color, 2.6], [1.1, color.lightened(0.5), 2.6], [0.45, Color(1, 1, 1), 3.0]]:
		var beam := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = layer[0]
		c.bottom_radius = layer[0]
		c.height = length
		beam.mesh = c
		beam.material_override = _glow_material(Color(layer[1], 0.9), layer[2])
		world.add_child(beam)
		beam.global_position = middle
		beam.rotation.z = PI / 2.0
		beam.scale = Vector3(0.2, 1.0, 0.2)
		var tween := beam.create_tween()
		tween.tween_property(beam, "scale", Vector3.ONE, 0.12).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.5)
		tween.tween_property(beam, "scale", Vector3(0.02, 1.0, 0.02), 0.35).set_ease(Tween.EASE_IN)
		tween.tween_callback(beam.queue_free)
	_flash_sphere(world, start, Color(1, 1, 1), 0.5, 3.0, 0.4)
	for i in 6:
		_sparks(world, start + Vector3(facing * length * (i + 1) / 7.0, 0, 0), color.lightened(0.3), 25, 9.0, 0.6)
	_flash_light(world, middle, color, 14.0, length, 0.9)
	Audio.sfx("laser", 0.4, 6.0)
	Audio.sfx("special_hit")
	shake(player, 0.9, 0.8)


## Overcharge-Warnung: blaues Knistern um den Kampfroboter, kurz bevor er sich entlädt.
static func overcharge_warn(player: Node3D, seconds: float) -> void:
	var blue := Color(0.3, 0.7, 1.0)
	var crackle := _particles(blue, 40, 0.25, 0.1)
	crackle.one_shot = false
	crackle.explosiveness = 0.0
	crackle.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	crackle.emission_sphere_radius = 0.7
	crackle.direction = Vector3.UP
	crackle.spread = 180.0
	crackle.initial_velocity_min = 1.0
	crackle.initial_velocity_max = 3.0
	crackle.gravity = Vector3.ZERO
	player.add_child(crackle)
	crackle.position = Vector3(0, 1.0, 0)
	crackle.emitting = true
	player.get_tree().create_timer(seconds).timeout.connect(crackle.queue_free)
	_flash_light(player.get_parent(), player.global_position + Vector3(0, 1.0, 0.6), blue, 3.0, 3.0, seconds)
	Audio.sfx("fuse", 1.6, -6.0)


## Overcharge: Stromschlag rundherum mit Blitzring, kleinen Blitzen und Funken.
static func overcharge(player: Node3D, radius: float) -> void:
	var world := player.get_parent()
	var blue := Color(0.3, 0.7, 1.0)
	var center: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	_ring(world, center, blue, 0.3, radius, 0.3, true)
	_ring(world, player.global_position + Vector3(0, 0.1, 0), blue, 0.3, radius, 0.3)
	_flash_sphere(world, center, Color(0.7, 0.9, 1.0), 0.3, 1.2, 0.2)
	_sparks(world, center, blue, 60, 9.0, 0.4)
	for i in 6:
		var a := TAU * i / 6.0 + randf() * 0.5
		var bolt := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(radius * 0.9, 0.05, 0.05)
		bolt.mesh = b
		bolt.material_override = _glow_material(Color(0.8, 0.95, 1.0, 0.95), 4.0)
		world.add_child(bolt)
		bolt.global_position = center + Vector3(cos(a), sin(a), 0) * radius * 0.45
		bolt.rotation.z = a + randf_range(-0.3, 0.3)
		var tween := bolt.create_tween()
		tween.tween_property(bolt.material_override, "albedo_color:a", 0.0, 0.2)
		tween.tween_callback(bolt.queue_free)
	_flash_light(world, center, blue, 9.0, radius * 2.5, 0.3)
	Audio.sfx("laser", 1.5, -2.0)
	shake(player, 0.15, 0.2)


## Goldener Faust-Abdruck für die Hundert Fäuste. big: der letzte, große Schlag.
static func fist(player: Node3D, pos: Vector3, big: bool) -> void:
	var world := player.get_parent()
	var gold := Color(1, 0.8, 0.3)
	_flash_sphere(world, pos, gold, 0.15, 0.9 if big else 0.5, 0.18)
	_ring(world, pos, gold, 0.2, 1.4 if big else 0.8, 0.2, true)
	_sparks(world, pos, gold, 30 if big else 12, 7.0 if big else 4.5, 0.35)
	if big:
		shake(player, 0.25, 0.25)


## Kurzer Schriftzug über einer Figur, z. B. "KRITISCH!".
static func popup(player: Node3D, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 70
	label.outline_size = 18
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	player.get_parent().add_child(label)
	label.global_position = player.global_position + Vector3(0, 2.6, 0)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y + 0.8, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.parallel().tween_property(label, "outline_modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.tween_callback(label.queue_free)


## Bis wann (Echtzeit in ms) die K.-o.-Zeitlupe läuft. Andere Zeitlupen und Treffer-Stopps warten so lange.
static var _ko_until := 0


## Bis wann (Echtzeit in ms) die Zeitlupe läuft (das späteste Ende aller gestarteten Zeitlupen).
static var _slow_until := 0

## Nummer der zuletzt gestarteten Zeitlupe: nur deren Zeitgeber setzt die Zeit zurück.
## (Ein Zeitgeber meldet sich oft ein paar Millisekunden vor dem errechneten Ende, ein Zeitvergleich
## ließ die Zeit deshalb manchmal für immer in Zeitlupe hängen.)
static var _slow_id := 0


## Kurze Zeitlupe für alles (in Echtzeit-Sekunden).
static func slow_motion(node: Node, scale: float, seconds: float) -> void:
	var tree := node.get_tree() if node else null
	if tree == null:
		return
	var now := Time.get_ticks_msec()
	var until := now + int(seconds * 1000.0)
	if now < _ko_until:
		return
	var running := now < _slow_until
	if running and Engine.time_scale <= scale and until <= _slow_until:
		# Ein mindestens so starker, längerer Treffer-Stopp läuft schon.
		return
	if running:
		# Überlappende Zeitlupen: die Zeit bleibt bis zum spätesten Ende langsam.
		until = maxi(until, _slow_until)
	Engine.time_scale = scale
	_slow_until = until
	_slow_id += 1
	var id := _slow_id
	tree.create_timer(maxf(until - now, 1) / 1000.0, true, false, true).timeout.connect(func():
		if id == _slow_id and Time.get_ticks_msec() >= _ko_until:
			_slow_until = 0
			Engine.time_scale = 1.0)


## Zeit sofort wieder normal (z. B. beim Verlassen des Kampfes).
static func reset_time() -> void:
	_slow_id += 1
	_slow_until = 0
	_ko_until = 0
	Engine.time_scale = 1.0


## Der entscheidende Treffer (die Figur fliegt gleich aus der Arena): starke Zeitlupe, Lichtblitz und Knall.
## Die Kamera zoomt dabei heran (siehe Fight._on_ko_hit).
static func ko_moment(player: Node3D, seconds: float) -> void:
	var world := player.get_parent()
	var pos := player.global_position + Vector3(0, 1.0, 0)
	_flash_sphere(world, pos, Color(1, 1, 1), 0.3, 2.6, 0.5)
	_ring(world, pos, Color(1, 0.85, 0.3), 0.5, 4.5, 0.6, true)
	_sparks(world, pos, Color(1, 0.9, 0.5), 70, 10.0, 0.8)
	_flash_light(world, pos, Color(1, 0.95, 0.8), 16.0, 10.0, 0.6)
	Audio.sfx("special_hit", 0.8)
	_ko_until = Time.get_ticks_msec() + int(seconds * 1000.0)
	Engine.time_scale = 0.12
	_slow_id += 1
	player.get_tree().create_timer(seconds, true, false, true).timeout.connect(func():
		_ko_until = 0
		_slow_until = 0
		Engine.time_scale = 1.0)


## Aus der Arena geflogen: bunter Lichtstrahl vom Rand in Richtung Bühne, wie bei Smash Bros.
static func blast(player: Node3D, zone: Rect2) -> void:
	var world := player.get_parent()
	var color: Color = player.get("color")
	var center := Vector3(zone.get_center().x, zone.position.y + zone.size.y * 0.4, 0)
	# Start am Rand der Arena, etwas nach innen, damit man ihn im Bild sieht.
	var start := Vector3(clampf(player.global_position.x, zone.position.x + 2.0, zone.end.x - 2.0),
		clampf(player.global_position.y, zone.position.y + 2.0, zone.end.y - 2.0), 0)
	var dir := (center - start).normalized()
	var length := 16.0
	for layer in 2:
		var beam := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 2.2 if layer == 0 else 1.1
		cone.height = length
		beam.mesh = cone
		beam.material_override = _glow_material(Color(color if layer == 0 else Color(1, 1, 1), 0.9), 3.5)
		world.add_child(beam)
		# Breites Ende am Rand, Spitze zur Bühne.
		var y := dir
		var x := y.cross(Vector3(0, 0, 1)).normalized()
		beam.global_transform = Transform3D(Basis(x, y, x.cross(y)), start + dir * length * 0.5)
		var tween := beam.create_tween().set_parallel()
		tween.tween_property(beam, "scale:x", 0.05, 0.9).set_ease(Tween.EASE_IN)
		tween.tween_property(beam, "scale:z", 0.05, 0.9).set_ease(Tween.EASE_IN)
		tween.tween_property(beam.material_override, "albedo_color:a", 0.0, 0.9)
		tween.chain().tween_callback(beam.queue_free)
	_flash_sphere(world, start, color, 0.5, 4.0, 0.5)
	_sparks(world, start, color, 90, 14.0, 0.9)
	_flash_light(world, start, color, 20.0, 18.0, 0.7)
	shake(player, 0.6, 0.6)


## Perfekt abgewehrt: weißer Blitz um das Schild und Schriftzug.
static func perfect_shield(player: Node3D) -> void:
	var world := player.get_parent()
	var pos := player.global_position + Vector3(0, 0.9, 0)
	_flash_sphere(world, pos, Color(1, 1, 1), 1.0, 1.8, 0.25)
	_ring(world, pos, Color(0.7, 0.95, 1.0), 0.8, 2.6, 0.35, true)
	_sparks(world, pos, Color(0.8, 0.95, 1.0), 30, 7.0, 0.4)
	popup(player, "PERFEKT!", Color(0.75, 0.95, 1.0))
	hit_stop(player, 0.12)


## Schild zerbrochen: Splitter in der Farbe des Spielers, Schriftzug, Wackeln.
static func shield_break(player: Node3D) -> void:
	var world := player.get_parent()
	var color: Color = player.get("color")
	var pos := player.global_position + Vector3(0, 0.9, 0)
	_flash_sphere(world, pos, color, 1.0, 2.4, 0.35)
	_sparks(world, pos, color, 80, 11.0, 0.8)
	_sparks(world, pos, Color(1, 1, 1), 30, 8.0, 0.5)
	popup(player, "SCHILD KAPUTT!", Color(1, 0.4, 0.3))
	hit_stop(player, 0.15)
	shake(player, 0.4, 0.4)


## Treffer-Stopp: das Bild friert für einen Augenblick fast ein, das macht Treffer wuchtig.
static func hit_stop(node: Node, seconds: float) -> void:
	slow_motion(node, 0.05, seconds)


## Kamerawackeln: mehrere Erschütterungen stören sich nicht, die stärkste zählt. Die Stärke ist in Metern
## bei normalem Abstand und wächst mit dem Zoom mit, damit das Wackeln immer gleich kräftig aussieht.
## Die Kamera im Kampf wendet es mit apply_shake an (Fight._update_camera).
static var _shake_strength := 0.0
static var _shake_left := 0.0
static var _shake_length := 1.0
static var _shake_phase := 0.0

static func shake(node: Node, strength: float, seconds: float) -> void:
	var now := _shake_strength * (_shake_left / _shake_length)
	if strength >= now:
		_shake_strength = strength
		_shake_left = seconds
		_shake_length = maxf(seconds, 0.01)


static func apply_shake(cam: Camera3D, real_delta: float) -> void:
	_shake_left = maxf(_shake_left - real_delta, 0.0)
	var amount := _shake_strength * pow(_shake_left / _shake_length, 1.5) * clampf(cam.position.z / 14.0, 0.6, 1.4)
	if amount < 0.002:
		cam.h_offset = 0.0
		cam.v_offset = 0.0
		return
	# Weiches Rütteln aus zwei Sinuswellen statt Zufallssprüngen (wirkt kräftig, aber nicht zappelig).
	_shake_phase += real_delta * 45.0
	cam.h_offset = amount * (sin(_shake_phase * 1.0) * 0.7 + sin(_shake_phase * 2.3 + 1.0) * 0.3)
	cam.v_offset = amount * (sin(_shake_phase * 1.3 + 2.0) * 0.7 + sin(_shake_phase * 2.9) * 0.3)


# --- Bausteine -------------------------------------------------------------------

# --- Treffer, Staub und Flugspur ------------------------------------------------------

## Weicher, runder Lichtpunkt für alle Partikel (statt eckiger Plättchen). Wird nur einmal gebaut.
static var _dot: Texture2D

static func soft_dot() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.75))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 64
		tex.height = 64
		_dot = tex
	return _dot


## Weniger Partikel bei Grafik "Niedrig".
static func amount_for_quality(amount: int) -> int:
	return amount if Settings.graphics > 0 else maxi(amount / 2, 1)


## Normaler Treffer: Funken in der Farbe des Angreifers, ein kurzer weißer Blitz und
## bei starken Treffern ein Ring, Treffer-Stopp und Kamerawackeln.
static func hit(source: Node3D, pos: Vector3, color: Color, strength: float) -> void:
	var world := source.get_parent()
	var heavy := strength >= 10.0
	_flash_sphere(world, pos, Color(1, 1, 1), 0.15, 0.7 if heavy else 0.45, 0.1)
	_sparks(world, pos, color, 24 if heavy else 12, 9.0 if heavy else 6.0, 0.35)
	_sparks(world, pos, Color(1, 0.95, 0.8), 10 if heavy else 5, 7.0, 0.2)
	if heavy:
		_ring(world, pos, color, 0.2, 1.8, 0.2, true)
		hit_stop(source, 0.06)
		shake(source, 0.18, 0.2)
	else:
		hit_stop(source, 0.025)


## Staubwolke am Boden (Landen, Absprung, Ausweichrolle).
static func dust(world: Node, pos: Vector3, amount := 10, spread := 2.5) -> void:
	var p := CPUParticles3D.new()
	p.amount = amount_for_quality(amount)
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 1.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.3, 0.05, 0.2)
	p.direction = Vector3(1, 0.25, 0)
	p.spread = 180.0
	p.flatness = 0.85
	p.initial_velocity_min = spread * 0.5
	p.initial_velocity_max = spread
	p.damping_min = 4.0
	p.damping_max = 6.0
	p.gravity = Vector3(0, 0.6, 0)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.3
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.5))
	grow.add_point(Vector2(1, 1.4))
	p.scale_amount_curve = grow
	var quad := QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = soft_dot()
	mat.albedo_color = Color(0.85, 0.8, 0.72, 0.55)
	mat.disable_receive_shadows = true
	quad.material = mat
	p.mesh = quad
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	world.add_child(p)
	p.global_position = pos + Vector3(0, 0.1, 0)
	p.emitting = true
	world.get_tree().create_timer(0.9).timeout.connect(p.queue_free)


## Rauchspur hinter einer Figur, die nach einem harten Treffer wegfliegt (wie in Smash).
static func launch_trail(player: Node3D, seconds: float) -> void:
	var p := CPUParticles3D.new()
	p.amount = amount_for_quality(40)
	p.lifetime = 0.45
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.25
	p.spread = 180.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.4
	var shrink := Curve.new()
	shrink.add_point(Vector2(0, 1))
	shrink.add_point(Vector2(1, 0.2))
	p.scale_amount_curve = shrink
	var quad := QuadMesh.new()
	quad.size = Vector2(0.55, 0.55)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = soft_dot()
	mat.albedo_color = Color(0.92, 0.92, 0.95, 0.6)
	quad.material = mat
	p.mesh = quad
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	p.position = Vector3(0, 1.0, 0)
	player.add_child(p)
	p.emitting = true
	player.get_tree().create_timer(seconds).timeout.connect(func():
		if is_instance_valid(p):
			p.emitting = false
			p.get_tree().create_timer(0.6).timeout.connect(p.queue_free))


static func _glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(color.r * energy * 0.32, color.g * energy * 0.32, color.b * energy * 0.32, color.a)
	return mat


static func _particles(color: Color, amount: int, lifetime: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount_for_quality(amount)
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 0.95
	var quad := QuadMesh.new()
	# Etwas größer, weil der runde Punkt zum Rand hin weich ausläuft.
	quad.size = Vector2(size, size) * 1.8
	var mat := _glow_material(color, 3.0)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = soft_dot()
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	p.mesh = quad
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	return p


static func _sparks(world: Node, pos: Vector3, color: Color, amount: int, speed: float, lifetime: float) -> void:
	var p := _particles(color, amount, lifetime, 0.14)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9, 0)
	p.damping_min = 2.0
	p.damping_max = 4.0
	world.add_child(p)
	p.global_position = pos
	p.emitting = true
	world.get_tree().create_timer(lifetime + 0.3).timeout.connect(p.queue_free)


static func _flash_sphere(world: Node, pos: Vector3, color: Color, from_r: float, to_r: float, seconds: float) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	m.mesh = s
	m.material_override = _glow_material(Color(color, 0.9), 3.0)
	world.add_child(m)
	m.global_position = pos
	m.scale = Vector3.ONE * from_r
	var tween := m.create_tween().set_parallel()
	tween.tween_property(m, "scale", Vector3.ONE * to_r, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(m.material_override, "albedo_color:a", 0.0, seconds)
	tween.chain().tween_callback(m.queue_free)


static func _ring(world: Node, pos: Vector3, color: Color, from_r: float, to_r: float, seconds: float,
		facing_camera := false) -> void:
	var m := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	m.mesh = torus
	m.material_override = _glow_material(Color(color, 0.9), 3.0)
	world.add_child(m)
	m.global_position = pos
	if facing_camera:
		m.rotation.x = PI / 2.0
	m.scale = Vector3.ONE * from_r
	var tween := m.create_tween().set_parallel()
	tween.tween_property(m, "scale", Vector3.ONE * to_r, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(m.material_override, "albedo_color:a", 0.0, seconds)
	tween.chain().tween_callback(m.queue_free)


static func _flash_light(world: Node, pos: Vector3, color: Color, energy: float, radius: float, seconds: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	world.add_child(light)
	light.global_position = pos
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, seconds)
	tween.tween_callback(light.queue_free)


static func _banner(world: Node, text: String, color: Color, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 110
	label.outline_size = 28
	label.modulate = color.lightened(0.3)
	label.outline_modulate = Color(0.1, 0.05, 0, 0.95)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	world.add_child(label)
	label.global_position = pos
	label.scale = Vector3.ONE * 0.2
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector3.ONE * 1.15, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector3.ONE, 0.08)
	tween.tween_interval(0.5)
	tween.parallel().tween_property(label, "position:y", pos.y + 0.6, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(label, "outline_modulate:a", 0.0, 0.25)
	tween.tween_callback(label.queue_free)
