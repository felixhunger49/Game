extends Node3D
## Japanischer Tempel: großer Steinhof mit rotem Holzgeländer vor einer Tempelhalle mit geschwungenem Dach.
## In der Mitte unter dem Torii führt ein Treppenschacht hinunter in einen Geheimgang mit Laternen.
## Links eine dreistöckige Pagode (alle Dächer begehbar), rechts die Schrein-Terrasse mit Gong und ein Wachturm
## mit Dach, außen ein Felsvorsprung mit großem Kirschbaum (Äste begehbar) und ein Bambus-Sprungbrett.
## Steinlaternen, ein großer Gong (für das Gong-Ereignis) und fallende Kirschblüten.

const HALF := 11.0
## Halbe Breite des Treppenschachts in der Mitte.
const SHAFT := 1.2
const TUNNEL_Y := -4.6
const TUNNEL_HALF := 9.0


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var stone_tex := MapFX.tex("steinplatten")
	var stone: Material = MapFX.textured(stone_tex, MapFX.tex("steinplatten_n"), Color.WHITE, 0.35) if stone_tex \
		else MapLook.mat(Color(0.72, 0.72, 0.7))
	var stone_dark := MapLook.mat(Color(0.45, 0.45, 0.44))
	var red := MapLook.mat(Color(0.78, 0.12, 0.08), 0.6)
	var black := MapLook.mat(Color(0.1, 0.08, 0.08), 0.5)
	var wood := MapLook.mat(Color(0.45, 0.28, 0.16), 0.8)
	var roof := MapLook.mat(Color(0.2, 0.22, 0.28), 0.6, 0.2)
	var paper := MapLook.mat(Color(1.0, 0.92, 0.75), 0.9, 0.0, 0.8)
	var bark := MapLook.mat(Color(0.3, 0.2, 0.17), 1.0)
	var gold := MapLook.mat(Color(0.95, 0.72, 0.3), 0.3, 0.8)
	$Spawn1.position = Vector3(-4.0, 0.2, 0)
	$Spawn2.position = Vector3(3.5, 0.2, 0)
	MapLook.stage_area(self, Rect2(-14.0, TUNNEL_Y, 28.5, 7.4 - TUNNEL_Y), HALF)

	# Steinhof: 22 breit, in zwei Hälften mit dem Treppenschacht dazwischen.
	for side in [-1, 1]:
		var w := HALF - SHAFT
		var cx: float = side * (SHAFT + w / 2.0)
		MapLook.solid(col, Vector3(w, 1.4, 4), Vector3(cx, -0.7, 0))
		MapLook.box(look, Vector3(w + 0.2, 0.6, 4.4), Vector3(cx + side * 0.1, -0.3, 0), stone)
		MapLook.box(look, Vector3(w, 0.8, 4.2), Vector3(cx, -1.0, 0.1), stone_dark)
		# Rote Holzkante am Schacht.
		MapLook.box(look, Vector3(0.18, 0.2, 4.4), Vector3(side * (SHAFT + 0.09), 0.02, 0), red)
	# Rotes Holzgeländer hinten.
	for i in 15:
		var x := -10.5 + i * 1.5
		if absf(x) > SHAFT + 0.3:
			MapLook.box(look, Vector3(0.14, 1.0, 0.14), Vector3(x, 0.5, -1.9), red)
	for side in [-1, 1]:
		MapLook.box(look, Vector3(HALF - SHAFT - 0.6, 0.12, 0.16), Vector3(side * (HALF + SHAFT) / 2.0, 0.95, -1.9), red)
		MapLook.box(look, Vector3(HALF - SHAFT - 0.6, 0.08, 0.12), Vector3(side * (HALF + SHAFT) / 2.0, 0.5, -1.9), red)

	_tunnel(col, look, plat, stone, stone_dark, wood, red, paper, black)

	# Tempelhalle hinten: Pfosten, Papierwände und ein geschwungenes Dach.
	for i in 9:
		MapLook.box(bg, Vector3(0.4, 5.6, 0.4), Vector3(-12.0 + i * 3.0, 2.8, -7.0), red)
	for i in 8:
		MapLook.box(bg, Vector3(2.6, 4.0, 0.1), Vector3(-10.5 + i * 3.0, 2.2, -7.3), paper)
	MapLook.box(bg, Vector3(26.0, 0.4, 1.2), Vector3(0, 5.7, -7.0), black)
	MapLook.box(bg, Vector3(29.0, 0.5, 5.0), Vector3(0, 6.5, -7.0), roof, Vector3(-12, 0, 0))
	MapLook.box(bg, Vector3(19.0, 1.4, 3.0), Vector3(0, 7.6, -7.6), roof, Vector3(-18, 0, 0))
	for side in [-1, 1]:
		MapLook.box(bg, Vector3(3.0, 0.4, 4.0), Vector3(side * 14.8, 7.0, -7.0), roof, Vector3(-12, 0, side * -14))
		MapLook.sphere(bg, 0.25, Vector3(side * 16.2, 7.5, -6.0), gold)

	# Schrein-Terrasse rechts: erhöht, mit zwei Stufen. Darauf hängt der große Gong (für das Gong-Ereignis).
	var terrace := 6.8
	MapLook.solid(col, Vector3(3.8, 1.0, 4), Vector3(terrace, 0.5, 0))
	MapLook.solid(col, Vector3(0.8, 0.5, 4), Vector3(terrace - 2.3, 0.25, 0))
	MapLook.box(look, Vector3(3.9, 1.0, 4.2), Vector3(terrace, 0.5, 0), stone)
	MapLook.box(look, Vector3(4.0, 0.1, 4.3), Vector3(terrace, 1.0, 0), red)
	MapLook.box(look, Vector3(0.8, 0.5, 4.2), Vector3(terrace - 2.3, 0.25, 0), stone_dark)
	var gong_root := Node3D.new()
	gong_root.name = "Gong"
	gong_root.position = Vector3(terrace + 0.6, 2.9, -1.4)
	look.add_child(gong_root)
	for side in [-1, 1]:
		MapLook.box(look, Vector3(0.18, 3.4, 0.18), Vector3(terrace + 0.6 + side * 1.0, 2.7, -1.4), wood)
	MapLook.box(look, Vector3(2.4, 0.18, 0.2), Vector3(terrace + 0.6, 4.4, -1.4), wood)
	MapLook.cylinder(gong_root, 0.8, 0.1, Vector3(0, 0, 0), gold, -1.0, Vector3(90, 0, 0), 32)
	MapLook.cylinder(gong_root, 0.3, 0.12, Vector3(0, 0, 0.02), MapLook.mat(Color(0.8, 0.55, 0.2), 0.3, 0.9), -1.0,
		Vector3(90, 0, 0), 24)

	# Steinlaternen.
	for l in [[-10.2, 0.0], [-3.0, 0.0], [2.6, 0.0], [terrace - 1.5, 1.0], [10.3, 0.0]]:
		var x: float = l[0]
		var y: float = l[1]
		MapLook.box(look, Vector3(0.5, 0.2, 0.5), Vector3(x, y + 0.1, -1.2), stone_dark)
		MapLook.cylinder(look, 0.12, 0.9, Vector3(x, y + 0.65, -1.2), stone_dark)
		MapLook.box(look, Vector3(0.5, 0.45, 0.5), Vector3(x, y + 1.3, -1.2), paper)
		MapLook.cylinder(look, 0.45, 0.25, Vector3(x, y + 1.65, -1.2), stone_dark, 0.05, Vector3.ZERO, 4)
		MapLook.light(look, Vector3(x, y + 1.3, -0.8), Color(1.0, 0.75, 0.4), 0.9, 3.5)

	# Dreistöckige Pagode links: drei geschwungene Dächer als Plattformen übereinander, oben eine goldene Spitze.
	var pagoda := -7.0
	for p in [[2.5, 3.6], [4.8, 3.0], [7.1, 2.4]]:
		var pos := Vector3(pagoda, p[0], 0)
		var width: float = p[1]
		MapLook.platform(col, Vector3(width, 0.3, 2.2), pos)
		MapLook.box(plat, Vector3(width + 0.4, 0.25, 2.4), pos + Vector3(0, -0.02, 0), roof)
		MapLook.box(plat, Vector3(width + 0.8, 0.12, 2.6), pos + Vector3(0, -0.2, 0.1), roof, Vector3(-6, 0, 0))
		for side in [-1, 1]:
			MapLook.sphere(plat, 0.12, pos + Vector3(side * (width * 0.5 + 0.4), -0.15, 1.1), gold)
		MapLook.box(plat, Vector3(width - 0.6, 2.0, 1.6), pos + Vector3(0, -1.25, -0.5), red)
		MapLook.box(plat, Vector3(width - 1.0, 1.2, 0.05), pos + Vector3(0, -1.2, 0.31), paper)
	MapLook.cylinder(plat, 0.06, 1.4, Vector3(pagoda, 7.9, -0.3), gold, 0.02, Vector3.ZERO, 8)
	for k in 3:
		MapLook.cylinder(plat, 0.18 - k * 0.04, 0.06, Vector3(pagoda, 7.5 + k * 0.3, -0.3), gold, -1.0, Vector3.ZERO, 12)

	# Bambus-Sprungbrett auf einem Felsen links außen: schleudert hoch zur Pagode.
	MapLook.solid(col, Vector3(2.8, 1.2, 3.0), Vector3(-12.4, -1.4, 0))
	MapLook.box(look, Vector3(3.0, 1.3, 3.2), Vector3(-12.5, -1.4, 0), stone_dark, Vector3(0, 0, 3))
	MapLook.sphere(look, 1.4, Vector3(-12.6, -2.2, 0.2), stone_dark, Vector3(1.0, 0.7, 1.0))
	var spring := BouncePad.create(plat, Vector3(1.0, 0.4, 2.0), Vector3(-12.8, -0.6, 0), 17.0)
	spring.visual = Node3D.new()
	spring.add_child(spring.visual)
	var bamboo := MapLook.mat(Color(0.55, 0.7, 0.3), 0.7)
	for k in 4:
		MapLook.cylinder(spring.visual, 0.08, 1.0, Vector3(-0.3 + k * 0.2, 0.05, 0.2), bamboo, -1.0, Vector3(90, 0, 0), 8)
	MapLook.box(spring.visual, Vector3(0.9, 0.08, 0.5), Vector3(0, 0.15, 0.2), MapLook.mat(Color(0.75, 0.15, 0.1), 0.6))

	# Torii über dem Treppenschacht: der Querbalken ist eine Plattform, darüber eine Glocke unter einem kleinen Dach.
	var torii := Vector3(0, 3.3, 0)
	MapLook.platform(col, Vector3(4.2, 0.3, 1.6), torii)
	MapLook.box(plat, Vector3(5.4, 0.35, 0.9), torii + Vector3(0, 0.0, -0.3), black)
	MapLook.box(plat, Vector3(4.4, 0.3, 1.6), torii + Vector3(0, -0.02, 0.1), red)
	MapLook.box(plat, Vector3(4.0, 0.25, 0.4), torii + Vector3(0, -0.8, -0.6), red)
	MapLook.box(plat, Vector3(0.5, 0.6, 0.12), torii + Vector3(0, -0.45, -0.45), black)
	for side in [-1, 1]:
		MapLook.cylinder(plat, 0.22, 3.4, Vector3(side * 1.9, 1.7, -0.6), red, -1.0, Vector3.ZERO, 12)
		MapLook.box(plat, Vector3(0.55, 0.3, 0.55), Vector3(side * 1.9, 0.15, -0.6), black)
	var bell := Vector3(0, 6.0, 0)
	MapLook.platform(col, Vector3(3.2, 0.3, 2.0), bell)
	MapLook.box(plat, Vector3(3.6, 0.25, 2.4), bell + Vector3(0, -0.02, -0.2), roof)
	MapLook.box(plat, Vector3(4.0, 0.12, 2.6), bell + Vector3(0, -0.2, -0.1), roof, Vector3(-6, 0, 0))
	for side in [-1, 1]:
		MapLook.box(plat, Vector3(0.16, 1.8, 0.16), bell + Vector3(side * 1.3, -1.05, -1.0), wood)
	MapLook.cylinder(plat, 0.35, 0.8, bell + Vector3(0, -0.9, -1.0), MapLook.mat(Color(0.55, 0.4, 0.2), 0.4, 0.7), 0.28)

	# Wachturm rechts über der Terrasse, auf Holzpfosten, mit begehbarem Dach.
	var lookout := Vector3(terrace + 0.4, 4.2, 0)
	MapLook.platform(col, Vector3(2.6, 0.3, 2.0), lookout)
	MapLook.box(plat, Vector3(2.7, 0.25, 2.0), lookout, wood)
	MapLook.box(plat, Vector3(2.9, 0.1, 0.1), lookout + Vector3(0, 0.6, -0.95), red)
	for side in [-1, 1]:
		MapLook.box(plat, Vector3(0.16, 3.4, 0.16), lookout + Vector3(side * 1.1, -1.8, -0.8), wood)
		MapLook.box(plat, Vector3(0.12, 2.4, 0.12), lookout + Vector3(side * 1.2, 1.2, -0.9), red)
	var top := lookout + Vector3(0, 2.6, 0)
	MapLook.platform(col, Vector3(2.4, 0.3, 2.0), top)
	MapLook.box(plat, Vector3(3.0, 0.25, 2.4), top + Vector3(0, -0.02, -0.2), roof)
	MapLook.box(plat, Vector3(3.4, 0.12, 2.6), top + Vector3(0, -0.2, -0.1), roof, Vector3(-6, 0, 0))

	# Felsvorsprung rechts außen mit großem Kirschbaum: zwei Äste zum Draufspringen.
	MapLook.solid(col, Vector3(3.4, 1.4, 3.0), Vector3(12.7, -1.6, 0))
	MapLook.box(look, Vector3(3.6, 1.5, 3.2), Vector3(12.8, -1.6, 0), stone_dark, Vector3(0, 0, -3))
	MapLook.sphere(look, 1.5, Vector3(13.0, -2.5, 0.2), stone_dark, Vector3(1.1, 0.7, 1.0))
	# Gemalter Kirschbaum hinter den Ästen (gleiches Bild wie im Hintergrund).
	MapLook.sprite(look, "res://assets/maps/tempel/baum_gross.png", Vector3(13.4, -0.95, -1.4), 7.6)
	for b in [[12.9, 1.6, 2.6, 30], [11.7, 4.4, 2.4, 55]]:
		var pos := Vector3(b[0], b[1], 0)
		MapLook.platform(col, Vector3(b[2], 0.3, 1.8), pos)
		MapLook.cylinder(plat, 0.14, b[2] + 0.6, pos + Vector3(0.3, -0.1, -0.2), bark, 0.08, Vector3(0, 0, b[3] + 30), 8)

	# Kirschbäume: gemalt (Flux) und ausgeschnitten (BiRefNet), damit Blüten und Rinde Struktur haben.
	# [x, z, Höhe, Bild, gespiegelt]
	for t in [[-12.6, -3.5, 6.5, "baum_gross", false], [16.0, -4.0, 6.0, "baum_doppel", true],
			[-17.0, -9.0, 7.5, "baum_doppel", false], [18.5, -10.0, 7.5, "baum_gross", true],
			[-6.5, -12.0, 5.5, "baum_mittel", false], [7.5, -12.5, 5.0, "baum_mittel", true]]:
		MapLook.sprite(bg, "res://assets/maps/tempel/%s.png" % t[3], Vector3(t[0], -0.15, t[1]), t[2], t[4])
	MapLook.box(bg, Vector3(80, 0.4, 40), Vector3(0, -0.2, -22), MapLook.mat(Color(0.5, 0.6, 0.38)))

	# Fallende Kirschblüten, warmes Nachmittagslicht, ein paar Vögel.
	MapLook.particles(self, Vector3(0, 11.0, -1.0), Vector3(18, 1, 4), Color(1.0, 0.75, 0.85, 1.0), 120,
		Vector3(0.6, -0.9, 0), 0.09, 12.0)
	MapLook.light(look, Vector3(0, 5.0, 4.0), Color(1.0, 0.88, 0.75), 0.8, 14.0)
	fx.flicker_all(look, 0.12)
	fx.flock(Vector3(0, 12.0, -8.0), 4, Color(0.2, 0.2, 0.25), Vector3(12, 0.8, 4), 0.3, 0.35)
	MapFX.mood(self, Color(1.0, 0.85, 0.85), 0.004, 0.2, 1.15, 1.1, 0.9)

	# Vordergrund: Kirschblütenzweige in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.sprite(fg, "res://assets/maps/tempel/bluetenzweig.png", Vector3(side * 1.95, -1.65, -3.0), 0.75,
			side < 0)
	# Tiefen-Ebene: Kirschbäume, Laterne und Toriis (mit Flux gemalt, mit BiRefNet ausgeschnitten)
	# zwischen Tempel und Hintergrundbild. Die Graskante (bei 83 % der Bildhöhe) steht auf dem Boden.
	MapLook.layer(bg, "res://assets/maps/tempel/mittelgrund.png", -32.0, 76.0, -76.0 * 640.0 / 1536.0 * 0.17, 2,
		Color(0.95, 0.93, 0.97))
	MapLook.backdrop(bg, "res://assets/maps/tempel/hintergrund.png", -60.0, 180.0, 10.0)


