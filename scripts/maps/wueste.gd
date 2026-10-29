extends Node3D
## Wüstenarena: Sandboden in einem großen Kolosseum aus Sandstein, umgestürzte Säulen und Fahnen,
## dahinter Dünen und Pyramiden. Eine abgesenkte Sandgrube in der Mitte, zwei Säulen und darüber ein Sonnensegel.
## Links und rechts steigen die Tribünen an bis zur Kaiserloge. Unter der Arena liegen die Gladiatorengänge:
## zwei Aufzüge fahren hinunter und wieder hoch (ist ein Aufzug unten, ist im Boden ein Loch!).
## Grelle Mittagssonne, flirrende Hitze und wehender Sand.

const HALF := 11.0
const BELOW_Y := -5.0
const BELOW_HALF := 13.0
## Mitte der beiden Aufzugsschächte (links und rechts) und ihre halbe Breite.
const LIFT_X := 7.0
const LIFT_HALF := 1.0


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var sand_tex := MapFX.tex("sand")
	var sand: Material = MapFX.textured(sand_tex, MapFX.tex("sand_n"), Color.WHITE, 0.3) if sand_tex \
		else MapLook.mat(Color(0.9, 0.75, 0.48))
	var sandstone_tex := MapFX.tex("sandstein")
	var sandstone: Material = MapFX.textured(sandstone_tex, MapFX.tex("sandstein_n"), Color.WHITE, 0.3) if sandstone_tex \
		else MapLook.mat(Color(0.85, 0.68, 0.45))
	var sandstone_dark := MapFX.surface("sandstein", Color(0.65, 0.5, 0.33))
	var red := MapFX.surface("stoff", Color(0.75, 0.15, 0.1), 0.8)
	var blue := MapFX.surface("stoff", Color(0.15, 0.3, 0.7), 0.8)
	var gold := MapFX.surface("gold", Color(0.95, 0.75, 0.3), 0.3, 0.8)
	var dune := MapFX.surface("sand", Color(0.95, 0.78, 0.5), 1.0)
	$Spawn1.position = Vector3(-4.5, 0.2, 0)
	$Spawn2.position = Vector3(4.5, 0.2, 0)
	MapLook.stage_area(self, Rect2(-14.4, BELOW_Y, 28.8, 6.8 - BELOW_Y), HALF)

	# Arenaboden aus Sand: abgesenkte Sandgrube in der Mitte, Aufzugsschächte links und rechts.
	var pieces := [[-HALF, -LIFT_X - LIFT_HALF], [-LIFT_X + LIFT_HALF, -2.0], [2.0, LIFT_X - LIFT_HALF], [LIFT_X + LIFT_HALF, HALF]]
	for f in pieces:
		var w: float = f[1] - f[0]
		var cx: float = (f[0] + f[1]) / 2.0
		MapLook.solid(col, Vector3(w, 1.4, 4), Vector3(cx, -0.7, 0))
		MapLook.box(look, Vector3(w, 0.5, 4.2), Vector3(cx, -0.25, 0), sand)
		MapLook.box(look, Vector3(w, 0.9, 4.4), Vector3(cx, -0.95, 0), sandstone_dark)
	MapLook.solid(col, Vector3(4.0, 1.4, 4), Vector3(0, -1.5, 0))
	MapLook.box(look, Vector3(4.0, 0.5, 4.2), Vector3(0, -1.05, 0), sand)
	MapLook.box(look, Vector3(4.0, 0.9, 4.4), Vector3(0, -1.75, 0), sandstone_dark)
	for side in [-1, 1]:
		MapLook.box(look, Vector3(0.3, 0.85, 4.2), Vector3(side * 2.05, -0.4, 0), sandstone_dark)
	for f in pieces:
		MapLook.box(look, Vector3(f[1] - f[0], 0.5, 0.4), Vector3((f[0] + f[1]) / 2.0, -0.2, 2.2), sandstone)
	# Knochen und ein alter Helm in der Grube.
	MapLook.cylinder(look, 0.06, 0.8, Vector3(-0.8, -0.75, -0.8), MapLook.mat(Color(0.95, 0.92, 0.85)), -1.0, Vector3(0, 30, 90), 6)
	MapLook.sphere(look, 0.25, Vector3(0.9, -0.7, -1.0), gold, Vector3(1.0, 0.7, 1.0))

	_hypogeum(col, look, plat, sand, sandstone, sandstone_dark, red, gold)

	# Kolosseumsmauer hinten: Bögen in zwei Stockwerken, Fahnen, umgestürzte Säulen.
	MapLook.box(look, Vector3(22.0, 0.5, 0.8), Vector3(0, 0.25, -2.3), sandstone)
	for i in 13:
		var x := -14.4 + i * 2.4
		MapLook.box(bg, Vector3(0.7, 6.0, 1.0), Vector3(x, 3.0, -11.0), sandstone_dark)
		MapLook.box(bg, Vector3(0.6, 3.5, 0.9), Vector3(x, 7.8, -11.2), sandstone_dark)
	MapLook.box(bg, Vector3(31.0, 0.8, 1.2), Vector3(0, 6.2, -11.0), sandstone_dark)
	MapLook.box(bg, Vector3(31.0, 0.6, 1.0), Vector3(0, 9.8, -11.2), sandstone_dark)
	MapLook.box(bg, Vector3(31.0, 9.6, 0.4), Vector3(0, 4.8, -11.8), MapLook.mat(Color(0.5, 0.38, 0.26)))
	for i in 6:
		var x := -10.0 + i * 4.0
		MapFX.cloth(bg, Vector2(1.0, 2.4), Vector3(x, 8.4, -10.6), Color(0.75, 0.15, 0.1) if i % 2 == 0 else Color(0.15, 0.3, 0.7),
			null, true, 0.15)
	MapLook.cylinder(look, 0.4, 3.0, Vector3(-4.6, 0.4, -1.5), sandstone, -1.0, Vector3(0, 30, 90), 10)
	# Waffenständer mit Schilden.
	for x in [4.4]:
		MapLook.box(look, Vector3(1.2, 0.12, 0.12), Vector3(x, 1.0, -1.8), sandstone_dark)
		MapLook.cylinder(look, 0.32, 0.06, Vector3(x - 0.3, 0.75, -1.72), red, -1.0, Vector3(90, 0, 0), 16)
		MapLook.cylinder(look, 0.32, 0.06, Vector3(x + 0.35, 0.75, -1.72), blue, -1.0, Vector3(90, 0, 0), 16)
		MapLook.sphere(look, 0.08, Vector3(x - 0.3, 0.75, -1.66), gold)
		MapLook.sphere(look, 0.08, Vector3(x + 0.35, 0.75, -1.66), gold)

	# Zwei Säulen-Plattformen neben der Grube, darüber das Sonnensegel.
	for p in [[-3.4, 3.0, 2.4], [3.4, 3.0, 2.4]]:
		var pos := Vector3(p[0], p[1], 0)
		var width: float = p[2]
		MapLook.platform(col, Vector3(width, 0.3, 2.2), pos)
		MapLook.box(plat, Vector3(width + 0.1, 0.5, 2.2), pos + Vector3(0, -0.1, 0), sandstone)
		MapLook.box(plat, Vector3(width + 0.2, 0.08, 2.3), pos + Vector3(0, -0.38, 0), gold)
		var h: float = p[1] - 0.35
		MapLook.cylinder(plat, 0.36, h, Vector3(p[0], h * 0.5, -0.6), sandstone_dark, 0.3, Vector3.ZERO, 10)
	var awning := Vector3(0, 6.0, 0)
	MapLook.platform(col, Vector3(6.0, 0.3, 2.2), awning)
	MapLook.box(plat, Vector3(6.2, 0.12, 2.4), awning + Vector3(0, -0.06, -0.2), red)
	for k in 4:
		MapLook.box(plat, Vector3(0.7, 0.13, 2.42), awning + Vector3(-2.25 + k * 1.5, -0.05, -0.2), MapFX.surface("stoff", Color(0.95, 0.9, 0.75), 0.9))
	for side in [-1, 1]:
		MapLook.cylinder(plat, 0.06, 2.6, awning + Vector3(side * 3.0, -1.3, -1.2), MapLook.mat(Color(0.4, 0.28, 0.15)), -1.0,
			Vector3.ZERO, 6)
		MapLook.box(plat, Vector3(0.05, 0.05, 2.0), awning + Vector3(side * 3.0, -0.05, -0.2), gold)

	# Tribünen links und rechts: Sitzreihen aus Sandstein, oben die Kaiserloge mit Baldachin.
	for side in [-1, 1]:
		for r in [[9.6, 2.3, 2.8], [11.6, 4.5, 2.6], [13.0, 6.7, 2.6]]:
			var pos := Vector3(side * r[0], r[1], 0)
			var width: float = r[2]
			MapLook.platform(col, Vector3(width, 0.3, 2.2), pos)
			MapLook.box(plat, Vector3(width + 0.1, 0.4, 2.2), pos + Vector3(0, -0.05, 0), sandstone)
			MapLook.box(plat, Vector3(width + 0.1, r[1] - 0.2, 1.4), Vector3(pos.x + side * 0.2, (r[1] - 0.2) / 2.0, -1.2),
				sandstone_dark)
			MapLook.box(plat, Vector3(width + 0.15, 0.06, 0.1), pos + Vector3(0, 0.16, 1.1), gold)
		var box := Vector3(side * 13.0, 6.7, 0)
		for k in [-1, 1]:
			MapLook.cylinder(plat, 0.08, 2.0, box + Vector3(k * 1.1, 1.0, -0.9), gold, -1.0, Vector3.ZERO, 8)
		MapLook.box(plat, Vector3(2.8, 0.12, 1.6), box + Vector3(0, 2.05, -0.5), red if side < 0 else blue)
		MapFX.cloth(plat, Vector2(0.8, 1.6), box + Vector3(side * 1.3, -0.9, 1.0), Color(0.75, 0.15, 0.1) if side < 0 \
			else Color(0.15, 0.3, 0.7), null, true, 0.12)
	# Obelisk auf der Kaiserloge rechts.
	MapLook.cylinder(plat, 0.25, 1.8, Vector3(13.6, 7.75, -0.7), sandstone, 0.12, Vector3(0, 45, 0), 4)
	MapLook.cylinder(plat, 0.12, 0.3, Vector3(13.6, 8.8, -0.7), gold, 0.0, Vector3(0, 45, 0), 4)

	# Dünen und Pyramiden.
	MapLook.box(bg, Vector3(140, 0.4, 70), Vector3(0, -0.3, -40), dune)
	for d in [[-26.0, -20.0, 9.0], [24.0, -18.0, 8.0], [-4.0, -32.0, 12.0], [30.0, -34.0, 11.0]]:
		MapLook.sphere(bg, d[2], Vector3(d[0], -d[2] * 0.75, d[1]), dune, Vector3(2.0, 1.0, 1.0))
	for py in [[-22.0, -40.0, 14.0], [-6.0, -50.0, 10.0]]:
		MapLook.cylinder(bg, py[2], py[2] * 0.9, Vector3(py[0], py[2] * 0.45, py[1]), sandstone_dark, 0.0, Vector3(0, 45, 0), 4)

	# Wehender Sand, flirrende Hitze, Geier.
	MapLook.particles(self, Vector3(-18.0, 1.5, 0), Vector3(1, 3.0, 3), Color(0.95, 0.8, 0.55, 0.7), 80,
		Vector3(9.0, 0.3, 0), 0.06, 4.5)
	MapLook.particles(self, Vector3(0, 3.0, -1.0), Vector3(14, 4, 2), Color(1.0, 0.95, 0.85, 0.2), 35,
		Vector3(0, 0.4, 0), 0.4, 4.0)
	fx.flock(Vector3(0, 12.0, -8.0), 3, Color(0.2, 0.15, 0.12), Vector3(9, 0.5, 4), 0.2, 0.5)
	MapLook.light(look, Vector3(0, 6.0, 4.0), Color(1.0, 0.95, 0.8), 0.9, 14.0)
	MapFX.mood(self, Color(1.0, 0.88, 0.7), 0.004, 0.2, 1.12, 1.12, 0.88)

	# Vordergrund: Sandsteinbrocken in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.box(fg, Vector3(0.9, 0.5, 0.4), Vector3(side * 2.05, -1.35, -3.0), sandstone_dark, Vector3(0, 0, side * 10.0))
		MapLook.sphere(fg, 0.35, Vector3(side * 1.6, -1.45, -3.0), dune, Vector3(1.8, 0.6, 0.6))
	MapLook.backdrop(bg, "res://assets/maps/wueste/hintergrund.png", -60.0, 180.0, 10.0)


