extends Node3D
## Unterwasser-Kuppel: große Arena unter einer Glaskuppel am Meeresgrund. Boden aus hellem Stein mit Korallen,
## draußen Riffe, Seetang, Fischschwärme und ein Wrack. Drei Luken im Boden führen hinunter in den Maschinenraum
## mit leuchtendem Reaktor (durch eine Luke fällt man mit 2× Runter). Zwei schwebende Korallenfelsen,
## Korallen-Vorsprünge, außen zwei Blasenröhren, die nach oben tragen, oben ein langer Glasröhren-Gang
## und ganz oben die Beobachtungskuppel. Aufsteigende Blasen und Lichtstrahlen von der Oberfläche.

const HALF := 12.0
const ENGINE_Y := -4.8
## Die drei Luken im Boden: Mitte und halbe Breite.
const HATCHES := [[-8.0, 1.0], [0.0, 1.3], [8.0, 1.0]]


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var floor_tex := MapFX.tex("korallen")
	var floor_mat: Material = MapFX.textured(floor_tex, MapFX.tex("korallen_n"), Color.WHITE, 0.3) if floor_tex \
		else MapLook.mat(Color(0.75, 0.82, 0.85))
	var steel := MapLook.mat(Color(0.55, 0.6, 0.65), 0.35, 0.8)
	var glass := MapLook.mat(Color(0.7, 0.9, 1.0, 0.18), 0.05, 0.0, 0.2)
	var glass_edge := MapLook.mat(Color(0.5, 0.95, 1.0), 0.3, 0.0, 2.0)
	var coral_pink := MapLook.mat(Color(1.0, 0.45, 0.55), 0.8)
	var coral_orange := MapLook.mat(Color(1.0, 0.6, 0.25), 0.8)
	var coral_purple := MapLook.mat(Color(0.65, 0.35, 0.9), 0.8)
	var kelp := MapLook.mat(Color(0.25, 0.55, 0.3), 1.0)
	var seabed := MapLook.mat(Color(0.75, 0.7, 0.55), 1.0)
	var wreck := MapLook.mat(Color(0.3, 0.25, 0.2), 1.0)
	$Spawn1.position = Vector3(-4.0, 0.2, 0)
	$Spawn2.position = Vector3(4.0, 0.2, 0)
	MapLook.stage_area(self, Rect2(-HALF - 0.6, ENGINE_Y, HALF * 2.0 + 1.2, 9.6 - ENGINE_Y), HALF)

	# Boden: 24 breit mit drei Luken, Stahlring und leuchtende Kante.
	var edges := [-HALF]
	for h in HATCHES:
		edges.append(h[0] - h[1])
		edges.append(h[0] + h[1])
	edges.append(HALF)
	for i in range(0, edges.size(), 2):
		var w: float = edges[i + 1] - edges[i]
		var cx: float = (edges[i] + edges[i + 1]) / 2.0
		MapLook.solid(col, Vector3(w, 1.4, 4), Vector3(cx, -0.7, 0))
		MapLook.box(look, Vector3(w, 0.6, 4.4), Vector3(cx, -0.3, 0), floor_mat)
		MapLook.box(look, Vector3(w, 0.12, 4.6), Vector3(cx, -0.62, 0), steel)
		MapLook.box(look, Vector3(w, 0.05, 0.06), Vector3(cx, -0.02, 2.2), glass_edge)
		MapLook.box(look, Vector3(w, 0.8, 4.0), Vector3(cx, -1.0, 0), steel)
	# Die Luken: Stahlgitter, auf denen man stehen kann (mit 2× Runter fällt man hindurch), mit leuchtendem Ring.
	for h in HATCHES:
		var x: float = h[0]
		var w: float = h[1] * 2.0
		MapLook.platform(col, Vector3(w, 0.3, 3.0), Vector3(x, -0.15, 0))
		MapLook.box(plat, Vector3(w, 0.12, 3.0), Vector3(x, -0.08, 0), MapLook.mat(Color(0.2, 0.25, 0.3), 0.4, 0.8))
		for k in 4:
			MapLook.box(plat, Vector3(w, 0.04, 0.08), Vector3(x, -0.01, -1.1 + k * 0.75), steel)
		MapLook.box(plat, Vector3(w + 0.1, 0.05, 0.08), Vector3(x, 0.0, 1.5), glass_edge)

	_engine_room(col, look, plat, steel, glass_edge, floor_mat)

	# Glaskuppel: Rippen aus Stahl und eine durchsichtige Halbkugel hinter der Arena.
	var dome := MapLook.sphere(bg, 16.0, Vector3(0, -1.0, -9.0), glass, Vector3(1.0, 0.8, 0.45))
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 9:
		var angle := -80.0 + i * 20.0
		var rib := Node3D.new()
		rib.position = Vector3(0, -1.0, -9.2)
		rib.rotation_degrees = Vector3(0, 0, angle)
		bg.add_child(rib)
		MapLook.box(rib, Vector3(0.22, 13.5, 0.22), Vector3(0, 6.75, 0), steel)
	MapLook.cylinder(bg, 16.2, 0.3, Vector3(0, -0.9, -9.0), steel, -1.0, Vector3.ZERO, 48)

	# Korallen und Seetang innen am Rand.
	for c in [[-10.8, coral_pink], [-5.8, coral_orange], [5.4, coral_purple], [10.6, coral_pink], [-2.6, coral_purple]]:
		var x: float = c[0]
		MapLook.cylinder(look, 0.12, 0.8, Vector3(x, 0.4, -1.7), c[1], 0.2, Vector3(0, 0, 10), 6)
		MapLook.cylinder(look, 0.1, 0.6, Vector3(x + 0.2, 0.45, -1.6), c[1], 0.16, Vector3(0, 0, -25), 6)
		MapLook.sphere(look, 0.28, Vector3(x - 0.15, 0.2, -1.5), c[1], Vector3(1.2, 0.7, 1.0))
	for x in [-4.4, 3.2, 5.6]:
		for k in 3:
			MapLook.cylinder(look, 0.06, 1.6 + k * 0.4, Vector3(x + k * 0.2, 0.8 + k * 0.2, -1.8), kelp, 0.03,
				Vector3(0, 0, -8 + k * 8), 5)

	# Zwei Korallenfelsen, die gegenläufig auf und ab schweben.
	for b in [[-4.4, 0.0], [4.4, 0.5]]:
		var x: float = b[0]
		var rock := MovingPlatform.create(plat, Vector3(2.6, 0.3, 2.2), Vector3(x, 1.8, 0), Vector3(x, 3.6, 0), 6.0, b[1])
		MapLook.box(rock, Vector3(2.7, 0.45, 2.2), Vector3(0, -0.07, 0), floor_mat)
		MapLook.sphere(rock, 0.6, Vector3(-0.8, -0.45, 0.4), coral_pink, Vector3(1.4, 0.7, 1.0))
		MapLook.sphere(rock, 0.5, Vector3(0.9, -0.4, 0.3), coral_orange, Vector3(1.3, 0.6, 1.0))
		MapLook.cylinder(rock, 0.1, 0.6, Vector3(0.4, 0.3, -0.8), coral_purple, 0.16, Vector3(0, 0, -15), 6)
		MapLook.particles(rock, Vector3(0, -0.5, 0), Vector3(0.8, 0.1, 0.5), Color(0.85, 0.95, 1.0, 0.6), 12,
			Vector3(0, -1.0, 0), 0.06, 1.5)

	# Glasbrücke in der Mitte und Korallen-Vorsprünge an den Stahlstützen.
	var bridge := Vector3(0, 4.4, 0)
	MapLook.platform(col, Vector3(3.4, 0.3, 2.0), bridge)
	MapLook.box(plat, Vector3(3.5, 0.15, 2.0), bridge + Vector3(0, 0.05, 0), glass)
	MapLook.box(plat, Vector3(3.6, 0.05, 0.06), bridge + Vector3(0, 0.13, 1.0), glass_edge)
	MapLook.box(plat, Vector3(3.6, 0.05, 0.06), bridge + Vector3(0, 0.13, -1.0), glass_edge)
	for side in [-1, 1]:
		MapLook.box(plat, Vector3(0.2, 4.4, 0.2), Vector3(side * 1.7, 2.2, -0.8), steel)
		var pos := Vector3(side * 7.6, 4.0, 0)
		MapLook.platform(col, Vector3(2.0, 0.3, 1.8), pos)
		MapLook.box(plat, Vector3(2.0, 0.4, 1.8), pos + Vector3(0, -0.05, 0), floor_mat)
		MapLook.sphere(plat, 0.55, pos + Vector3(side * 0.2, -0.5, 0.0), coral_purple if side < 0 else coral_pink, Vector3(1.2, 1.0, 1.0))
		MapLook.box(plat, Vector3(0.25, 4.0, 0.25), Vector3(side * 8.2, 2.0, -0.8), steel)

	# Blasenröhren außen: aufsteigendes Wasser trägt einen sanft hinauf bis zum Glasröhren-Gang.
	for side in [-1, 1]:
		var x: float = side * 10.6
		BouncePad.create(look, Vector3(1.4, 7.4, 2.0), Vector3(x, 3.7, 0), 9.5, true)
		var tube := MapLook.cylinder(look, 0.85, 7.6, Vector3(x, 3.8, -0.2), glass, -1.0, Vector3.ZERO, 20)
		tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		MapLook.cylinder(look, 0.95, 0.2, Vector3(x, 0.1, -0.2), steel, -1.0, Vector3.ZERO, 20)
		MapLook.cylinder(look, 0.95, 0.06, Vector3(x, 0.22, -0.2), glass_edge, -1.0, Vector3.ZERO, 20)
		MapLook.particles(look, Vector3(x, 0.4, 0), Vector3(0.5, 0.1, 0.5), Color(0.85, 0.95, 1.0, 0.7), 40,
			Vector3(0, 6.0, 0), 0.08, 1.2)

	# Glasröhren-Gang oben quer durch die Kuppel und die Beobachtungskuppel ganz oben.
	var corridor := Vector3(0, 7.0, 0)
	MapLook.platform(col, Vector3(19.0, 0.3, 2.0), corridor)
	MapLook.box(plat, Vector3(19.0, 0.15, 2.0), corridor + Vector3(0, -0.05, 0), steel)
	MapLook.box(plat, Vector3(19.1, 0.05, 0.06), corridor + Vector3(0, 0.05, 1.0), glass_edge)
	var pipe := MapLook.cylinder(plat, 1.3, 19.0, corridor + Vector3(0, 1.0, -0.4), glass, -1.0, Vector3(0, 0, 90), 24)
	pipe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for y in [2.3, -0.25]:
		MapLook.box(plat, Vector3(19.0, 0.08, 0.1), corridor + Vector3(0, y, -1.2), glass_edge)
	var obs := Vector3(0, 9.6, 0)
	MapLook.platform(col, Vector3(3.2, 0.3, 2.0), obs)
	MapLook.box(plat, Vector3(3.3, 0.2, 2.0), obs + Vector3(0, -0.05, 0), steel)
	MapLook.box(plat, Vector3(3.4, 0.05, 0.06), obs + Vector3(0, 0.07, 1.0), glass_edge)
	var cap := MapLook.sphere(plat, 1.7, obs + Vector3(0, 0.4, -0.6), glass, Vector3(1.0, 0.8, 0.6))
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MapLook.light(plat, obs + Vector3(0, 0.8, 0.6), Color(0.5, 0.95, 1.0), 0.8, 5.0)

	# Draußen: Meeresgrund, Riffe, ein Wrack, Fischschwärme.
	MapLook.box(bg, Vector3(140, 0.4, 70), Vector3(0, -1.5, -40), seabed)
	for r in [[-20.0, -16.0, coral_pink], [19.0, -14.0, coral_purple], [-9.0, -24.0, coral_orange], [10.0, -26.0, coral_pink]]:
		MapLook.sphere(bg, 2.5, Vector3(r[0], -0.5, r[1]), r[2], Vector3(1.6, 0.9, 1.2))
		MapLook.cylinder(bg, 0.3, 4.0, Vector3(r[0] + 1.5, 1.5, r[1]), kelp, 0.1, Vector3(0, 0, 8), 6)
	MapLook.box(bg, Vector3(14.0, 3.5, 4.0), Vector3(24.0, 0.5, -32.0), wreck, Vector3(0, -30, 18))
	MapLook.cylinder(bg, 0.3, 9.0, Vector3(23.0, 5.0, -32.0), wreck, -1.0, Vector3(0, 0, 25), 6)
	fx.flock(Vector3(0, 11.0, -14.0), 6, Color(1.0, 0.7, 0.2), Vector3(14, 1.0, 5), 0.25, 0.3)
	fx.flock(Vector3(-4.0, 14.0, -17.0), 5, Color(0.3, 0.7, 1.0), Vector3(12, 1.0, 5), -0.3, 0.3)

	# Aufsteigende Blasen, Lichtstrahlen von oben, blaues Licht.
	MapLook.particles(self, Vector3(0, -1.0, -1.5), Vector3(15, 0.5, 3), Color(0.85, 0.95, 1.0, 0.6), 80,
		Vector3(0, 2.0, 0), 0.08, 6.0)
	for x in [-10.0, -4.0, 3.0, 9.0]:
		MapLook.box(bg, Vector3(1.8, 24.0, 0.05), Vector3(x, 8.0, -10.0), MapLook.mat(Color(0.7, 0.95, 1.0, 0.1), 1.0, 0.0, 0.6),
			Vector3(0, 0, 12))
	MapLook.light(look, Vector3(0, 7.0, 4.0), Color(0.6, 0.85, 1.0), 1.0, 14.0)
	MapLook.light(look, Vector3(0, 0.6, 1.5), Color(0.3, 0.9, 1.0), 0.6, 8.0)
	MapFX.mood(self, Color(0.1, 0.35, 0.55), 0.02, 0.6, 1.15, 1.05)

	# Vordergrund: Korallen in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.sphere(fg, 0.45, Vector3(side * 2.05, -1.32, -3.0), coral_pink if side < 0 else coral_purple, Vector3(1.5, 0.7, 0.5))
		MapLook.cylinder(fg, 0.06, 0.6, Vector3(side * 1.65, -1.2, -3.0), kelp, 0.03, Vector3(0, 0, side * 10.0), 5)
	MapLook.backdrop(bg, "res://assets/maps/unterwasser/hintergrund.png", -60.0, 180.0, 10.0)


