extends Node3D
## Neonstadt bei Nacht: zwei Hochhausdächer auf verschiedener Höhe mit Klimagerät und Antenne, ein Hover-Taxi,
## das hin und her fliegt, dahinter leuchtende Reklametafeln und oben ein Werbeschild als Plattform.
## Regen, nasse Spiegelungen und Lichter in Lila und Türkis.


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var metal_tex := MapFX.tex("metall")
	var metal: Material = MapFX.textured(metal_tex, MapFX.tex("metall_n"), Color(0.8, 0.82, 0.9), 0.35, 0.35, 0.6) if metal_tex \
		else MapLook.mat(Color(0.22, 0.24, 0.3), 0.35, 0.6)
	var wall := MapLook.mat(Color(0.1, 0.1, 0.15), 0.7, 0.3)
	var steel := MapLook.mat(Color(0.4, 0.42, 0.48), 0.4, 0.8)
	var cyan := MapLook.mat(Color(0.2, 0.95, 1.0), 0.4, 0.0, 3.0)
	var pink := MapLook.mat(Color(1.0, 0.2, 0.75), 0.4, 0.0, 3.0)
	var purple := MapLook.mat(Color(0.6, 0.3, 1.0), 0.4, 0.0, 3.0)
	var holo := MapLook.mat(Color(0.25, 0.9, 1.0, 0.45), 0.2, 0.0, 1.5)
	$Spawn1.position = Vector3(-3.5, 0.2, 0)
	$Spawn2.position = Vector3(3.5, 1.4, 0)

	# Zwei Hochhausdächer: links niedriger, rechts 1,2 höher. Hauswände mit Fenstern, Neonkanten vorne.
	var window := MapLook.mat(Color(0.9, 0.6, 0.3), 0.5, 0.0, 0.5)
	for r in [[-3.35, 8.3, 0.0], [4.15, 6.7, 1.2]]:
		var cx: float = r[0]
		var w: float = r[1]
		var h: float = r[2]
		MapLook.solid(col, Vector3(w, 2.2, 4), Vector3(cx, h - 1.1, 0))
		MapLook.box(look, Vector3(w + 0.2, 0.5, 4.4), Vector3(cx, h - 0.25, 0), metal)
		MapLook.box(look, Vector3(w + 0.3, 0.06, 0.08), Vector3(cx, h - 0.02, 2.2), cyan if h == 0.0 else pink)
		MapLook.box(look, Vector3(w, 12.0, 4.0), Vector3(cx, h - 6.5, -0.2), wall)
		for row in 4:
			for i in int(w / 2.0):
				if (row * 7 + i + int(h)) % 3 != 0:
					MapLook.box(look, Vector3(1.2, 0.8, 0.05), Vector3(cx - w * 0.5 + 1.2 + i * 2.0, h - 1.6 - row * 1.6, 1.82), window)
	# Kante zwischen den Dächern: Metallwand mit Leiter.
	MapLook.box(look, Vector3(0.3, 1.3, 4.2), Vector3(0.75, 0.6, 0), steel)
	for k in 4:
		MapLook.box(look, Vector3(0.5, 0.05, 0.05), Vector3(0.55, 0.2 + k * 0.3, 1.7), steel)

	# Klimagerät links: fester Kasten, auf den man sich stellen kann.
	MapLook.solid(col, Vector3(1.6, 1.0, 1.6), Vector3(-5.6, 0.5, 0))
	MapLook.box(look, Vector3(1.6, 1.0, 1.6), Vector3(-5.6, 0.5, 0), steel)
	MapLook.cylinder(look, 0.55, 0.08, Vector3(-5.6, 1.03, 0), wall, -1.0, Vector3.ZERO, 16)
	MapLook.box(look, Vector3(1.0, 0.6, 0.05), Vector3(-5.6, 0.5, 0.81), wall)
	# Rohre, Lüfter hinten und eine Antenne mit blinkendem Licht.
	MapLook.cylinder(look, 0.12, 2.0, Vector3(-2.5, 1.0, -1.8), steel, -1.0, Vector3.ZERO, 8)
	MapLook.cylinder(look, 0.12, 5.0, Vector3(-2.0, 0.4, -1.8), steel, -1.0, Vector3(0, 0, 90), 8)
	MapLook.box(look, Vector3(1.4, 1.0, 1.2), Vector3(6.4, 1.7, -1.4), steel)

	# Lüftungsschacht im linken Dach: warmer Aufwind hebt alle sanft nach oben.
	BouncePad.create(look, Vector3(1.4, 6.0, 2.0), Vector3(-2.2, 3.0, 0), 9.0, true)
	MapLook.box(look, Vector3(1.4, 0.06, 1.6), Vector3(-2.2, 0.03, 0), steel)
	for k in 5:
		MapLook.box(look, Vector3(1.3, 0.04, 0.08), Vector3(-2.2, 0.07, -0.6 + k * 0.3), wall)
	MapLook.particles(look, Vector3(-2.2, 0.3, 0), Vector3(0.6, 0.1, 0.6), Color(0.6, 1.0, 1.0, 0.5), 40,
		Vector3(0, 6.0, 0), 0.06, 1.0)
	MapLook.light(look, Vector3(-2.2, 0.4, 0.6), Color(0.3, 0.9, 1.0), 1.0, 3.0)

	# Antenne links oben mit kleiner Plattform.
	var mast := Vector3(-6.2, 4.6, 0)
	MapLook.platform(col, Vector3(1.8, 0.3, 1.6), mast)
	MapLook.box(plat, Vector3(1.8, 0.15, 1.6), mast, steel)
	MapLook.box(plat, Vector3(1.9, 0.04, 0.06), mast + Vector3(0, 0.08, 0.8), cyan)
	MapLook.cylinder(plat, 0.08, 4.6, Vector3(-6.2, 2.3, -0.6), steel, -1.0, Vector3.ZERO, 8)
	MapLook.cylinder(plat, 0.04, 2.0, mast + Vector3(0.6, 1.0, -0.6), steel, 0.01, Vector3.ZERO, 6)
	MapLook.sphere(plat, 0.1, mast + Vector3(0.6, 2.05, -0.6), MapLook.mat(Color(1, 0.1, 0.1), 0.5, 0.0, 4.0))
	MapLook.light(plat, mast + Vector3(0.6, 2.0, -0.3), Color(1, 0.1, 0.1), 1.0, 3.0)

	# Werbeschild rechts oben mit Neonschrift: Plattform auf dem Schild.
	var top := Vector3(4.6, 5.0, 0)
	MapLook.platform(col, Vector3(3.6, 0.3, 2.0), top)
	MapLook.box(plat, Vector3(3.7, 0.3, 2.0), top, steel)
	MapLook.box(plat, Vector3(4.0, 1.6, 0.2), top + Vector3(0, -1.1, -0.6), wall)
	MapLook.box(plat, Vector3(4.1, 0.06, 0.06), top + Vector3(0, -0.28, -0.48), pink)
	MapLook.box(plat, Vector3(4.1, 0.06, 0.06), top + Vector3(0, -1.92, -0.48), pink)
	_neon_text(plat, "ARENA", top + Vector3(0, -1.1, -0.45), Color(1.0, 0.3, 0.8), 140)
	for side in [-1, 1]:
		MapLook.box(plat, Vector3(0.12, 3.8, 0.12), top + Vector3(side * 1.6, -1.9, -0.8), steel)

	# Hover-Taxi: fliegt quer über die Arena hin und her.
	var taxi := MovingPlatform.create(plat, Vector3(2.6, 0.3, 1.8), Vector3(-4.0, 3.0, 0), Vector3(2.0, 3.0, 0), 9.0)
	var taxi_body := MapLook.mat(Color(1.0, 0.8, 0.15), 0.35, 0.4)
	MapLook.box(taxi, Vector3(2.6, 0.35, 1.8), Vector3(0, -0.05, 0), taxi_body)
	MapLook.box(taxi, Vector3(2.7, 0.06, 1.9), Vector3(0, -0.25, 0), cyan)
	MapLook.box(taxi, Vector3(0.6, 0.2, 0.3), Vector3(0, 0.2, -0.7), MapLook.mat(Color(0.1, 0.1, 0.12), 0.4, 0.5))
	_neon_text(taxi, "TAXI", Vector3(0, 0.35, -0.7), Color(1.0, 0.9, 0.3), 40)
	for side in [-1, 1]:
		MapLook.cylinder(taxi, 0.3, 0.15, Vector3(side * 1.1, -0.35, 0), holo, 0.15, Vector3.ZERO, 12)
	MapLook.light(taxi, Vector3(0, -0.6, 0.4), Color(0.2, 0.9, 1.0), 1.5, 4.0)

	# Leuchtreklame an den Nachbarhäusern.
	var signs := [["RAMEN", Vector3(-11.0, 6.0, -8.0), Color(1.0, 0.35, 0.2)], ["24H", Vector3(10.5, 7.5, -9.0), Color(0.3, 1.0, 0.9)],
		["CYBER", Vector3(-4.0, 10.0, -14.0), Color(0.7, 0.4, 1.0)], ["KAMPF", Vector3(6.0, 11.5, -16.0), Color(1.0, 0.3, 0.8)]]
	for s in signs:
		MapLook.box(bg, Vector3(5.5, 1.8, 0.2), s[1] + Vector3(0, 0, -0.2), wall)
		_neon_text(bg, s[0], s[1], s[2], 200)
		MapLook.light(bg, s[1] + Vector3(0, 0, 1.0), s[2], 2.0, 7.0)
	for b in [[-16.0, 14.0, -12.0], [-9.0, 18.0, -20.0], [0.0, 22.0, -26.0], [9.0, 17.0, -18.0], [16.0, 13.0, -11.0]]:
		MapLook.box(bg, Vector3(6.0, b[1], 5.0), Vector3(b[0], b[1] * 0.5 - 6.0, b[2]), wall)
		for k in 6:
			var m: Material = [cyan, pink, purple][k % 3]
			MapLook.box(bg, Vector3(0.12, b[1] * 0.8, 0.1), Vector3(b[0] - 2.9 + k * 1.16, b[1] * 0.45 - 6.0, b[2] + 2.55), m)

	# Regen, Lichter in Lila und Türkis, Nebel in der Tiefe.
	MapLook.particles(self, Vector3(0, 12.0, 0), Vector3(16, 1, 6), Color(0.7, 0.85, 1.0, 0.6), 220,
		Vector3(-1.0, -22.0, 0), 0.04, 1.0)
	MapLook.light(look, Vector3(-5.0, 4.0, 3.0), Color(0.7, 0.3, 1.0), 1.4, 12.0)
	MapLook.light(look, Vector3(5.0, 4.0, 3.0), Color(0.2, 0.9, 1.0), 1.4, 12.0)
	fx.flicker_all(bg, 0.08)
	MapFX.mood(self, Color(0.2, 0.1, 0.35), 0.015, 0.9, 1.2, 1.1)

	# Vordergrund: dunkle Dachkanten mit Neonleiste in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.box(fg, Vector3(1.2, 0.5, 0.3), Vector3(side * 2.05, -1.35, -3.0), wall, Vector3(0, 0, side * 6.0))
		MapLook.box(fg, Vector3(1.2, 0.03, 0.05), Vector3(side * 2.05, -1.1, -2.85), cyan, Vector3(0, 0, side * 6.0))
	MapLook.backdrop(bg, "res://assets/maps/neonstadt/hintergrund.png")


## Leuchtschrift als 3D-Text.
func _neon_text(parent: Node3D, text: String, pos: Vector3, color: Color, size: int) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.01
	label.modulate = color * 1.6
	label.outline_size = 18
	label.outline_modulate = Color(color, 0.5)
	label.shaded = false
	label.position = pos
	parent.add_child(label)