## Gladiatorengänge unter der Arena: Sandsteingewölbe mit Fackeln, Gittertüren, Waffen und zwei Aufzügen,
## die von hier unten bis zum Arenaboden fahren. Außen führen Steinbalkone wieder hinauf.
func _hypogeum(col: Node3D, look: Node3D, plat: Node3D, sand: Material, stone: Material, dark: Material, red: Material,
		gold: Material) -> void:
	MapLook.solid(col, Vector3(BELOW_HALF * 2.0, 1.6, 4), Vector3(0, BELOW_Y - 0.8, 0))
	MapLook.box(look, Vector3(BELOW_HALF * 2.0 + 0.2, 0.4, 4.3), Vector3(0, BELOW_Y - 0.2, 0), sand)
	MapLook.box(look, Vector3(BELOW_HALF * 2.0, 1.4, 4.0), Vector3(0, BELOW_Y - 1.2, 0), dark)
	MapLook.cylinder(look, 1.0, 5.0, Vector3(0, BELOW_Y - 4.4, -0.5), dark, BELOW_HALF - 1.0, Vector3.ZERO, 16).scale = \
		Vector3(1.0, 1.0, 0.3)
	var h := -1.4 - BELOW_Y
	MapLook.box(look, Vector3(HALF * 2.0, h, 0.4), Vector3(0, BELOW_Y + h / 2.0, -2.0), dark)
	# Bögen an der Rückwand mit Gittertüren und Fackeln.
	var bars := MapLook.mat(Color(0.25, 0.22, 0.2), 0.5, 0.7)
	for i in 6:
		var x := -9.0 + i * 3.6
		MapLook.box(look, Vector3(0.5, h, 0.5), Vector3(x - 1.8, BELOW_Y + h / 2.0, -1.6), stone)
		MapLook.box(look, Vector3(1.8, 2.2, 0.1), Vector3(x, BELOW_Y + 1.1, -1.78), MapLook.mat(Color(0.12, 0.1, 0.08)))
		for k in 5:
			MapLook.box(look, Vector3(0.05, 2.2, 0.05), Vector3(x - 0.7 + k * 0.35, BELOW_Y + 1.1, -1.7), bars)
		if i % 2 == 0:
			MapLook.cylinder(look, 0.1, 0.25, Vector3(x + 1.2, BELOW_Y + 2.4, -1.65), gold, 0.18)
			MapLook.light(look, Vector3(x + 1.2, BELOW_Y + 2.7, -1.0), Color(1.0, 0.65, 0.3), 1.0, 4.5)
			MapLook.particles(look, Vector3(x + 1.2, BELOW_Y + 2.6, -1.65), Vector3(0.06, 0.02, 0.06),
				Color(1, 0.6, 0.2, 0.9), 12, Vector3(0, 0.9, 0), 0.08, 0.5)
	# Waffen und Fässer.
	MapLook.cylinder(look, 0.35, 0.8, Vector3(-11.6, BELOW_Y + 0.4, -1.3), MapLook.mat(Color(0.45, 0.3, 0.18)), 0.32)
	MapLook.cylinder(look, 0.35, 0.8, Vector3(10.8, BELOW_Y + 0.4, -1.4), MapLook.mat(Color(0.45, 0.3, 0.18)), 0.32)
	MapLook.cylinder(look, 0.3, 0.06, Vector3(-2.0, BELOW_Y + 0.6, -1.65), red, -1.0, Vector3(90, 0, 0), 16)
	MapLook.cylinder(look, 0.03, 1.4, Vector3(2.4, BELOW_Y + 0.7, -1.6), bars, -1.0, Vector3(0, 0, 25), 6)
	# Die beiden Aufzüge in ihren Schächten, gegeneinander versetzt.
	for side in [-1, 1]:
		var lift := MovingPlatform.create(plat, Vector3(LIFT_HALF * 2.0 - 0.1, 0.3, 2.4),
			Vector3(side * LIFT_X, BELOW_Y - 0.15, 0), Vector3(side * LIFT_X, -0.15, 0), 9.0, 0.0 if side < 0 else 0.5)
		MapLook.box(lift, Vector3(LIFT_HALF * 2.0 - 0.1, 0.3, 2.4), Vector3.ZERO, MapLook.mat(Color(0.45, 0.32, 0.2), 0.9))
		MapLook.box(lift, Vector3(LIFT_HALF * 2.0, 0.06, 2.45), Vector3(0, 0.16, 0), gold)
		for k in [-1, 1]:
			MapLook.cylinder(lift, 0.025, 5.0, Vector3(k * 0.8, 2.5, -1.0), bars, -1.0, Vector3.ZERO, 5)
		MapLook.box(look, Vector3(LIFT_HALF * 2.0 + 0.2, 0.1, 0.4), Vector3(side * LIFT_X, -0.05, 2.2), gold)
	# Steinbalkone außen, über die man aus den Gängen wieder hinaufkommt.
	for side in [-1, 1]:
		var pos := Vector3(side * 12.0, -2.4, 0)
		MapLook.platform(col, Vector3(2.2, 0.3, 2.0), pos)
		MapLook.box(plat, Vector3(2.3, 0.4, 2.1), pos + Vector3(0, -0.05, 0), stone)
		MapLook.box(plat, Vector3(0.8, 0.5, 0.8), pos + Vector3(side * 0.6, -0.5, -0.3), dark)
	MapLook.light(look, Vector3(0, BELOW_Y + 2.0, 1.5), Color(1.0, 0.8, 0.55), 0.8, 12.0)