## Maschinenraum unter dem Boden: Rohre, Ventile, Warnstreifen und in der Mitte ein leuchtender Reaktor.
## Unter jeder Luke hängt ein Laufsteg, über den man wieder hinaufkommt. Die Wände an den Enden sind dicht.
func _engine_room(col: Node3D, look: Node3D, plat: Node3D, steel: Material, glow: Material, floor_mat: Material) -> void:
	var inner := HALF - 0.6
	MapLook.solid(col, Vector3(HALF * 2.0, 1.6, 4), Vector3(0, ENGINE_Y - 0.8, 0))
	MapLook.box(look, Vector3(HALF * 2.0 + 0.2, 0.3, 4.3), Vector3(0, ENGINE_Y - 0.15, 0), MapLook.mat(Color(0.35, 0.38, 0.42), 0.5, 0.7))
	MapLook.box(look, Vector3(HALF * 2.0, 1.3, 4.0), Vector3(0, ENGINE_Y - 0.95, 0), steel)
	var h := -1.4 - ENGINE_Y
	for side in [-1, 1]:
		MapLook.solid(col, Vector3(0.6, h, 4), Vector3(side * (inner + 0.3), ENGINE_Y + h / 2.0, 0))
		MapLook.box(look, Vector3(0.7, h, 4.2), Vector3(side * (inner + 0.3), ENGINE_Y + h / 2.0, 0), steel)
	var wall := MapLook.mat(Color(0.16, 0.2, 0.26), 0.5, 0.6)
	MapLook.box(look, Vector3(inner * 2.0, h, 0.3), Vector3(0, ENGINE_Y + h / 2.0, -1.95), wall)
	# Rohre an der Rückwand.
	var pipe := MapLook.mat(Color(0.6, 0.5, 0.3), 0.4, 0.8)
	for y in [ENGINE_Y + 2.7, ENGINE_Y + 3.1]:
		MapLook.cylinder(look, 0.12, inner * 2.0, Vector3(0, y, -1.7), pipe, -1.0, Vector3(0, 0, 90), 10)
	for x in [-9.5, -5.0, 5.0, 9.5]:
		MapLook.cylinder(look, 0.15, h, Vector3(x, ENGINE_Y + h / 2.0, -1.65), steel, -1.0, Vector3.ZERO, 10)
		MapLook.cylinder(look, 0.25, 0.08, Vector3(x + 0.4, ENGINE_Y + 1.5, -1.7), MapLook.mat(Color(0.8, 0.1, 0.1), 0.5),
			-1.0, Vector3(90, 0, 0), 12)
	# Warnstreifen am Boden.
	var yellow := MapLook.mat(Color(1.0, 0.8, 0.1), 0.6)
	for i in 12:
		MapLook.box(look, Vector3(0.5, 0.02, 0.3), Vector3(-inner + 1.0 + i * 1.8, ENGINE_Y + 0.01, 1.7), yellow, Vector3(0, 35, 0))
	# Reaktor in der Mitte hinten.
	MapLook.cylinder(look, 0.9, 2.6, Vector3(0, ENGINE_Y + 1.3, -1.2), steel, -1.0, Vector3.ZERO, 20)
	var core := MapLook.cylinder(look, 0.55, 2.0, Vector3(0, ENGINE_Y + 1.3, -0.9), MapLook.mat(Color(0.3, 1.0, 0.9, 0.8), 0.1,
		0.0, 4.0), -1.0, Vector3.ZERO, 16)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MapLook.light(look, Vector3(0, ENGINE_Y + 1.5, 0.3), Color(0.3, 1.0, 0.9), 1.6, 7.0)
	MapLook.particles(look, Vector3(0, ENGINE_Y + 2.4, -0.9), Vector3(0.4, 0.1, 0.4), Color(0.6, 1.0, 0.95, 0.8), 20,
		Vector3(0, 0.8, 0), 0.06, 1.0)
	# Dampf aus den Rohren und Warnlichter.
	for x in [-7.0, 7.0]:
		MapLook.particles(look, Vector3(x, ENGINE_Y + 3.0, -1.4), Vector3(0.1, 0.1, 0.1), Color(0.9, 0.95, 1.0, 0.35), 15,
			Vector3(0.6, -0.4, 0.4), 0.3, 1.2)
		MapLook.light(look, Vector3(x, ENGINE_Y + 2.8, -0.8), Color(1.0, 0.3, 0.2), 0.8, 4.0)
	# Laufstege unter den Luken.
	for hatch in HATCHES:
		var pos := Vector3(hatch[0], -2.4, 0)
		var w: float = hatch[1] * 2.0 + 0.4
		MapLook.platform(col, Vector3(w, 0.3, 1.8), pos)
		MapLook.box(plat, Vector3(w, 0.1, 1.8), pos, steel)
		MapLook.box(plat, Vector3(w, 0.05, 0.05), pos + Vector3(0, 0.6, 0.88), steel)
		for k in [-1, 1]:
			MapLook.box(plat, Vector3(0.05, 0.6, 0.05), pos + Vector3(k * (w / 2.0 - 0.05), 0.3, 0.88), steel)
			MapLook.box(plat, Vector3(0.06, 1.0, 0.06), pos + Vector3(k * (w / 2.0 - 0.1), 0.5, -0.88), steel)
