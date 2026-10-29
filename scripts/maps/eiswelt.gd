extends Node3D
## Eiswelt: zwei große Eisschollen mit einer Spalte in der Mitte. Die Spalte führt hinunter in eine Eishöhle mit
## einem eingefrorenen Mammut (auch über die Kanten erreichbar). Eine schwebende Scholle über der Spalte, zwei hohe
## Eisvorsprünge, eine Eiszapfenbrücke und ganz oben der Eisberg-Gipfel. Außen treibt links eine kleine Scholle,
## rechts steht eine Eissäule. Es schneit und glitzert.

const GAP := 1.3
const HALF := 10.5
const CAVE_Y := -4.8
const CAVE_HALF := 12.5


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var ice_tex := MapFX.tex("eis")
	var snow_tex := MapFX.tex("schnee")
	var ice: Material = MapFX.textured(ice_tex, MapFX.tex("eis_n"), Color(0.85, 0.95, 1.0), 0.35, 0.15, 0.1) if ice_tex \
		else MapLook.mat(Color(0.62, 0.86, 0.97), 0.12, 0.1)
	var snow: Material = MapFX.textured(snow_tex, MapFX.tex("schnee_n"), Color.WHITE, 0.35, 0.8) if snow_tex \
		else MapLook.mat(Color(0.96, 0.98, 1.0), 0.8)
	var ice_dark := MapLook.mat(Color(0.35, 0.6, 0.8), 0.15, 0.1)
	var crystal := MapLook.mat(Color(0.45, 0.9, 1.0, 0.75), 0.05, 0.2, 0.6)
	$Spawn1.position = Vector3(-4.5, 0.2, 0)
	$Spawn2.position = Vector3(4.5, 0.2, 0)
	MapLook.stage_area(self, Rect2(-14.8, CAVE_Y, 29.6, 9.2 - CAVE_Y), HALF)

	# Zwei Schollen von x = ±1,3 bis ±10,5, darunter ist Platz für die Eishöhle.
	var floe_width := HALF - GAP
	for side in [-1, 1]:
		var cx: float = side * (GAP + floe_width / 2.0)
		MapLook.solid(col, Vector3(floe_width, 1.4, 4), Vector3(cx, -0.7, 0))
		MapLook.box(look, Vector3(floe_width + 0.3, 1.5, 4.2), Vector3(cx, -0.75, 0), ice)
		MapLook.box(look, Vector3(floe_width + 0.4, 0.28, 4.5), Vector3(cx, -0.13, 0), snow)
		for i in 8:
			var x: float = cx - floe_width / 2.0 + 0.6 + i * 1.1
			var length := 0.5 + (i * 7 % 5) * 0.15
			MapLook.cylinder(look, 0.02, length, Vector3(x, -1.5 - length / 2.0, 1.95), ice, 0.18, Vector3.ZERO, 6)

	_ice_cave(col, look, plat, ice, ice_dark, snow, crystal)

	# Plattformen: schwebende Scholle über der Spalte und zwei hohe Eisvorsprünge.
	for p in [[0.0, 2.0, 2.8], [-7.0, 4.2, 2.4], [7.0, 4.2, 2.4]]:
		var pos := Vector3(p[0], p[1], 0)
		var width: float = p[2]
		MapLook.platform(col, Vector3(width, 0.3, 2.4), pos)
		MapLook.box(plat, Vector3(width + 0.1, 0.45, 2.5), pos + Vector3(0, -0.07, 0), ice)
		MapLook.box(plat, Vector3(width + 0.2, 0.12, 2.6), pos + Vector3(0, 0.11, 0), snow)
		for k in int(width / 0.8):
			MapLook.cylinder(plat, 0.02, 0.7, pos + Vector3(-width / 2.0 + 0.4 + k * 0.8, -0.6, 0.8), ice, 0.15, Vector3.ZERO, 6)
	# Zwei mittlere Eisvorsprünge zwischen Scholle und Brücke.
	for side in [-1, 1]:
		var pos := Vector3(side * 3.6, 4.4, 0)
		MapLook.platform(col, Vector3(2.0, 0.3, 2.2), pos)
		MapLook.box(plat, Vector3(2.1, 0.4, 2.3), pos + Vector3(0, -0.05, 0), ice)
		MapLook.box(plat, Vector3(2.2, 0.1, 2.4), pos + Vector3(0, 0.12, 0), snow)

	# Eiszapfenbrücke oben und der Eisberg-Gipfel ganz oben.
	var bridge := Vector3(0, 6.8, 0)
	MapLook.platform(col, Vector3(8.0, 0.3, 2.2), bridge)
	MapLook.box(plat, Vector3(8.1, 0.4, 2.3), bridge + Vector3(0, -0.05, 0), ice)
	MapLook.box(plat, Vector3(8.2, 0.1, 2.4), bridge + Vector3(0, 0.12, 0), snow)
	for k in 10:
		var length := 0.5 + (k * 5 % 4) * 0.25
		MapLook.cylinder(plat, 0.02, length, bridge + Vector3(-3.6 + k * 0.8, -0.25 - length / 2.0, 0.9), ice, 0.16, Vector3.ZERO, 6)
	var summit := Vector3(0, 9.2, 0)
	MapLook.platform(col, Vector3(2.6, 0.3, 2.0), summit)
	MapLook.box(plat, Vector3(2.7, 0.4, 2.1), summit + Vector3(0, -0.05, 0), ice)
	MapLook.box(plat, Vector3(2.8, 0.12, 2.2), summit + Vector3(0, 0.12, 0), snow)
	MapLook.cylinder(plat, 1.5, 2.6, Vector3(0, 8.2, -1.6), ice_dark, 0.2, Vector3.ZERO, 6)
	MapLook.cylinder(plat, 0.25, 1.4, summit + Vector3(0.6, 0.85, -1.0), crystal, 0.0, Vector3(0, 0, -10), 6)
	MapLook.light(plat, summit + Vector3(0, 1.0, 0.6), Color(0.5, 0.9, 1.0), 1.0, 5.0)

	# Außen: links treibt eine kleine Scholle hin und her, rechts steht eine Eissäule.
	var drift := MovingPlatform.create(plat, Vector3(2.4, 0.3, 2.0), Vector3(-14.0, -2.0, 0), Vector3(-11.6, -2.0, 0), 8.0)
	MapLook.box(drift, Vector3(2.5, 0.5, 2.1), Vector3(0, -0.1, 0), ice)
	MapLook.box(drift, Vector3(2.6, 0.12, 2.2), Vector3(0, 0.08, 0), snow)
	var pillar := Vector3(13.6, -1.8, 0)
	MapLook.platform(col, Vector3(2.2, 0.3, 2.2), pillar)
	MapLook.box(plat, Vector3(2.3, 0.4, 2.3), pillar + Vector3(0, -0.05, 0), ice)
	MapLook.box(plat, Vector3(2.4, 0.12, 2.4), pillar + Vector3(0, 0.12, 0), snow)
	MapLook.cylinder(plat, 0.5, 6.0, pillar + Vector3(0, -3.2, -0.2), ice_dark, 1.0, Vector3.ZERO, 6)

	# Schneefeld und Eiskristalle (Berge und Polarlicht sind im Hintergrundbild gemalt).
	MapLook.box(bg, Vector3(260, 0.5, 110), Vector3(0, -8.5, 0), snow)
	for c in [[-17.5, -7.0, 5.0, 10.0], [-15.0, -12.0, 8.0, -8.0], [17.0, -8.0, 6.0, -12.0], [15.5, -14.0, 9.0, 6.0], [-7.0, -16.0, 4.0, 4.0]]:
		MapLook.cylinder(bg, 0.9, c[2], Vector3(c[0], -6.0 + c[2] / 2.0, c[1]), crystal, 0.0, Vector3(0, 0, c[3]), 6)
		MapLook.light(bg, Vector3(c[0], -5.0 + c[2] * 0.5, c[1] + 1.5), Color(0.4, 0.85, 1.0), 0.8, 5.0)

	# Leuchtende Eiskristall-Haufen an den Rändern der Schollen: 3D-Modell aus Flux + Trellis,
	# sonst aus Formen gebaut.
	for k in [[Vector3(-9.4, 0.0, -1.5), 1.0, 20.0], [Vector3(9.5, 0.0, -1.4), 0.75, -30.0]]:
		if MapLook.prop(look, "res://assets/maps/props/eiskristall.glb", k[0], 2.0 * k[1], k[2]) == null:
			_crystal_cluster(look, k[0], k[1], crystal, snow)
		MapLook.light(look, k[0] + Vector3(0, 1.0, 0.6), Color(0.45, 0.9, 1.0), 1.0, 4.0)

	# Kaltes Licht, Schneefall, glitzernde Eiskristalle in der Luft.
	MapLook.light(look, Vector3(0, 4.0, 5.0), Color(0.6, 0.85, 1.0), 1.0, 14.0)
	MapLook.particles(self, Vector3(0, 15.0, 0), Vector3(28, 1, 8), Color(1, 1, 1, 0.9), 200,
		Vector3(0.3, -1.6, 0), 0.1, 12.0)
	MapLook.particles(self, Vector3(0, 3.0, 0), Vector3(14, 5, 2), Color(0.7, 0.95, 1.0, 1.0), 40,
		Vector3(0, 0.15, 0), 0.05, 3.0)
	fx.flicker_all(bg, 0.15)
	MapFX.mood(self, Color(0.65, 0.8, 1.0), 0.008, 0.35, 1.1, 1.1, 0.95)

	# Vordergrund: Eiszapfen hängen in die oberen Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		for k in 4:
			var length := 0.35 + (k % 2) * 0.25
			MapLook.cylinder(fg, 0.0, length, Vector3(side * (2.15 - k * 0.2), 1.25 - length / 2.0, -3.0), ice, 0.07, Vector3.ZERO, 6)
	MapLook.backdrop(bg, "res://assets/maps/eiswelt/hintergrund.png", -60.0, 180.0, 10.0)


