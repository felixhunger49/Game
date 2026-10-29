extends Node3D
## Wüstenarena: Sandboden in einem alten Kolosseum aus Sandstein, umgestürzte Säulen und Fahnen,
## dahinter Dünen und Pyramiden. Eine abgesenkte Sandgrube in der Mitte und vier treppenartig versetzte Säulen.
## Grelle Mittagssonne, flirrende Hitze und wehender Sand.


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
	var sandstone_dark := MapLook.mat(Color(0.65, 0.5, 0.33))
	var red := MapLook.mat(Color(0.75, 0.15, 0.1), 0.8)
	var blue := MapLook.mat(Color(0.15, 0.3, 0.7), 0.8)
	var gold := MapLook.mat(Color(0.95, 0.75, 0.3), 0.3, 0.8)
	var dune := MapLook.mat(Color(0.95, 0.78, 0.5), 1.0)
	$Spawn1.position = Vector3(-4.5, 0.2, 0)
	$Spawn2.position = Vector3(4.5, 0.2, 0)

	# Arenaboden aus Sand mit einer abgesenkten Sandgrube in der Mitte, eingefasst mit Sandstein.
	for f in [[-4.75, 5.5], [4.75, 5.5]]:
		MapLook.solid(col, Vector3(f[1], 2.2, 4), Vector3(f[0], -1.1, 0))
		MapLook.box(look, Vector3(f[1], 0.5, 4.2), Vector3(f[0], -0.25, 0), sand)
	MapLook.solid(col, Vector3(4.0, 2.2, 4), Vector3(0, -1.9, 0))
	MapLook.box(look, Vector3(4.0, 0.5, 4.2), Vector3(0, -1.05, 0), sand)
	for side in [-1, 1]:
		MapLook.box(look, Vector3(0.3, 0.85, 4.2), Vector3(side * 2.05, -0.4, 0), sandstone_dark)
	MapLook.box(look, Vector3(15.6, 0.7, 0.4), Vector3(0, -0.2, 2.2), sandstone)
	MapLook.box(look, Vector3(15.6, 1.8, 4.6), Vector3(0, -2.0, 0), sandstone_dark)
	# Knochen und ein alter Helm in der Grube.
	MapLook.cylinder(look, 0.06, 0.8, Vector3(-0.8, -0.75, -0.8), MapLook.mat(Color(0.95, 0.92, 0.85)), -1.0, Vector3(0, 30, 90), 6)
	MapLook.sphere(look, 0.25, Vector3(0.9, -0.7, -1.0), gold, Vector3(1.0, 0.7, 1.0))

	# Kolosseumsmauer hinten: Bögen in zwei Stockwerken, Fahnen, umgestürzte Säulen.
	MapLook.box(look, Vector3(17.0, 0.5, 0.8), Vector3(0, 0.25, -2.3), sandstone)
	for i in 8:
		var x := -8.4 + i * 2.4
		MapLook.box(bg, Vector3(0.7, 6.0, 1.0), Vector3(x, 3.0, -6.0), sandstone)
		MapLook.box(bg, Vector3(0.6, 3.5, 0.9), Vector3(x, 7.8, -6.2), sandstone)
	MapLook.box(bg, Vector3(19.0, 0.8, 1.2), Vector3(0, 6.2, -6.0), sandstone)
	MapLook.box(bg, Vector3(19.0, 0.6, 1.0), Vector3(0, 9.8, -6.2), sandstone)
	MapLook.box(bg, Vector3(19.0, 9.6, 0.4), Vector3(0, 4.8, -6.8), sandstone_dark)
	for i in 4:
		var x := -6.0 + i * 4.0
		MapFX.cloth(bg, Vector2(1.0, 2.4), Vector3(x, 8.4, -5.6), Color(0.75, 0.15, 0.1) if i % 2 == 0 else Color(0.15, 0.3, 0.7),
			null, true, 0.15)
	MapLook.cylinder(look, 0.4, 3.0, Vector3(-3.8, 0.4, -1.5), sandstone, -1.0, Vector3(0, 30, 90), 10)
	# Waffenständer mit Schilden.
	for x in [3.6]:
		MapLook.box(look, Vector3(1.2, 0.12, 0.12), Vector3(x, 1.0, -1.8), sandstone_dark)
		MapLook.cylinder(look, 0.32, 0.06, Vector3(x - 0.3, 0.75, -1.72), red, -1.0, Vector3(90, 0, 0), 16)
		MapLook.cylinder(look, 0.32, 0.06, Vector3(x + 0.35, 0.75, -1.72), blue, -1.0, Vector3(90, 0, 0), 16)
		MapLook.sphere(look, 0.08, Vector3(x - 0.3, 0.75, -1.66), gold)
		MapLook.sphere(look, 0.08, Vector3(x + 0.35, 0.75, -1.66), gold)

	# Vier Säulen-Plattformen, treppenartig versetzt: links unten, Mitte links hoch, Mitte rechts, rechts ganz oben.
	for p in [[-6.0, 1.8, 2.2], [-2.6, 3.6, 2.4], [2.4, 2.6, 2.4], [5.9, 4.4, 2.2]]:
		var pos := Vector3(p[0], p[1], 0)
		var width: float = p[2]
		MapLook.platform(col, Vector3(width, 0.3, 2.2), pos)
		MapLook.box(plat, Vector3(width + 0.1, 0.5, 2.2), pos + Vector3(0, -0.1, 0), sandstone)
		MapLook.box(plat, Vector3(width + 0.2, 0.08, 2.3), pos + Vector3(0, -0.38, 0), gold)
		var h: float = p[1] - 0.35
		MapLook.cylinder(plat, 0.36, h, Vector3(p[0], h * 0.5, -0.6), sandstone_dark, 0.3, Vector3.ZERO, 10)
	# Obelisk auf der höchsten Säule.
	MapLook.cylinder(plat, 0.25, 1.8, Vector3(6.5, 5.45, -0.7), sandstone, 0.12, Vector3(0, 45, 0), 4)
	MapLook.cylinder(plat, 0.12, 0.3, Vector3(6.5, 6.5, -0.7), gold, 0.0, Vector3(0, 45, 0), 4)

	# Dünen und Pyramiden.
	MapLook.box(bg, Vector3(140, 0.4, 70), Vector3(0, -0.3, -40), dune)
	for d in [[-20.0, -18.0, 9.0], [18.0, -16.0, 8.0], [-4.0, -30.0, 12.0], [26.0, -32.0, 11.0]]:
		MapLook.sphere(bg, d[2], Vector3(d[0], -d[2] * 0.75, d[1]), dune, Vector3(2.0, 1.0, 1.0))
	for py in [[-22.0, -40.0, 14.0], [-6.0, -50.0, 10.0]]:
		MapLook.cylinder(bg, py[2], py[2] * 0.9, Vector3(py[0], py[2] * 0.45, py[1]), sandstone_dark, 0.0, Vector3(0, 45, 0), 4)

	# Wehender Sand, flirrende Hitze, Geier.
	MapLook.particles(self, Vector3(-14.0, 1.5, 0), Vector3(1, 1.5, 3), Color(0.95, 0.8, 0.55, 0.7), 60,
		Vector3(9.0, 0.3, 0), 0.06, 3.5)
	MapLook.particles(self, Vector3(0, 3.0, -1.0), Vector3(10, 3, 2), Color(1.0, 0.95, 0.85, 0.2), 25,
		Vector3(0, 0.4, 0), 0.4, 4.0)
	fx.flock(Vector3(0, 12.0, -8.0), 3, Color(0.2, 0.15, 0.12), Vector3(9, 0.5, 4), 0.2, 0.5)
	MapLook.light(look, Vector3(0, 6.0, 4.0), Color(1.0, 0.95, 0.8), 0.9, 14.0)
	MapFX.mood(self, Color(1.0, 0.88, 0.7), 0.004, 0.2, 1.12, 1.12, 0.88)

	# Vordergrund: Sandsteinbrocken in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.box(fg, Vector3(0.9, 0.5, 0.4), Vector3(side * 2.05, -1.35, -3.0), sandstone_dark, Vector3(0, 0, side * 10.0))
		MapLook.sphere(fg, 0.35, Vector3(side * 1.6, -1.45, -3.0), dune, Vector3(1.8, 0.6, 0.6))
	MapLook.backdrop(bg, "res://assets/maps/wueste/hintergrund.png")
