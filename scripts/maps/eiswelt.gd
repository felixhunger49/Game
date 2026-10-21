extends Node3D
## Eiswelt: zwei Eisschollen mit einer Spalte in der Mitte (wer hineinfällt, ist raus),
## eine schwebende Scholle über der Spalte und zwei hohe Eisvorsprünge. Es schneit und glitzert.

const GAP := 1.3


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
	$Spawn1.position = Vector3(-4.0, 0.2, 0)
	$Spawn2.position = Vector3(4.0, 0.2, 0)

	# Zwei Schollen von x = ±1,3 bis ±8.
	var floe_width := 8.0 - GAP
	for side in [-1, 1]:
		var cx: float = side * (GAP + floe_width / 2.0)
		MapLook.solid(col, Vector3(floe_width, 2.2, 4), Vector3(cx, -1.1, 0))
		MapLook.box(look, Vector3(floe_width + 0.3, 2.4, 4.2), Vector3(cx, -1.2, 0), ice)
		MapLook.box(look, Vector3(floe_width - 0.4, 1.6, 3.8), Vector3(cx + side * 0.2, -3.0, 0), ice_dark)
		MapLook.box(look, Vector3(floe_width + 0.4, 0.28, 4.5), Vector3(cx, -0.13, 0), snow)
		for i in 6:
			var x: float = cx - floe_width / 2.0 + 0.6 + i * 1.1
			var length := 0.8 + (i * 7 % 5) * 0.25
			MapLook.cylinder(look, 0.02, length, Vector3(x, -2.4 - length / 2.0, 1.95), ice, 0.22, Vector3.ZERO, 6)

	# Plattformen: schwebende Scholle über der Spalte und zwei hohe Eisvorsprünge.
	for p in [[0.0, 2.0, 2.8], [-5.6, 4.2, 2.4], [5.6, 4.2, 2.4]]:
		var pos := Vector3(p[0], p[1], 0)
		var width: float = p[2]
		MapLook.platform(col, Vector3(width, 0.3, 2.4), pos)
		MapLook.box(plat, Vector3(width + 0.1, 0.45, 2.5), pos + Vector3(0, -0.07, 0), ice)
		MapLook.box(plat, Vector3(width + 0.2, 0.12, 2.6), pos + Vector3(0, 0.11, 0), snow)
		for k in int(width / 0.8):
			MapLook.cylinder(plat, 0.02, 0.7, pos + Vector3(-width / 2.0 + 0.4 + k * 0.8, -0.6, 0.8), ice, 0.15, Vector3.ZERO, 6)

	# Schneefeld und Eiskristalle (Berge und Polarlicht sind im Hintergrundbild gemalt).
	MapLook.box(bg, Vector3(260, 0.5, 110), Vector3(0, -8.5, 0), snow)
	for c in [[-10.5, -6.0, 5.0, 10.0], [-12.0, -10.0, 8.0, -8.0], [10.0, -7.0, 6.0, -12.0], [12.5, -12.0, 9.0, 6.0], [-6.0, -14.0, 4.0, 4.0]]:
		MapLook.cylinder(bg, 0.9, c[2], Vector3(c[0], -6.0 + c[2] / 2.0, c[1]), crystal, 0.0, Vector3(0, 0, c[3]), 6)
		MapLook.light(bg, Vector3(c[0], -5.0 + c[2] * 0.5, c[1] + 1.5), Color(0.4, 0.85, 1.0), 0.8, 5.0)

	# Leuchtende Eiskristall-Haufen an den Rändern der Schollen.
	_crystal_cluster(look, Vector3(-7.0, 0.0, -1.5), 1.0, crystal, snow)
	_crystal_cluster(look, Vector3(7.1, 0.0, -1.4), 0.75, crystal, snow)

	# Kaltes Licht, Schneefall, glitzernde Eiskristalle in der Luft.
	MapLook.light(look, Vector3(0, 4.0, 5.0), Color(0.6, 0.85, 1.0), 1.0, 14.0)
	MapLook.particles(self, Vector3(0, 13.0, 0), Vector3(24, 1, 8), Color(1, 1, 1, 0.9), 160,
		Vector3(0.3, -1.6, 0), 0.1, 12.0)
	MapLook.particles(self, Vector3(0, 3.0, 0), Vector3(10, 3, 2), Color(0.7, 0.95, 1.0, 1.0), 30,
		Vector3(0, 0.15, 0), 0.05, 3.0)
	fx.flicker_all(bg, 0.15)
	MapFX.mood(self, Color(0.65, 0.8, 1.0), 0.008, 0.35, 1.1, 1.1, 0.95)

	# Vordergrund: Eiszapfen hängen in die oberen Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		for k in 4:
			var length := 0.35 + (k % 2) * 0.25
			MapLook.cylinder(fg, 0.0, length, Vector3(side * (2.15 - k * 0.2), 1.25 - length / 2.0, -3.0), ice, 0.07, Vector3.ZERO, 6)
	MapLook.backdrop(bg, "res://assets/maps/eiswelt/hintergrund.png")


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
