extends Node3D
## Dschungel-Ruinen: bemooster Steinboden einer alten Tempelanlage, Lianen und Moos.
## In der Mitte eine Stufenpyramide mit einem kleinen Schrein auf der Spitze, links ein Urwaldriese mit Ästen
## bis hinauf in die Baumkrone, rechts ein Felsvorsprung am Wasserfall. Unter dem Boden liegt eine Höhle mit
## Wasserbecken und Goldgötze, erreichbar über die Kanten und ein eingestürztes Loch im Boden.
## Ein Steinaufzug fährt außen von der Höhle bis zum Felsvorsprung. Papageien, Glühwürmchen und Sonnenstrahlen.

const HALF := 11.0
const CAVE_Y := -4.6
const CAVE_HALF := 13.5
## Eingestürztes Loch im Boden rechts (von HOLE_X1 bis HOLE_X2).
const HOLE_X1 := 6.4
const HOLE_X2 := 8.2


const D := "res://assets/maps/dschungel/"


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var stone_tex := MapFX.tex("moosstein")
	var stone: Material = MapFX.textured(stone_tex, MapFX.tex("moosstein_n"), Color.WHITE, 0.3) if stone_tex \
		else MapLook.mat(Color(0.5, 0.52, 0.45))
	var stone_dark := MapFX.surface("fels_dunkel", Color(0.32, 0.34, 0.3))
	var moss := MapFX.surface("moos", Color(0.28, 0.5, 0.18), 1.0)
	var leaf := MapFX.surface("blaetter", Color(0.18, 0.55, 0.2), 1.0)
	var leaf_light := MapFX.surface("blaetter", Color(0.35, 0.7, 0.25), 1.0)
	var vine := MapFX.surface("blaetter", Color(0.2, 0.42, 0.15), 1.0)
	var trunk := MapFX.surface("rinde", Color(0.35, 0.25, 0.18), 1.0)
	var water := MapLook.mat(Color(0.55, 0.85, 1.0, 0.7), 0.1, 0.0, 0.6)
	var gold := MapFX.surface("gold", Color(0.95, 0.75, 0.25), 0.3, 0.8)
	$Spawn1.position = Vector3(-6.0, 0.2, 0)
	$Spawn2.position = Vector3(5.0, 0.2, 0)
	MapLook.stage_area(self, Rect2(-CAVE_HALF, CAVE_Y, CAVE_HALF * 2.0, 7.6 - CAVE_Y), HALF)

	# Steinboden: 22 breit, rechts mit einem eingestürzten Loch. Moos an den Kanten.
	for piece in [[-HALF, HOLE_X1], [HOLE_X2, HALF]]:
		var w: float = piece[1] - piece[0]
		var cx: float = (piece[0] + piece[1]) / 2.0
		MapLook.solid(col, Vector3(w, 1.4, 4), Vector3(cx, -0.7, 0))
		MapLook.box(look, Vector3(w + 0.2, 0.6, 4.4), Vector3(cx, -0.3, 0), stone)
		MapLook.box(look, Vector3(w + 0.3, 0.08, 0.5), Vector3(cx, -0.02, 2.0), moss)
		MapLook.box(look, Vector3(w, 0.8, 4.0), Vector3(cx, -1.0, 0.1), stone_dark)
	MapLook.box(look, Vector3(1.2, 0.5, 0.8), Vector3(-9.4, 0.25, -1.4), stone, Vector3(0, 20, 12))
	MapLook.box(look, Vector3(0.8, 0.4, 0.6), Vector3(9.6, 0.2, -1.4), stone, Vector3(0, -30, -8))
	# Abgebrochene Steine am Loch.
	for side in [HOLE_X1, HOLE_X2]:
		MapLook.box(look, Vector3(0.6, 0.4, 0.6), Vector3(side, -1.2, 1.4), stone_dark, Vector3(20, 30, 25))

	_cave(col, look, plat, stone, stone_dark, moss, vine, water, gold)

	# Stufenpyramide in der Mitte: drei feste Stufen, oben ein kleiner Schrein mit begehbarem Dach.
	for st in [[8.0, 1.0], [5.6, 2.0], [3.2, 3.0]]:
		var w: float = st[0]
		var h: float = st[1]
		MapLook.solid(col, Vector3(w, h, 4), Vector3(0, h * 0.5, 0))
		MapLook.box(look, Vector3(w + 0.1, h, 4.1), Vector3(0, h * 0.5, 0), stone if int(h) % 2 else stone_dark)
		MapLook.box(look, Vector3(w + 0.15, 0.06, 4.15), Vector3(0, h, 0), moss)
		MapLook.cylinder(look, 0.03, 0.9, Vector3(w * 0.5 - 0.3, h - 0.45, 2.06), vine, 0.02, Vector3.ZERO, 5)
	var shrine := Vector3(0, 5.6, 0)
	MapLook.platform(col, Vector3(3.0, 0.3, 2.0), shrine)
	MapLook.box(plat, Vector3(3.3, 0.45, 2.4), shrine + Vector3(0, -0.1, -0.3), stone)
	MapLook.box(plat, Vector3(3.35, 0.06, 2.45), shrine + Vector3(0, 0.15, -0.3), moss)
	for side in [-1, 1]:
		MapLook.box(plat, Vector3(0.4, 2.4, 0.4), Vector3(side * 1.2, 4.2, -1.1), stone_dark)
	MapLook.box(look, Vector3(0.8, 0.6, 0.8), Vector3(0, 3.3, -1.3), stone_dark)
	MapLook.sphere(look, 0.32, Vector3(0, 3.95, -1.3), gold, Vector3(1.0, 1.2, 1.0))
	MapLook.light(look, Vector3(0, 4.0, -0.7), Color(1.0, 0.8, 0.4), 0.9, 3.5)

	# Urwaldriese links: Äste in drei Höhen bis hinauf in die Baumkrone.
	MapLook.cylinder(plat, 0.8, 11.0, Vector3(-10.6, 3.0, -1.2), trunk, 0.55, Vector3.ZERO, 10)
	for b in [[-8.2, 2.4, 2.8], [-11.4, 4.8, 2.6], [-8.6, 7.4, 3.4]]:
		var pos := Vector3(b[0], b[1], 0)
		var width: float = b[2]
		MapLook.platform(col, Vector3(width, 0.3, 1.8), pos)
		MapLook.cylinder(plat, 0.22, width + 0.4, pos + Vector3(0, -0.05, 0), trunk, 0.16, Vector3(0, 0, 90), 8)
		MapLook.box(plat, Vector3(width, 0.08, 1.6), pos + Vector3(0, 0.12, 0), MapFX.surface("holz", Color(0.4, 0.3, 0.2), 1.0))
		if not MapLook.sprite(plat, D + "busch_%d.png" % (1 + int(b[1]) % 2), pos + Vector3(width * 0.4, 0.05, -0.75), 1.0, b[0] > -9.0):
			MapLook.sphere(plat, 0.5, pos + Vector3(width * 0.45, 0.25, -0.4), leaf_light, Vector3(1.4, 0.6, 1.0))
		MapLook.cylinder(plat, 0.04, 1.3, pos + Vector3(-width * 0.3, -0.7, 0.6), vine, 0.02, Vector3.ZERO, 5)
	# Blätterkrone über dem obersten Ast.
	if not MapLook.sprite(plat, D + "krone.png", Vector3(-9.8, 6.6, -1.6), 5.5):
		MapLook.sphere(plat, 2.6, Vector3(-9.8, 9.4, -1.4), leaf, Vector3(1.6, 0.6, 1.0))
		MapLook.sphere(plat, 1.8, Vector3(-7.6, 8.9, -1.0), leaf_light, Vector3(1.4, 0.5, 1.0))
		MapLook.sphere(plat, 1.4, Vector3(-12.4, 8.6, -0.9), leaf_light, Vector3(1.4, 0.5, 1.0))

	# Felsvorsprung rechts am Wasserfall, hoch oben.
	var ledge := Vector3(9.2, 3.4, 0)
	MapLook.platform(col, Vector3(3.0, 0.3, 2.2), ledge)
	MapLook.box(plat, Vector3(3.1, 0.6, 2.3), ledge + Vector3(0, -0.15, 0), stone)
	MapLook.box(plat, Vector3(3.15, 0.06, 2.35), ledge + Vector3(0, 0.15, 0), moss)
	MapLook.box(plat, Vector3(2.4, 3.2, 1.2), ledge + Vector3(0.3, -2.0, -1.4), stone_dark)
	MapLook.box(plat, Vector3(1.2, 6.0, 0.15), ledge + Vector3(0.6, 2.5, -1.3), water)
	MapLook.particles(plat, ledge + Vector3(0.6, 0.0, -1.1), Vector3(0.5, 0.1, 0.2), Color(1, 1, 1, 0.8), 30,
		Vector3(0, 1.5, 0.6), 0.1, 0.8, Vector3(0, -5.0, 0))

	# Steinaufzug rechts außen: fährt von der Höhle bis hoch zum Felsvorsprung und wieder hinunter.
	var lift := MovingPlatform.create(plat, Vector3(2.0, 0.3, 2.0), Vector3(12.5, CAVE_Y - 0.15, 0),
		Vector3(12.5, 3.25, 0), 9.0)
	MapLook.box(lift, Vector3(2.0, 0.45, 2.0), Vector3(0, -0.08, 0), stone)
	MapLook.box(lift, Vector3(2.05, 0.06, 2.05), Vector3(0, 0.15, 0), moss)
	for side in [-1, 1]:
		MapLook.cylinder(lift, 0.03, 8.0, Vector3(side * 0.8, 4.0, -0.8), vine, -1.0, Vector3.ZERO, 5)
	MapLook.sphere(lift, 0.18, Vector3(0, -0.2, 1.0), gold)

	# Riesenblüte links am Boden: ein Sprungfeld, das bis zu den Ästen hochschleudert.
	var flower := BouncePad.create(plat, Vector3(1.2, 0.4, 2.0), Vector3(-5.6, 0.2, 0), 17.0)
	flower.visual = Node3D.new()
	flower.visual.position = Vector3(0, -0.2, 0)
	flower.add_child(flower.visual)
	var petal := MapLook.mat(Color(1.0, 0.35, 0.55), 0.8)
	for k in 6:
		var a := k * TAU / 6.0
		MapLook.sphere(flower.visual, 0.3, Vector3(cos(a) * 0.4, 0.05, sin(a) * 0.4), petal, Vector3(1.4, 0.35, 0.8))
	MapLook.sphere(flower.visual, 0.22, Vector3(0, 0.1, 0), MapLook.mat(Color(1.0, 0.85, 0.2), 0.6, 0.0, 0.8),
		Vector3(1, 0.5, 1))

	# Stufenpyramide und Wasserfall im Hintergrund.
	for i in 6:
		var w := 22.0 - i * 3.4
		MapLook.box(bg, Vector3(w, 1.6, w * 0.6), Vector3(-18.0, i * 1.6 + 0.8, -30.0), stone_dark if i % 2 else stone)
	MapLook.box(bg, Vector3(3.0, 2.4, 3.0), Vector3(-18.0, 10.8, -30.0), stone)
	MapLook.box(bg, Vector3(3.0, 16.0, 0.3), Vector3(19.0, 4.0, -24.0), water)
	MapLook.particles(bg, Vector3(19.0, -3.8, -23.5), Vector3(2.0, 0.3, 0.5), Color(1, 1, 1, 0.8), 60,
		Vector3(0, 3.0, 1.0), 0.15, 1.2, Vector3(0, -6.0, 0))
	MapLook.box(bg, Vector3(120, 0.4, 60), Vector3(0, -0.3, -30), MapFX.surface("gras", Color(0.2, 0.4, 0.16)))

	# Urwaldbäume mit großen Blätterkronen.
	var tree_i := 0
	for t in [[-15.5, -4.5, 1.3], [15.0, -5.0, 1.2], [-21.0, -12.0, 1.6], [22.0, -12.0, 1.7], [6.0, -16.0, 1.5], [-7.0, -18.0, 1.4]]:
		var base := Vector3(t[0], 0.0, t[1])
		var s: float = t[2]
		tree_i += 1
		if MapLook.sprite(bg, D + "baum_%d.png" % (1 + tree_i % 3), base + Vector3(0, -0.15, 0), 8.5 * s, t[0] > 0.0,
				Color(0.92, 0.97, 0.92)):
			continue
		MapLook.cylinder(bg, 0.35 * s, 7.0 * s, base + Vector3(0, 3.5 * s, 0), trunk, 0.25 * s, Vector3.ZERO, 8)
		MapLook.sphere(bg, 2.2 * s, base + Vector3(0, 7.2 * s, 0), leaf, Vector3(1.4, 0.7, 1.2))
		MapLook.sphere(bg, 1.6 * s, base + Vector3(1.6 * s, 6.6 * s, 0.4), leaf_light, Vector3(1.3, 0.7, 1.1))
		MapLook.sphere(bg, 1.5 * s, base + Vector3(-1.6 * s, 6.4 * s, 0.3), leaf_light, Vector3(1.3, 0.7, 1.1))
	for x in [-6.8, 10.4]:
		if not MapLook.sprite(look, D + "busch_%d.png" % (1 if x < 0 else 2), Vector3(x, -0.05, -1.7), 1.6, x > 0.0):
			MapLook.sphere(look, 0.9, Vector3(x, 0.4, -1.6), leaf, Vector3(1.4, 0.7, 0.9))

	# Papageien, Glühwürmchen, Sonnenstrahlen und Dunst.
	fx.flock(Vector3(0, 11.0, -6.0), 3, Color(0.95, 0.2, 0.15), Vector3(10, 0.8, 4), 0.4, 0.35)
	fx.flock(Vector3(2.0, 12.0, -8.0), 3, Color(0.2, 0.5, 1.0), Vector3(12, 0.8, 4), -0.35, 0.35)
	MapLook.particles(self, Vector3(0, 2.0, 0), Vector3(13, 5, 3), Color(0.9, 1.0, 0.4, 1.0), 45,
		Vector3(0.2, 0.3, 0), 0.05, 5.0)
	for x in [-8.0, -1.0, 6.5]:
		MapLook.box(bg, Vector3(1.5, 18.0, 0.05), Vector3(x, 6.0, -4.0), MapLook.mat(Color(1.0, 0.95, 0.7, 0.05), 1.0, 0.0, 0.3),
			Vector3(0, 0, -18))
	MapLook.light(look, Vector3(0, 6.0, 4.0), Color(1.0, 0.95, 0.8), 0.8, 14.0)
	MapFX.mood(self, Color(0.6, 0.8, 0.6), 0.005, 0.2, 1.2, 1.12, 0.9)

	# Vordergrund: große Blätter in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		if MapLook.sprite(fg, D + "busch_%d.png" % (1 if side < 0 else 2), Vector3(side * 1.95, -1.65, -3.0), 0.8, side < 0):
			continue
		MapLook.sphere(fg, 0.5, Vector3(side * 2.05, -1.32, -3.0), leaf, Vector3(1.6, 0.5, 0.4))
		MapLook.sphere(fg, 0.35, Vector3(side * 1.6, -1.4, -3.0), leaf_light, Vector3(1.6, 0.5, 0.4))
	MapLook.backdrop(bg, "res://assets/maps/dschungel/hintergrund.png", -60.0, 180.0, 10.0)