## Geheimgang unter dem Steinhof: Holzboden, Laternen, Steinfiguren und ein Fass. Im Treppenschacht hilft
## eine Holzplanke beim Hochspringen, an den Enden schließen Steinwände den Gang ab.
func _tunnel(col: Node3D, look: Node3D, plat: Node3D, stone: Material, dark: Material, wood: Material, red: Material,
		paper: Material, black: Material) -> void:
	var h := -1.4 - TUNNEL_Y
	MapLook.solid(col, Vector3(TUNNEL_HALF * 2.0 + 1.2, 1.6, 4), Vector3(0, TUNNEL_Y - 0.8, 0))
	MapLook.box(look, Vector3(TUNNEL_HALF * 2.0 + 1.2, 0.3, 4.2), Vector3(0, TUNNEL_Y - 0.15, 0), wood)
	MapLook.box(look, Vector3(TUNNEL_HALF * 2.0 + 1.6, 1.3, 4.0), Vector3(0, TUNNEL_Y - 0.95, 0), dark)
	for side in [-1, 1]:
		MapLook.solid(col, Vector3(0.6, h, 4), Vector3(side * (TUNNEL_HALF + 0.3), TUNNEL_Y + h / 2.0, 0))
		MapLook.box(look, Vector3(0.7, h, 4.2), Vector3(side * (TUNNEL_HALF + 0.3), TUNNEL_Y + h / 2.0, 0), stone)
	# Rückwand aus dunklem Holz mit Stützbalken und Laternen.
	MapLook.box(look, Vector3(TUNNEL_HALF * 2.0, h, 0.3), Vector3(0, TUNNEL_Y + h / 2.0, -1.9), MapLook.mat(Color(0.3, 0.2, 0.14)))
	for i in 7:
		var x := -7.5 + i * 2.5
		MapLook.box(look, Vector3(0.25, h, 0.25), Vector3(x, TUNNEL_Y + h / 2.0, -1.7), wood)
		if i % 2 == 0:
			MapLook.box(look, Vector3(0.4, 0.55, 0.4), Vector3(x + 1.25, TUNNEL_Y + 2.2, -1.5), paper)
			MapLook.box(look, Vector3(0.45, 0.06, 0.45), Vector3(x + 1.25, TUNNEL_Y + 2.5, -1.5), black)
			MapLook.light(look, Vector3(x + 1.25, TUNNEL_Y + 2.2, -0.9), Color(1.0, 0.7, 0.35), 1.0, 4.5)
	MapLook.box(look, Vector3(TUNNEL_HALF * 2.0, 0.25, 0.3), Vector3(0, -1.55, -1.7), wood)
	# Kleine Steinfiguren und ein Sake-Fass.
	for x in [-5.0, 4.0]:
		MapLook.cylinder(look, 0.22, 0.5, Vector3(x, TUNNEL_Y + 0.25, -1.4), stone, 0.18)
		MapLook.sphere(look, 0.17, Vector3(x, TUNNEL_Y + 0.62, -1.4), stone)
		MapLook.box(look, Vector3(0.36, 0.14, 0.05), Vector3(x, TUNNEL_Y + 0.38, -1.2), red)
	MapLook.cylinder(look, 0.35, 0.8, Vector3(7.6, TUNNEL_Y + 0.4, -1.3), wood, 0.33, Vector3.ZERO, 14)
	MapLook.cylinder(look, 0.36, 0.05, Vector3(7.6, TUNNEL_Y + 0.7, -1.3), black, -1.0, Vector3.ZERO, 14)
	# Holzplanke im Treppenschacht und Stufen an der Rückwand des Schachts.
	MapLook.platform(col, Vector3(SHAFT * 2.0 - 0.2, 0.3, 2.0), Vector3(0, -2.3, 0))
	MapLook.box(plat, Vector3(SHAFT * 2.0 - 0.1, 0.2, 2.0), Vector3(0, -2.3, 0), wood)
	for k in 4:
		MapLook.box(look, Vector3(SHAFT * 2.0, 0.25, 0.6), Vector3(0, TUNNEL_Y + 0.6 + k * 0.9, -1.4 + k * 0.1), dark)
