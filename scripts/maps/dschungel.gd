extends Node3D
## Dschungel-Ruinen: bemooster Steinboden einer alten Tempelanlage, Lianen und Moos,
## dahinter eine Stufenpyramide und ein Wasserfall. Tempelstufen in der Mitte, Baumäste, ein Felsvorsprung,
## ein Steinaufzug, der hoch und runter fährt, und ein hoher Steinbogen. Papageien, Glühwürmchen und Sonnenstrahlen.


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var stone_tex := MapFX.tex("moosstein")
	var stone: Material = MapFX.textured(stone_tex, MapFX.tex("moosstein_n"), Color.WHITE, 0.3) if stone_tex \
		else MapLook.mat(Color(0.5, 0.52, 0.45))
	var stone_dark := MapLook.mat(Color(0.32, 0.34, 0.3))
	var moss := MapLook.mat(Color(0.28, 0.5, 0.18), 1.0)
	var leaf := MapLook.mat(Color(0.18, 0.55, 0.2), 1.0)
	var leaf_light := MapLook.mat(Color(0.35, 0.7, 0.25), 1.0)
	var vine := MapLook.mat(Color(0.2, 0.42, 0.15), 1.0)
	var trunk := MapLook.mat(Color(0.35, 0.25, 0.18), 1.0)
	var water := MapLook.mat(Color(0.55, 0.85, 1.0, 0.7), 0.1, 0.0, 0.6)
	var gold := MapLook.mat(Color(0.95, 0.75, 0.25), 0.3, 0.8)
	$Spawn1.position = Vector3(-4.8, 0.2, 0)
	$Spawn2.position = Vector3(4.8, 0.2, 0)

	# Steinboden: 15 breit, Moos an den Kanten, Treppenstufen darunter.
	MapLook.solid(col, Vector3(15, 2.2, 4), Vector3(0, -1.1, 0))
	MapLook.box(look, Vector3(15.4, 0.6, 4.4), Vector3(0, -0.3, 0), stone)
	MapLook.box(look, Vector3(15.5, 0.08, 0.5), Vector3(0, -0.02, 2.0), moss)
	MapLook.box(look, Vector3(14.6, 0.7, 4.0), Vector3(0, -0.95, 0.3), stone_dark)
	MapLook.box(look, Vector3(13.4, 0.9, 3.6), Vector3(0, -1.7, 0.6), stone_dark)
	MapLook.box(look, Vector3(1.2, 0.5, 0.8), Vector3(-4.4, 0.25, -1.4), stone, Vector3(0, 20, 12))
	MapLook.box(look, Vector3(0.8, 0.4, 0.6), Vector3(5.6, 0.2, -1.4), stone, Vector3(0, -30, -8))

	# Tempelstufen in der Mitte: zwei feste Stufen übereinander, oben ein Altar.
	for st in [[6.0, 0.7], [3.4, 1.4]]:
		var w: float = st[0]
		var h: float = st[1]
		MapLook.solid(col, Vector3(w, h, 4), Vector3(0, h * 0.5, 0))
		MapLook.box(look, Vector3(w + 0.1, h, 4.1), Vector3(0, h * 0.5, 0), stone)
		MapLook.box(look, Vector3(w + 0.15, 0.06, 4.15), Vector3(0, h, 0), moss)
	MapLook.box(look, Vector3(0.8, 0.6, 0.8), Vector3(0, 1.7, -1.4), stone_dark)
	MapLook.sphere(look, 0.32, Vector3(0, 2.35, -1.4), gold, Vector3(1.0, 1.2, 1.0))
	MapLook.light(look, Vector3(0, 2.4, -0.8), Color(1.0, 0.8, 0.4), 0.8, 3.0)

	# Baumäste links: ein niedriger und ein hoher Ast an einem dicken Urwaldbaum.
	MapLook.cylinder(plat, 0.6, 9.0, Vector3(-7.4, 3.5, -1.0), trunk, 0.45, Vector3.ZERO, 10)
	MapLook.sphere(plat, 2.6, Vector3(-7.4, 8.4, -1.2), leaf, Vector3(1.4, 0.6, 1.0))
	for b in [[-5.6, 2.4, 2.8], [-3.4, 4.4, 2.2]]:
		var pos := Vector3(b[0], b[1], 0)
		var width: float = b[2]
		MapLook.platform(col, Vector3(width, 0.3, 1.8), pos)
		MapLook.cylinder(plat, 0.22, width + 0.4, pos + Vector3(0, -0.05, 0), trunk, 0.16, Vector3(0, 0, 90), 8)
		MapLook.box(plat, Vector3(width, 0.08, 1.6), pos + Vector3(0, 0.12, 0), MapLook.mat(Color(0.4, 0.3, 0.2), 1.0))
		MapLook.sphere(plat, 0.5, pos + Vector3(width * 0.45, 0.25, -0.4), leaf_light, Vector3(1.4, 0.6, 1.0))
		MapLook.cylinder(plat, 0.04, 1.3, pos + Vector3(-width * 0.3, -0.7, 0.6), vine, 0.02, Vector3.ZERO, 5)
	MapLook.cylinder(plat, 0.2, 2.4, Vector3(-4.6, 3.4, -0.4), trunk, 0.14, Vector3(0, 0, 55), 8)

	# Felsvorsprung rechts am Wasserfall, hoch oben.
	var ledge := Vector3(5.8, 3.4, 0)
	MapLook.platform(col, Vector3(3.0, 0.3, 2.2), ledge)
	MapLook.box(plat, Vector3(3.1, 0.6, 2.3), ledge + Vector3(0, -0.15, 0), stone)
	MapLook.box(plat, Vector3(3.15, 0.06, 2.35), ledge + Vector3(0, 0.15, 0), moss)
	MapLook.box(plat, Vector3(2.4, 3.2, 1.2), ledge + Vector3(0.3, -2.0, -1.4), stone_dark)
	MapLook.box(plat, Vector3(1.2, 6.0, 0.15), ledge + Vector3(0.6, 2.5, -1.3), water)
	MapLook.particles(plat, ledge + Vector3(0.6, 0.0, -1.1), Vector3(0.5, 0.1, 0.2), Color(1, 1, 1, 0.8), 30,
		Vector3(0, 1.5, 0.6), 0.1, 0.8, Vector3(0, -5.0, 0))

	# Steinaufzug zwischen Stufen und Felsvorsprung: fährt hoch und runter.
	var lift := MovingPlatform.create(plat, Vector3(2.0, 0.3, 2.0), Vector3(3.3, 1.6, 0), Vector3(3.3, 4.6, 0), 7.0)
	MapLook.box(lift, Vector3(2.0, 0.45, 2.0), Vector3(0, -0.08, 0), stone)
	MapLook.box(lift, Vector3(2.05, 0.06, 2.05), Vector3(0, 0.15, 0), moss)
	for side in [-1, 1]:
		MapLook.cylinder(lift, 0.03, 6.0, Vector3(side * 0.8, 3.0, -0.8), vine, -1.0, Vector3.ZERO, 5)
	MapLook.sphere(lift, 0.18, Vector3(0, -0.2, 1.0), gold)

	# Riesenblüte auf der unteren Stufe: ein Sprungfeld, das bis zu den Ästen hochschleudert.
	var flower := BouncePad.create(plat, Vector3(1.2, 0.4, 2.0), Vector3(-2.4, 0.9, 0), 17.0)
	flower.visual = Node3D.new()
	flower.visual.position = Vector3(0, -0.2, 0)
	flower.add_child(flower.visual)
	var petal := MapLook.mat(Color(1.0, 0.35, 0.55), 0.8)
	for k in 6:
		var a := k * TAU / 6.0
		MapLook.sphere(flower.visual, 0.3, Vector3(cos(a) * 0.4, 0.05, sin(a) * 0.4), petal, Vector3(1.4, 0.35, 0.8))
	MapLook.sphere(flower.visual, 0.22, Vector3(0, 0.1, 0), MapLook.mat(Color(1.0, 0.85, 0.2), 0.6, 0.0, 0.8),
		Vector3(1, 0.5, 1))

	# Hoher Steinbogen über den Stufen.
	var top := Vector3(-0.4, 5.6, 0)
	MapLook.platform(col, Vector3(2.6, 0.3, 1.8), top)
	MapLook.box(plat, Vector3(2.8, 0.5, 1.8), top + Vector3(0, -0.1, -0.2), stone)
	MapLook.box(plat, Vector3(2.85, 0.06, 1.85), top + Vector3(0, 0.15, -0.2), moss)
	MapLook.cylinder(plat, 0.05, 2.4, top + Vector3(0.9, -1.3, 0.7), vine, 0.03, Vector3.ZERO, 5)
	MapLook.box(plat, Vector3(0.6, 4.0, 0.7), Vector3(-1.5, 3.4, -1.3), stone_dark)
	MapLook.box(plat, Vector3(0.6, 4.0, 0.7), Vector3(0.7, 3.4, -1.3), stone_dark)

	# Stufenpyramide und Wasserfall im Hintergrund.
	for i in 6:
		var w := 22.0 - i * 3.4
		MapLook.box(bg, Vector3(w, 1.6, w * 0.6), Vector3(-14.0, i * 1.6 + 0.8, -26.0), stone_dark if i % 2 else stone)
	MapLook.box(bg, Vector3(3.0, 2.4, 3.0), Vector3(-14.0, 10.8, -26.0), stone)
	MapLook.box(bg, Vector3(3.0, 16.0, 0.3), Vector3(14.0, 4.0, -20.0), water)
	MapLook.particles(bg, Vector3(14.0, -3.8, -19.5), Vector3(2.0, 0.3, 0.5), Color(1, 1, 1, 0.8), 60,
		Vector3(0, 3.0, 1.0), 0.15, 1.2, Vector3(0, -6.0, 0))
	MapLook.box(bg, Vector3(120, 0.4, 60), Vector3(0, -0.3, -30), MapLook.mat(Color(0.2, 0.4, 0.16)))

	# Urwaldbäume mit großen Blätterkronen.
	for t in [[-10.5, -3.5, 1.3], [10.0, -4.0, 1.2], [-17.0, -12.0, 1.6], [18.0, -12.0, 1.7], [5.0, -16.0, 1.5], [-6.0, -18.0, 1.4]]:
		var base := Vector3(t[0], 0.0, t[1])
		var s: float = t[2]
		MapLook.cylinder(bg, 0.35 * s, 7.0 * s, base + Vector3(0, 3.5 * s, 0), trunk, 0.25 * s, Vector3.ZERO, 8)
		MapLook.sphere(bg, 2.2 * s, base + Vector3(0, 7.2 * s, 0), leaf, Vector3(1.4, 0.7, 1.2))
		MapLook.sphere(bg, 1.6 * s, base + Vector3(1.6 * s, 6.6 * s, 0.4), leaf_light, Vector3(1.3, 0.7, 1.1))
		MapLook.sphere(bg, 1.5 * s, base + Vector3(-1.6 * s, 6.4 * s, 0.3), leaf_light, Vector3(1.3, 0.7, 1.1))
	for x in [-8.6, 8.4]:
		MapLook.sphere(look, 0.9, Vector3(x, 0.4, -1.6), leaf, Vector3(1.4, 0.7, 0.9))

	# Papageien, Glühwürmchen, Sonnenstrahlen und Dunst.
	fx.flock(Vector3(0, 9.0, -6.0), 3, Color(0.95, 0.2, 0.15), Vector3(10, 0.8, 4), 0.4, 0.35)
	fx.flock(Vector3(2.0, 10.0, -8.0), 3, Color(0.2, 0.5, 1.0), Vector3(12, 0.8, 4), -0.35, 0.35)
	MapLook.particles(self, Vector3(0, 3.0, 0), Vector3(10, 3, 3), Color(0.9, 1.0, 0.4, 1.0), 30,
		Vector3(0.2, 0.3, 0), 0.05, 5.0)
	for x in [-6.0, -1.0, 4.5]:
		MapLook.box(bg, Vector3(1.5, 18.0, 0.05), Vector3(x, 6.0, -4.0), MapLook.mat(Color(1.0, 0.95, 0.7, 0.05), 1.0, 0.0, 0.3),
			Vector3(0, 0, -18))
	MapLook.light(look, Vector3(0, 6.0, 4.0), Color(1.0, 0.95, 0.8), 0.8, 14.0)
	MapFX.mood(self, Color(0.6, 0.8, 0.6), 0.005, 0.2, 1.2, 1.12, 0.9)

	# Vordergrund: große Blätter in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.sphere(fg, 0.5, Vector3(side * 2.05, -1.32, -3.0), leaf, Vector3(1.6, 0.5, 0.4))
		MapLook.sphere(fg, 0.35, Vector3(side * 1.6, -1.4, -3.0), leaf_light, Vector3(1.6, 0.5, 0.4))
	MapLook.backdrop(bg, "res://assets/maps/dschungel/hintergrund.png")