## Höhle unter den Ruinen: Felswände, Tropfsteine, ein Wasserbecken, leuchtende Pilze und ein goldener Götze.
## Im eingestürzten Loch hängen Lianen, eine Wurzel hilft beim Hochspringen.
func _cave(col: Node3D, look: Node3D, plat: Node3D, stone: Material, dark: Material, moss: Material, vine: Material,
		water: Material, gold: Material) -> void:
	MapLook.solid(col, Vector3(CAVE_HALF * 2.0, 1.6, 4), Vector3(0, CAVE_Y - 0.8, 0))
	MapLook.box(look, Vector3(CAVE_HALF * 2.0 + 0.2, 0.5, 4.3), Vector3(0, CAVE_Y - 0.25, 0), stone)
	MapLook.box(look, Vector3(CAVE_HALF * 2.0 + 0.3, 0.06, 0.4), Vector3(0, CAVE_Y - 0.02, 2.0), moss)
	var rock := MapLook.mat(Color(0.26, 0.24, 0.22), 1.0)
	MapLook.box(look, Vector3(CAVE_HALF * 2.0 - 1.0, 2.2, 4.0), Vector3(0, CAVE_Y - 2.6, 0), rock)
	MapLook.cylinder(look, 1.0, 5.0, Vector3(0, CAVE_Y - 6.2, -0.4), rock, CAVE_HALF - 1.0, Vector3.ZERO, 16).scale = \
		Vector3(1.0, 1.0, 0.3)
	var h := -1.4 - CAVE_Y
	MapLook.box(look, Vector3(HALF * 2.0, h, 0.4), Vector3(0, CAVE_Y + h / 2.0, -2.0), rock)
	# Tropfsteine von der Decke.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 12:
		var x := rng.randf_range(-10.0, 10.0)
		if x > HOLE_X1 - 0.5 and x < HOLE_X2 + 0.5:
			continue
		var len := rng.randf_range(0.4, 1.0)
		MapLook.cylinder(look, 0.0, len, Vector3(x, -1.4 - len / 2.0, rng.randf_range(-1.8, -1.0)), dark, 0.2, Vector3.ZERO, 6)
	# Wasserbecken in der Mitte (nur zum Anschauen) mit Lichtspiegelung.
	MapLook.box(look, Vector3(6.0, 0.04, 2.6), Vector3(-1.0, CAVE_Y + 0.02, -0.4), water)
	MapLook.light(look, Vector3(-1.0, CAVE_Y + 0.6, 0.3), Color(0.4, 0.8, 1.0), 1.0, 5.0)
	MapLook.particles(look, Vector3(-1.0, CAVE_Y + 0.3, -0.4), Vector3(2.8, 0.1, 1.0), Color(0.6, 0.9, 1.0, 0.6), 15,
		Vector3(0, 0.3, 0), 0.05, 2.0)
	# Leuchtende Pilze.
	var glow := MapLook.mat(Color(0.4, 1.0, 0.7), 0.6, 0.0, 2.5)
	for x in [-9.0, -6.5, 3.4, 9.6, 11.8]:
		MapLook.cylinder(look, 0.05, 0.35, Vector3(x, CAVE_Y + 0.17, -1.4), MapLook.mat(Color(0.9, 0.9, 0.8)), -1.0)
		MapLook.sphere(look, 0.2, Vector3(x, CAVE_Y + 0.38, -1.4), glow, Vector3(1.2, 0.5, 1.2))
		MapLook.light(look, Vector3(x, CAVE_Y + 0.6, -1.0), Color(0.4, 1.0, 0.7), 0.6, 2.5)
	# Goldener Götze auf einem Sockel links.
	MapLook.box(look, Vector3(0.9, 0.8, 0.9), Vector3(-4.2, CAVE_Y + 0.4, -1.5), dark)
	MapLook.box(look, Vector3(0.5, 0.7, 0.4), Vector3(-4.2, CAVE_Y + 1.15, -1.5), gold)
	MapLook.sphere(look, 0.22, Vector3(-4.2, CAVE_Y + 1.7, -1.5), gold)
	MapLook.light(look, Vector3(-4.2, CAVE_Y + 1.4, -0.8), Color(1.0, 0.8, 0.4), 0.9, 3.5)
	# Lianen und eine Wurzel im eingestürzten Loch.
	var hole := (HOLE_X1 + HOLE_X2) / 2.0
	for k in 3:
		MapLook.cylinder(look, 0.035, 2.4 + k * 0.4, Vector3(hole - 0.5 + k * 0.5, -1.4 - k * 0.2, -0.9), vine, 0.02,
			Vector3.ZERO, 5)
	var root := Vector3(hole, -2.3, 0)
	MapLook.platform(col, Vector3(HOLE_X2 - HOLE_X1 - 0.2, 0.3, 1.8), root)
	MapLook.cylinder(plat, 0.18, HOLE_X2 - HOLE_X1 + 0.4, root, MapLook.mat(Color(0.35, 0.25, 0.18), 1.0), 0.12,
		Vector3(0, 0, 90), 8)
	MapLook.light(look, Vector3(hole, -0.5, 1.0), Color(1.0, 0.95, 0.7), 0.8, 4.0)