## Haufen aus sechseckigen Kristallen mit Spitze, die schräg aus einem verschneiten Felsen wachsen.
func _crystal_cluster(parent: Node3D, pos: Vector3, size: float, crystal: Material, snow: Material) -> void:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	MapLook.sphere(root, 0.55 * size, Vector3(0, 0.1, 0), MapLook.mat(Color(0.55, 0.6, 0.68)), Vector3(1.4, 0.6, 1.0))
	MapLook.sphere(root, 0.5 * size, Vector3(0, 0.3, 0), snow, Vector3(1.3, 0.35, 0.9))
	for c in [[0.0, 1.6, 0.0, 0.0], [-0.35, 1.1, 25.0, 10.0], [0.4, 1.2, -28.0, -8.0], [0.15, 0.8, 12.0, 35.0], [-0.2, 0.7, -15.0, -30.0]]:
		var h: float = c[1] * size
		var tilt := Node3D.new()
		tilt.position = Vector3(c[0] * size, 0.2 * size, 0)
		tilt.rotation_degrees = Vector3(c[3], 0, c[2])
		root.add_child(tilt)
		MapLook.cylinder(tilt, 0.16 * size, h, Vector3(0, h / 2.0, 0), crystal, -1.0, Vector3.ZERO, 6)
		MapLook.cylinder(tilt, 0.0, 0.35 * size, Vector3(0, h + 0.17 * size, 0), crystal, 0.16 * size, Vector3(180, 0, 0), 6)
	MapLook.light(root, Vector3(0, 1.0 * size, 0.6), Color(0.45, 0.9, 1.0), 1.2, 4.0)


