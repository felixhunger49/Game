extends Node3D
## Eiswelt: zwei Eisschollen mit einer Spalte in der Mitte (wer hineinfällt, ist raus),
## eine schwebende Scholle über der Spalte und zwei hohe Eisvorsprünge. Es schneit.

const GAP := 1.3


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var ice := MapLook.mat(Color(0.62, 0.86, 0.97), 0.12, 0.1)
	var ice_dark := MapLook.mat(Color(0.35, 0.6, 0.8), 0.15, 0.1)
	var snow := MapLook.mat(Color(0.96, 0.98, 1.0), 0.8)
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

	# Kaltes Licht und Schneefall.
	MapLook.light(look, Vector3(0, 4.0, 5.0), Color(0.6, 0.85, 1.0), 1.0, 14.0)
	MapLook.particles(self, Vector3(0, 13.0, 0), Vector3(24, 1, 8), Color(1, 1, 1, 0.9), 160,
		Vector3(0.3, -1.6, 0), 0.1, 12.0)
	MapLook.backdrop(bg, "res://assets/maps/eiswelt/hintergrund.png")
