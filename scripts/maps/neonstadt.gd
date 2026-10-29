extends Node3D
## Neonstadt bei Nacht: zwei breite Hochhausdächer auf verschiedener Höhe, dazwischen eine Gasse, durch die man
## hinunter in die Neon-Arkade fällt (ein offenes Stockwerk mit Läden unter den Dächern). Außen Feuerleitern,
## auf den Dächern Klimagerät, Lüftungsschacht, Antenne, Werbeschild und Wassertank. Ein Hover-Taxi fliegt über
## der Gasse, ganz oben zieht ein Werbe-Luftschiff hin und her. Regen und Lichter in Lila und Türkis.

const HALF := 12.5
const ARCADE_Y := -4.2
## Halbe Breite der Gasse zwischen den Häusern.
const ALLEY := 1.5


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var metal_tex := MapFX.tex("metall")
	var metal: Material = MapFX.textured(metal_tex, MapFX.tex("metall_n"), Color(0.8, 0.82, 0.9), 0.35, 0.35, 0.6) if metal_tex \
		else MapLook.mat(Color(0.22, 0.24, 0.3), 0.35, 0.6)
	var wall := MapFX.surface("beton", Color(0.1, 0.1, 0.15), 0.7, 0.3)
	var steel := MapFX.surface("rost", Color(0.4, 0.42, 0.48), 0.4, 0.8)
	var cyan := MapLook.mat(Color(0.2, 0.95, 1.0), 0.4, 0.0, 3.0)
	var pink := MapLook.mat(Color(1.0, 0.2, 0.75), 0.4, 0.0, 3.0)
	var purple := MapLook.mat(Color(0.6, 0.3, 1.0), 0.4, 0.0, 3.0)
	var holo := MapLook.mat(Color(0.25, 0.9, 1.0, 0.45), 0.2, 0.0, 1.5)
	$Spawn1.position = Vector3(-5.0, 0.2, 0)
	$Spawn2.position = Vector3(5.0, 1.4, 0)
	MapLook.stage_area(self, Rect2(-15.5, ARCADE_Y, 31.0, 8.4 - ARCADE_Y), HALF)

	# Zwei Hochhausdächer: links niedriger, rechts 1,2 höher, dazwischen die Gasse. Neonkanten vorne.
	var window := MapLook.mat(Color(0.9, 0.6, 0.3), 0.5, 0.0, 0.5)
	for r in [[-HALF, -ALLEY, 0.0], [ALLEY, HALF, 1.2]]:
		var x1: float = r[0]
		var x2: float = r[1]
		var h: float = r[2]
		var w := x2 - x1
		var cx := (x1 + x2) / 2.0
		MapLook.solid(col, Vector3(w, 1.4, 4), Vector3(cx, h - 0.7, 0))
		MapLook.box(look, Vector3(w + 0.2, 0.5, 4.4), Vector3(cx, h - 0.25, 0), metal)
		MapLook.box(look, Vector3(w, 0.9, 4.2), Vector3(cx, h - 0.95, 0), wall)
		MapLook.box(look, Vector3(w + 0.3, 0.06, 0.08), Vector3(cx, h - 0.02, 2.2), cyan if h == 0.0 else pink)
		MapLook.box(look, Vector3(w + 0.1, 0.05, 0.06), Vector3(cx, h - 1.4, 2.12), purple)

	_arcade(col, look, wall, steel, metal, window, cyan, pink, purple)

	# Klimagerät links: fester Kasten, auf den man sich stellen kann.
	MapLook.solid(col, Vector3(1.6, 1.0, 1.6), Vector3(-9.8, 0.5, 0))
	MapLook.box(look, Vector3(1.6, 1.0, 1.6), Vector3(-9.8, 0.5, 0), steel)
	MapLook.cylinder(look, 0.55, 0.08, Vector3(-9.8, 1.03, 0), wall, -1.0, Vector3.ZERO, 16)
	MapLook.box(look, Vector3(1.0, 0.6, 0.05), Vector3(-9.8, 0.5, 0.81), wall)
	# Rohre, Lüfter hinten.
	MapLook.cylinder(look, 0.12, 2.0, Vector3(-3.0, 1.0, -1.8), steel, -1.0, Vector3.ZERO, 8)
	MapLook.cylinder(look, 0.12, 6.0, Vector3(-6.0, 0.4, -1.8), steel, -1.0, Vector3(0, 0, 90), 8)
	MapLook.box(look, Vector3(1.4, 1.0, 1.2), Vector3(3.4, 1.7, -1.4), steel)

	# Lüftungsschacht im linken Dach: warmer Aufwind hebt alle sanft nach oben.
	var vent := -5.2
	BouncePad.create(look, Vector3(1.4, 6.0, 2.0), Vector3(vent, 3.0, 0), 9.0, true)
	MapLook.box(look, Vector3(1.4, 0.06, 1.6), Vector3(vent, 0.03, 0), steel)
	for k in 5:
		MapLook.box(look, Vector3(1.3, 0.04, 0.08), Vector3(vent, 0.07, -0.6 + k * 0.3), wall)
	MapLook.particles(look, Vector3(vent, 0.3, 0), Vector3(0.6, 0.1, 0.6), Color(0.6, 1.0, 1.0, 0.5), 40,
		Vector3(0, 6.0, 0), 0.06, 1.0)
	MapLook.light(look, Vector3(vent, 0.4, 0.6), Color(0.3, 0.9, 1.0), 1.0, 3.0)

	# Antenne links oben mit kleiner Plattform.
	var mast := Vector3(-8.0, 4.4, 0)
	MapLook.platform(col, Vector3(1.8, 0.3, 1.6), mast)
	MapLook.box(plat, Vector3(1.8, 0.15, 1.6), mast, steel)
	MapLook.box(plat, Vector3(1.9, 0.04, 0.06), mast + Vector3(0, 0.08, 0.8), cyan)
	MapLook.cylinder(plat, 0.08, 4.4, Vector3(mast.x, 2.2, -0.6), steel, -1.0, Vector3.ZERO, 8)
	MapLook.cylinder(plat, 0.04, 2.0, mast + Vector3(0.6, 1.0, -0.6), steel, 0.01, Vector3.ZERO, 6)
	MapLook.sphere(plat, 0.1, mast + Vector3(0.6, 2.05, -0.6), MapLook.mat(Color(1, 0.1, 0.1), 0.5, 0.0, 4.0))
	MapLook.light(plat, mast + Vector3(0.6, 2.0, -0.3), Color(1, 0.1, 0.1), 1.0, 3.0)

	# Werbeschild rechts oben mit Neonschrift: Plattform auf dem Schild.
	var top := Vector3(6.4, 5.0, 0)
	MapLook.platform(col, Vector3(3.6, 0.3, 2.0), top)
	MapLook.box(plat, Vector3(3.7, 0.3, 2.0), top, steel)
	MapLook.box(plat, Vector3(4.0, 1.6, 0.2), top + Vector3(0, -1.1, -0.6), wall)
	MapLook.box(plat, Vector3(4.1, 0.06, 0.06), top + Vector3(0, -0.28, -0.48), pink)
	MapLook.box(plat, Vector3(4.1, 0.06, 0.06), top + Vector3(0, -1.92, -0.48), pink)
	_neon_text(plat, "ARENA", top + Vector3(0, -1.1, -0.45), Color(1.0, 0.3, 0.8), 140)
	for side in [-1, 1]:
		MapLook.box(plat, Vector3(0.12, 3.8, 0.12), top + Vector3(side * 1.6, -1.9, -0.8), steel)

	# Wassertank rechts auf dem Dach: man kann draufspringen.
	var tank := Vector3(10.8, 1.2, 0)
	MapLook.solid(col, Vector3(2.0, 2.4, 2.0), tank + Vector3(0, 1.2, 0))
	MapLook.cylinder(look, 1.05, 1.9, tank + Vector3(0, 1.45, 0), MapFX.surface("rost", Color(0.35, 0.25, 0.2), 0.8), -1.0,
		Vector3.ZERO, 16)
	MapLook.cylinder(look, 1.15, 0.5, tank + Vector3(0, 2.65, 0), wall, 0.2, Vector3.ZERO, 16)
	for side in [-1, 1]:
		MapLook.box(look, Vector3(0.12, 0.5, 0.12), tank + Vector3(side * 0.8, 0.25, 0.6), steel)
	MapLook.box(look, Vector3(2.2, 0.05, 0.06), tank + Vector3(0, 0.9, 1.08), cyan)

	# Feuerleitern außen an den Häusern: von hier kommt man aus der Arkade wieder hoch.
	for f in [[-14.0, -1.6], [14.0, -1.0]]:
		var pos := Vector3(f[0], f[1], 0)
		MapLook.platform(col, Vector3(2.4, 0.3, 1.8), pos)
		MapLook.box(plat, Vector3(2.4, 0.1, 1.8), pos, steel)
		MapLook.box(plat, Vector3(2.4, 0.06, 0.06), pos + Vector3(0, 0.7, 0.88), steel)
		for k in 3:
			MapLook.box(plat, Vector3(0.06, 0.7, 0.06), pos + Vector3(-1.1 + k * 1.1, 0.35, 0.88), steel)
		MapLook.box(plat, Vector3(0.1, 3.2, 0.1), pos + Vector3(signf(pos.x) * 1.1, -1.6, 0.6), steel)

	# Hover-Taxi: fliegt über der Gasse hin und her.
	var taxi := MovingPlatform.create(plat, Vector3(2.6, 0.3, 1.8), Vector3(-5.0, 3.0, 0), Vector3(4.0, 3.0, 0), 9.0)
	var taxi_body := MapLook.mat(Color(1.0, 0.8, 0.15), 0.35, 0.4)
	MapLook.box(taxi, Vector3(2.6, 0.35, 1.8), Vector3(0, -0.05, 0), taxi_body)
	MapLook.box(taxi, Vector3(2.7, 0.06, 1.9), Vector3(0, -0.25, 0), cyan)
	MapLook.box(taxi, Vector3(0.6, 0.2, 0.3), Vector3(0, 0.2, -0.7), MapLook.mat(Color(0.1, 0.1, 0.12), 0.4, 0.5))
	_neon_text(taxi, "TAXI", Vector3(0, 0.35, -0.7), Color(1.0, 0.9, 0.3), 40)
	for side in [-1, 1]:
		MapLook.cylinder(taxi, 0.3, 0.15, Vector3(side * 1.1, -0.35, 0), holo, 0.15, Vector3.ZERO, 12)
	MapLook.light(taxi, Vector3(0, -0.6, 0.4), Color(0.2, 0.9, 1.0), 1.5, 4.0)

	# Werbe-Luftschiff ganz oben: auf seinem Rücken kann man stehen.
	var blimp := MovingPlatform.create(plat, Vector3(4.0, 0.3, 1.8), Vector3(-5.0, 8.2, 0), Vector3(5.0, 8.2, 0), 16.0, 0.25)
	var hull := MapLook.sphere(blimp, 1.0, Vector3(0, -0.85, -0.4), MapLook.mat(Color(0.25, 0.22, 0.35), 0.5, 0.3))
	hull.scale = Vector3(2.6, 0.85, 0.9)
	MapLook.box(blimp, Vector3(4.0, 0.12, 1.6), Vector3(0, -0.05, -0.2), steel)
	MapLook.box(blimp, Vector3(3.2, 0.5, 0.05), Vector3(0, -0.9, 0.52), wall)
	_neon_text(blimp, "SIEG!", Vector3(0, -0.9, 0.56), Color(0.3, 1.0, 0.9), 70)
	MapLook.box(blimp, Vector3(0.9, 0.35, 0.5), Vector3(0, -1.75, -0.3), steel)
	for side in [-1, 1]:
		MapLook.box(blimp, Vector3(0.6, 0.7, 0.06), Vector3(side * 2.5, -0.8, -0.4), purple)
	MapLook.light(blimp, Vector3(0, -1.9, 0.2), Color(0.3, 1.0, 0.9), 1.4, 5.0)

	# Leuchtreklame an den Nachbarhäusern.
	var signs := [["RAMEN", Vector3(-20.0, 7.0, -19.0), Color(1.0, 0.35, 0.2)], ["24H", Vector3(20.5, 8.5, -19.0), Color(0.3, 1.0, 0.9)],
		["CYBER", Vector3(-7.0, 14.0, -27.0), Color(0.7, 0.4, 1.0)], ["KAMPF", Vector3(9.0, 15.5, -25.0), Color(1.0, 0.3, 0.8)]]
	for s in signs:
		MapLook.box(bg, Vector3(5.5, 1.8, 0.2), s[1] + Vector3(0, 0, -0.2), wall)
		_neon_text(bg, s[0], s[1], s[2], 200)
		MapLook.light(bg, s[1] + Vector3(0, 0, 1.0), s[2], 2.0, 7.0)
	for b in [[-26.0, 16.0, -22.0], [-13.0, 20.0, -30.0], [0.0, 24.0, -38.0], [13.0, 19.0, -28.0], [26.0, 15.0, -22.0]]:
		MapLook.box(bg, Vector3(6.0, b[1], 5.0), Vector3(b[0], b[1] * 0.5 - 6.0, b[2]), wall)
		for k in 6:
			var m: Material = [cyan, pink, purple][k % 3]
			MapLook.box(bg, Vector3(0.12, b[1] * 0.8, 0.1), Vector3(b[0] - 2.9 + k * 1.16, b[1] * 0.45 - 6.0, b[2] + 2.55), m)

	# Regen, Lichter in Lila und Türkis, Nebel in der Tiefe.
	MapLook.particles(self, Vector3(0, 13.0, 0), Vector3(20, 1, 6), Color(0.7, 0.85, 1.0, 0.6), 300,
		Vector3(-1.0, -22.0, 0), 0.04, 1.0)
	MapLook.light(look, Vector3(-7.0, 4.0, 3.0), Color(0.7, 0.3, 1.0), 1.4, 14.0)
	MapLook.light(look, Vector3(7.0, 4.0, 3.0), Color(0.2, 0.9, 1.0), 1.4, 14.0)
	fx.flicker_all(bg, 0.08)
	MapFX.mood(self, Color(0.2, 0.1, 0.35), 0.015, 0.9, 1.2, 1.1)

	# Vordergrund: dunkle Dachkanten mit Neonleiste in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.box(fg, Vector3(1.2, 0.5, 0.3), Vector3(side * 2.05, -1.35, -3.0), wall, Vector3(0, 0, side * 6.0))
		MapLook.box(fg, Vector3(1.2, 0.03, 0.05), Vector3(side * 2.05, -1.1, -2.85), cyan, Vector3(0, 0, side * 6.0))
	MapLook.backdrop(bg, "res://assets/maps/neonstadt/hintergrund.png", -60.0, 180.0, 10.0)


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