## Eishöhle unter den Schollen: blaue Eiswände, Eiszapfen an der Decke, leuchtende Kristalle und ein Mammut,
## das in einem Eisblock eingefroren ist. In der Spalte hilft ein Eisvorsprung beim Hochspringen.
func _ice_cave(col: Node3D, look: Node3D, plat: Node3D, ice: Material, dark: Material, snow: Material,
		crystal: Material) -> void:
	MapLook.solid(col, Vector3(CAVE_HALF * 2.0, 1.6, 4), Vector3(0, CAVE_Y - 0.8, 0))
	MapLook.box(look, Vector3(CAVE_HALF * 2.0 + 0.3, 1.7, 4.2), Vector3(0, CAVE_Y - 0.85, 0), ice)
	MapLook.box(look, Vector3(CAVE_HALF * 2.0 + 0.4, 0.2, 4.4), Vector3(0, CAVE_Y - 0.1, 0), snow)
	MapLook.box(look, Vector3(CAVE_HALF * 2.0 - 1.0, 1.6, 3.6), Vector3(0, CAVE_Y - 2.4, 0), dark)
	var h := -1.4 - CAVE_Y
	MapLook.box(look, Vector3(HALF * 2.0, h, 0.4), Vector3(0, CAVE_Y + h / 2.0, -2.0), dark)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 14:
		var x := rng.randf_range(-10.0, 10.0)
		if absf(x) < GAP + 0.3:
			continue
		var len := rng.randf_range(0.3, 0.9)
		MapLook.cylinder(look, 0.0, len, Vector3(x, -1.4 - len / 2.0, rng.randf_range(-1.8, -0.6)), ice, 0.14, Vector3.ZERO, 6)
	for i in 6:
		var x := rng.randf_range(-11.0, 11.0)
		var hgt := rng.randf_range(0.5, 1.2)
		MapLook.cylinder(look, 0.16, hgt, Vector3(x, CAVE_Y + hgt / 2.0, rng.randf_range(-1.7, -1.2)), crystal, 0.0,
			Vector3(0, 0, rng.randf_range(-25, 25)), 6)
		MapLook.light(look, Vector3(x, CAVE_Y + 0.8, -0.8), Color(0.4, 0.85, 1.0), 0.6, 3.0)
	# Eingefrorenes Mammut in einem Eisblock an der Rückwand.
	var m := Vector3(-6.0, CAVE_Y, -1.3)
	var fur := MapLook.mat(Color(0.4, 0.27, 0.18), 1.0)
	var tusk := MapLook.mat(Color(0.95, 0.92, 0.82), 0.5)
	MapLook.sphere(look, 0.9, m + Vector3(0, 1.3, 0), fur, Vector3(1.3, 0.9, 0.8))
	MapLook.sphere(look, 0.55, m + Vector3(1.1, 1.6, 0.1), fur)
	MapLook.cylinder(look, 0.18, 1.0, m + Vector3(1.55, 1.0, 0.2), fur, 0.1, Vector3(0, 0, -15), 8)
	for z in [-0.2, 0.3]:
		MapLook.cylinder(look, 0.06, 1.0, m + Vector3(1.6, 1.2, z), tusk, 0.02, Vector3(0, 0, 55), 6)
	for x in [-0.6, 0.6]:
		MapLook.cylinder(look, 0.2, 0.8, m + Vector3(x, 0.4, 0), fur, -1.0, Vector3.ZERO, 8)
	var block := MapLook.box(look, Vector3(3.6, 2.8, 1.4), m + Vector3(0.3, 1.4, 0), MapLook.mat(Color(0.6, 0.85, 1.0, 0.35), 0.05, 0.1, 0.2))
	block.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MapLook.light(look, m + Vector3(0.3, 1.5, 1.4), Color(0.5, 0.85, 1.0), 1.0, 5.0)
	# Eisvorsprung in der Spalte.
	var shelf := Vector3(0, -2.4, 0)
	MapLook.platform(col, Vector3(GAP * 2.0 - 0.2, 0.3, 2.0), shelf)
	MapLook.box(plat, Vector3(GAP * 2.0 - 0.1, 0.35, 2.0), shelf + Vector3(0, -0.05, 0), ice)
	MapLook.particles(look, Vector3(0, CAVE_Y + 1.5, -0.5), Vector3(10, 1.2, 1.0), Color(0.7, 0.95, 1.0, 0.9), 25,
		Vector3(0, 0.1, 0), 0.05, 3.0)