## Neon-Arkade: offenes Stockwerk unter beiden Dächern mit Läden, Automaten und Säulen. Darunter die Hauswände
## mit Fenstern bis in die Tiefe.
func _arcade(col: Node3D, look: Node3D, wall: Material, steel: Material, metal: Material, window: Material,
		cyan: Material, pink: Material, purple: Material) -> void:
	MapLook.solid(col, Vector3(HALF * 2.0, 1.2, 4), Vector3(0, ARCADE_Y - 0.6, 0))
	MapLook.box(look, Vector3(HALF * 2.0 + 0.2, 0.3, 4.3), Vector3(0, ARCADE_Y - 0.15, 0), metal)
	MapLook.box(look, Vector3(HALF * 2.0 + 0.3, 0.05, 0.08), Vector3(0, ARCADE_Y - 0.02, 2.17), cyan)
	# Rückwand mit Läden.
	var h := 1.4 + absf(ARCADE_Y)
	MapLook.box(look, Vector3(HALF * 2.0, h, 0.3), Vector3(0, ARCADE_Y + h / 2.0, -1.95), wall)
	var shops := [["RAMEN", -9.0, Color(1.0, 0.4, 0.2)], ["GAMES", -4.5, Color(0.3, 1.0, 0.9)],
		["SUSHI", 4.5, Color(1.0, 0.3, 0.8)], ["ROBO", 9.0, Color(0.7, 0.45, 1.0)]]
	for shop in shops:
		var x: float = shop[1]
		var c: Color = shop[2]
		MapLook.box(look, Vector3(3.0, 1.6, 0.1), Vector3(x, ARCADE_Y + 0.9, -1.78), MapLook.mat(c * 0.35, 0.4, 0.0, 0.6))
		_neon_text(look, shop[0], Vector3(x, ARCADE_Y + 2.25, -1.75), c, 70)
		MapLook.light(look, Vector3(x, ARCADE_Y + 1.6, -0.8), c, 1.1, 4.5)
	for x in [-11.5, -6.8, -2.2, 2.2, 6.8, 11.5]:
		MapLook.box(look, Vector3(0.4, h, 0.4), Vector3(x, ARCADE_Y + h / 2.0, -1.5), steel)
	# Getränkeautomaten.
	for x in [-1.0, 0.9]:
		MapLook.box(look, Vector3(0.8, 1.7, 0.6), Vector3(x, ARCADE_Y + 0.85, -1.4), MapLook.mat(Color(0.85, 0.85, 0.9), 0.4, 0.3))
		MapLook.box(look, Vector3(0.6, 1.0, 0.04), Vector3(x, ARCADE_Y + 1.0, -1.08), MapLook.mat(Color(0.4, 0.9, 1.0), 0.3, 0.0, 1.5))
	# Hauswände unter der Arkade mit Fenstern.
	for side in [-1, 1]:
		var cx: float = side * (HALF + ALLEY) / 2.0
		var w := HALF - ALLEY + 0.0
		MapLook.box(look, Vector3(HALF, 12.0, 4.0), Vector3(side * HALF / 2.0, ARCADE_Y - 7.2, -0.2), wall)
		for row in 4:
			for i in int(w / 2.0):
				if (row * 7 + i + side) % 3 != 0:
					MapLook.box(look, Vector3(1.2, 0.8, 0.05), Vector3(cx - w * 0.5 + 1.2 + i * 2.0, ARCADE_Y - 2.0 - row * 1.6, 1.82),
						window)
	MapLook.box(look, Vector3(HALF * 2.0, 0.08, 0.08), Vector3(0, ARCADE_Y - 1.25, 2.12), pink)
	MapLook.particles(look, Vector3(0, ARCADE_Y + 1.5, -0.5), Vector3(11, 1.0, 1.0), Color(0.8, 0.5, 1.0, 0.7), 20,
		Vector3(0, 0.2, 0), 0.04, 4.0)
	MapLook.light(look, Vector3(0, ARCADE_Y + 2.0, 1.5), Color(0.7, 0.4, 1.0), 1.0, 10.0)
	# Pfützen in der Gasse.
	MapLook.box(look, Vector3(ALLEY * 2.0, 0.02, 3.0), Vector3(0, ARCADE_Y + 0.01, 0.3), MapLook.mat(Color(0.3, 0.4, 0.6), 0.05, 0.6))
