extends Node3D
## Piratenschiff: großes Schiff mit drei Masten. Durch zwei Luken im Deck kommt man hinunter ins Unterdeck mit den
## Kanonen und der Schatztruhe. Vorne das Vordeck mit dem Bugspriet, hinten das Achterdeck mit der Hecklaterne,
## daneben schaukelt ein Beiboot im Wasser. Wanten, Rahen, Ausguck und Krähennest bis hoch zur obersten Rah.
## Bei Seegang schaukelt "Schiff". Wehende Segel und Flaggen, Wellen und Möwen.

const MAIN_MAST := -3.2
const AFT_MAST := 3.6
const FORE_MAST := -9.0
## Deck von DECK_X1 bis DECK_X2, darunter das Unterdeck auf Höhe LOWER_Y.
const DECK_X1 := -12.0
const DECK_X2 := 11.0
const LOWER_Y := -3.2
## Die beiden Luken im Deck: Mitte und halbe Breite.
const HATCHES := [[-5.4, 0.8], [1.8, 0.8]]
## Höhe der Rahen (Stangen mit Segeln), auf denen man stehen kann.
const MAIN_YARD := 11.0
const AFT_YARD := 8.5


func _ready() -> void:
	var col: Node3D = $Collision
	var ship := Node3D.new()
	ship.name = "Schiff"
	$StageLook.add_child(ship)
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var planks_tex := MapFX.tex("planken")
	var hull_tex := MapFX.tex("rumpf")
	var deck: Material = MapFX.textured(planks_tex, MapFX.tex("planken_n"), Color(1, 0.95, 0.9), 0.5) if planks_tex \
		else MapLook.mat(Color(0.62, 0.42, 0.24))
	var hull: Material = MapFX.textured(hull_tex, MapFX.tex("rumpf_n"), Color(0.85, 0.8, 0.78), 0.45) if hull_tex \
		else MapLook.mat(Color(0.32, 0.19, 0.1))
	var plank_line := MapLook.mat(Color(0.35, 0.22, 0.12))
	var hull_dark := MapLook.mat(Color(0.2, 0.12, 0.07))
	var wood := MapLook.mat(Color(0.32, 0.19, 0.1))
	var red := MapLook.mat(Color(0.8, 0.12, 0.1))
	var rope := MapLook.mat(Color(0.75, 0.65, 0.45))
	var iron := MapLook.mat(Color(0.15, 0.15, 0.17), 0.4, 0.6)
	var sail_tex := MapFX.tex("segeltuch")
	$Spawn1.position = Vector3(-7.5, 0.2, 0)
	$Spawn2.position = Vector3(4.5, 0.2, 0)
	MapLook.stage_area(self, Rect2(-15.6, LOWER_Y, 31.0, MAIN_YARD + 0.3 - LOWER_Y), 11.0)

	# Deck mit zwei Luken (Gitter, durch die man mit 2× Runter fällt), rechts das erhöhte Achterdeck.
	var edges := [DECK_X1]
	for h in HATCHES:
		edges.append(h[0] - h[1])
		edges.append(h[0] + h[1])
	edges.append(DECK_X2)
	for i in range(0, edges.size(), 2):
		var w: float = edges[i + 1] - edges[i]
		var cx: float = (edges[i] + edges[i + 1]) / 2.0
		MapLook.solid(col, Vector3(w, 0.6, 4), Vector3(cx, -0.3, 0))
		MapLook.box(ship, Vector3(w, 0.3, 4.2), Vector3(cx, -0.15, 0), deck)
		MapLook.box(ship, Vector3(w, 0.3, 4.0), Vector3(cx, -0.45, 0), wood)
	for h in HATCHES:
		MapLook.platform(col, Vector3(h[1] * 2.0, 0.3, 3.0), Vector3(h[0], -0.15, 0))
		for k in 4:
			MapLook.box(ship, Vector3(0.08, 0.1, 3.0), Vector3(h[0] - h[1] + 0.2 + k * 0.4, -0.05, 0), wood)
		MapLook.box(ship, Vector3(h[1] * 2.0, 0.1, 0.08), Vector3(h[0], -0.05, 0.0), wood)
	if planks_tex == null:
		for i in 7:
			MapLook.box(ship, Vector3(DECK_X2 - DECK_X1, 0.02, 0.05), Vector3((DECK_X1 + DECK_X2) / 2.0, 0.005, -1.8 + i * 0.6),
				plank_line)
	MapLook.solid(col, Vector3(3.6, 1.2, 4), Vector3(DECK_X2 - 1.8, 0.6, 0))
	MapLook.box(ship, Vector3(3.8, 1.2, 4.2), Vector3(DECK_X2 - 1.8, 0.6, 0), hull)
	MapLook.box(ship, Vector3(3.8, 0.12, 4.2), Vector3(DECK_X2 - 1.8, 1.15, 0), deck)
	MapLook.box(ship, Vector3(DECK_X2 - DECK_X1 + 0.6, 0.18, 0.2), Vector3((DECK_X1 + DECK_X2) / 2.0, -0.55, 2.2), red)

	_lower_deck(col, ship, hull, hull_dark, wood, iron, deck, red)

	# Bug (links): erhöhtes Vordeck, auf das man springen kann, und der Bugspriet weit über dem Wasser.
	MapLook.solid(col, Vector3(3.2, 1.0, 4), Vector3(DECK_X1 + 1.6, 0.5, 0))
	MapLook.box(ship, Vector3(3.2, 3.2, 4.4), Vector3(DECK_X1 - 0.5, -1.6, 0), hull, Vector3(0, 0, 22.0))
	MapLook.box(ship, Vector3(3.4, 1.0, 4.4), Vector3(DECK_X1 + 1.6, 0.5, 0), hull)
	MapLook.box(ship, Vector3(3.4, 0.12, 4.4), Vector3(DECK_X1 + 1.6, 0.95, 0), deck)
	MapLook.box(ship, Vector3(1.0, 0.9, 4.4), Vector3(DECK_X1 - 0.3, 1.0, 0), hull, Vector3(0, 0, -20.0))
	for i in 4:
		MapLook.box(ship, Vector3(0.12, 0.7, 0.12), Vector3(DECK_X1 + 0.4 + i * 0.9, 1.35, -2.0), wood)
	MapLook.box(ship, Vector3(3.2, 0.12, 0.18), Vector3(DECK_X1 + 1.75, 1.7, -2.0), wood)
	var bowsprit := Vector3(DECK_X1 - 2.0, 2.0, 0)
	MapLook.platform(col, Vector3(3.0, 0.3, 1.6), bowsprit)
	MapLook.cylinder(ship, 0.16, 5.0, bowsprit + Vector3(1.0, -0.5, 0), wood, 0.1, Vector3(0, 0, 72))
	MapLook.box(ship, Vector3(3.0, 0.12, 1.0), bowsprit + Vector3(0, 0.0, 0), deck)
	MapLook.cylinder(ship, 0.03, 5.0, bowsprit + Vector3(2.2, 2.6, -0.4), rope, -1.0, Vector3(0, 0, -35))
	# Heck (rechts): Wand mit Fenstern und darüber die Hecklaterne als kleine Plattform.
	MapLook.box(ship, Vector3(1.2, 4.6, 4.6), Vector3(DECK_X2 + 0.4, -1.0, 0), hull)
	for k in 3:
		MapLook.box(ship, Vector3(0.05, 0.5, 0.6), Vector3(DECK_X2 + 1.02, -1.4, -1.2 + k * 1.2),
			MapLook.mat(Color(1, 0.8, 0.4), 0.5, 0.0, 1.5))
	var lantern := Vector3(DECK_X2 - 0.6, 3.6, 0)
	MapLook.platform(col, Vector3(2.0, 0.3, 1.8), lantern)
	MapLook.box(ship, Vector3(2.1, 0.2, 1.8), lantern, wood)
	MapLook.box(ship, Vector3(0.15, 2.4, 0.15), lantern + Vector3(0.6, -1.2, -0.7), wood)
	MapLook.sphere(ship, 0.3, lantern + Vector3(0.0, 0.5, -0.6), MapLook.mat(Color(1, 0.75, 0.3), 0.5, 0.0, 3.0))
	MapLook.light(ship, lantern + Vector3(0, 0.6, 0), Color(1, 0.7, 0.35), 1.2, 5.0)

	# Beiboot rechts neben dem Schiff: schaukelt im Wasser auf und ab.
	var boat := MovingPlatform.create($Platforms, Vector3(2.6, 0.3, 1.6), Vector3(13.6, -2.7, 0), Vector3(13.6, -2.2, 0), 3.5)
	MapLook.box(boat, Vector3(2.8, 0.6, 1.4), Vector3(0, -0.35, 0), hull)
	MapLook.box(boat, Vector3(2.6, 0.1, 1.3), Vector3(0, 0.0, 0), deck)
	MapLook.cylinder(boat, 0.04, 2.0, Vector3(0.6, 0.2, 0.7), wood, -1.0, Vector3(0, 0, 70))
	# Laternen am Heck (flackern).
	for x in [8.9, 10.2]:
		MapLook.sphere(ship, 0.18, Vector3(x, 2.0, -1.6), MapLook.mat(Color(1, 0.75, 0.3), 0.5, 0.0, 2.5))
		MapLook.light(ship, Vector3(x, 2.0, -1.2), Color(1, 0.7, 0.35), 0.8, 3.0)

	# Reling hinten (vorne nicht, damit sie die Kämpfer nicht verdeckt).
	for i in 18:
		MapLook.box(ship, Vector3(0.12, 0.8, 0.12), Vector3(-10.2 + i * 1.0, 0.4, -2.0), wood)
	MapLook.box(ship, Vector3(18.0, 0.12, 0.18), Vector3(-1.7, 0.82, -2.0), wood)

	# Hauptmast und hinterer Mast mit wehenden Segeln und Flaggen.
	MapLook.cylinder(ship, 0.25, 15.0, Vector3(MAIN_MAST, 7.5, -0.4), wood)
	MapLook.cylinder(ship, 0.22, 12.0, Vector3(AFT_MAST, 6.0, -0.4), wood)
	# Rahen (die Stangen, an denen die Segel hängen): man kann auf ihnen stehen.
	# Die obere Rah erreicht man vom Ausguck aus, die untere von der Rah in der Mitte.
	for yard in [[MAIN_MAST, MAIN_YARD, 6.0, 5.4], [AFT_MAST, AFT_YARD, 5.0, 4.6]]:
		MapLook.cylinder(ship, 0.16, yard[2], Vector3(yard[0], yard[1], -0.3), wood, -1.0, Vector3(0, 0, 90))
		MapLook.platform(col, Vector3(yard[3], 0.3, 2.4), Vector3(yard[0], yard[1] + 0.16 - 0.15, 0))
	MapFX.cloth(ship, Vector2(5.4, 3.4), Vector3(MAIN_MAST, MAIN_YARD - 1.75, -0.9), Color(0.97, 0.94, 0.86), sail_tex, true, 0.35)
	MapFX.cloth(ship, Vector2(4.6, 3.0), Vector3(AFT_MAST, AFT_YARD - 1.55, -0.9), Color(0.97, 0.94, 0.86), sail_tex, true, 0.3)
	MapFX.cloth(ship, Vector2(1.4, 0.8), Vector3(MAIN_MAST + 0.75, 15.0, -0.4), Color(0.85, 0.12, 0.1), null, false, 0.25)
	MapFX.cloth(ship, Vector2(1.1, 0.6), Vector3(AFT_MAST + 0.6, 12.0, -0.4), Color(0.1, 0.1, 0.1), null, false, 0.2)
	for b in [-7.4, -2.0, 5.2]:
		MapLook.cylinder(ship, 0.4, 0.9, Vector3(b, 0.45, -1.3), hull)
	for c in [-0.6, 3.6]:
		MapLook.cylinder(ship, 0.22, 1.4, Vector3(c, 0.35, -1.5), iron, -1.0, Vector3(90, 0, 0))

	# Kanone auf dem Achterdeck (3D-Modell aus Flux + Trellis).
	MapLook.prop(ship, "res://assets/maps/props/kanone.glb", Vector3(9.6, 1.2, -1.0), 1.1, -90.0)

	# Vordermast mit Rah und Krähennest.
	MapLook.cylinder(ship, 0.2, 9.0, Vector3(FORE_MAST, 5.5, -0.4), wood)
	MapLook.cylinder(ship, 0.14, 4.0, Vector3(FORE_MAST, 5.2, -0.3), wood, -1.0, Vector3(0, 0, 90))
	MapLook.platform(col, Vector3(3.6, 0.3, 2.4), Vector3(FORE_MAST, 5.21, 0))
	MapFX.cloth(ship, Vector2(3.6, 2.4), Vector3(FORE_MAST, 3.9, -0.9), Color(0.97, 0.94, 0.86), sail_tex, true, 0.3)
	MapLook.platform(col, Vector3(2.0, 0.3, 2.0), Vector3(FORE_MAST, 8.0, 0))
	MapLook.cylinder(ship, 1.0, 0.5, Vector3(FORE_MAST, 7.9, 0), deck, -1.0, Vector3.ZERO, 16)
	MapLook.cylinder(ship, 1.05, 0.1, Vector3(FORE_MAST, 8.15, 0), wood, -1.0, Vector3.ZERO, 16)
	MapFX.cloth(ship, Vector2(1.0, 0.6), Vector3(FORE_MAST + 0.55, 10.0, -0.4), Color(0.1, 0.1, 0.1), null, false, 0.2)

	# Plattformen.
	# Wanten am Bug (links, niedrig).
	MapLook.platform(col, Vector3(2.6, 0.3, 2.4), Vector3(-7.0, 2.6, 0))
	MapLook.box(ship, Vector3(2.7, 0.25, 2.5), Vector3(-7.0, 2.6, 0), deck)
	for x in [-8.2, -5.8]:
		MapLook.cylinder(ship, 0.03, 6.0, Vector3(x, 4.0, -0.4), rope)
	MapLook.cylinder(ship, 0.04, 7.5, Vector3(-5.4, 6.2, -0.4), rope, -1.0, Vector3(0, 0, 38))
	# Rah am hinteren Mast (mittelhoch).
	MapLook.platform(col, Vector3(3.4, 0.3, 2.4), Vector3(AFT_MAST, 3.4, 0))
	MapLook.cylinder(ship, 0.18, 3.6, Vector3(AFT_MAST, 3.35, 0), wood, -1.0, Vector3(0, 0, 90))
	MapLook.box(ship, Vector3(3.4, 0.12, 1.2), Vector3(AFT_MAST, 3.5, 0), deck)
	# Ausguck hoch oben am Hauptmast.
	MapLook.platform(col, Vector3(2.4, 0.3, 2.4), Vector3(MAIN_MAST, 6.2, 0))
	MapLook.cylinder(ship, 1.25, 0.6, Vector3(MAIN_MAST, 6.05, 0), deck, -1.0, Vector3.ZERO, 16)
	MapLook.cylinder(ship, 1.3, 0.12, Vector3(MAIN_MAST, 6.38, 0), wood, -1.0, Vector3.ZERO, 16)
	MapLook.cylinder(ship, 0.04, 6.5, Vector3(MAIN_MAST - 1.6, 3.0, -0.4), rope, -1.0, Vector3(0, 0, -14))
	MapLook.cylinder(ship, 0.04, 6.5, Vector3(MAIN_MAST + 1.6, 3.0, -0.4), rope, -1.0, Vector3(0, 0, 14))

	# Meer mit Wellen und Gischt, Möwen.
	MapFX.water(bg, Vector2(220, 110), Vector3(0, -3.6, 0))
	MapLook.particles(self, Vector3(0, -3.3, 3.0), Vector3(18, 0.2, 1), Color(1, 1, 1, 0.7), 60,
		Vector3(0, 1.5, 0), 0.15, 1.5, Vector3(0, -2, 0))
	fx.flock(Vector3(0, 14.0, -8.0), 6, Color(0.97, 0.97, 0.97), Vector3(14, 1.0, 5), 0.25, 0.5)
	fx.flicker_all(ship, 0.25)
	MapFX.mood(self, Color(0.75, 0.88, 1.0), 0.005, 0.35, 1.15, 1.05)

	# Vordergrund: Taue hängen in die oberen Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.cylinder(fg, 0.025, 2.2, Vector3(side * 1.85, 0.90, -3.0), rope, -1.0, Vector3(0, 0, side * 55.0), 6)
		MapLook.cylinder(fg, 0.02, 1.4, Vector3(side * 2.11, 0.63, -3.0), rope, -1.0, Vector3(0, 0, side * 20.0), 6)
	MapLook.backdrop(bg, "res://assets/maps/piratenschiff/hintergrund.png", -60.0, 180.0, 10.0)


## Unterdeck: vorne offen (wie ein Puppenhaus), hinten die Bordwand mit Kanonen an den Stückpforten, Hängematten,
## Fässer und eine Schatztruhe. Die Enden schließt die Bordwand ab, unten liegt der Kiel im Wasser.
func _lower_deck(col: Node3D, ship: Node3D, hull: Material, dark: Material, wood: Material, iron: Material,
		deck: Material, red: Material) -> void:
	var x1 := DECK_X1 + 1.0
	var x2 := DECK_X2 - 1.4
	var w := x2 - x1
	var cx := (x1 + x2) / 2.0
	var h := -0.6 - LOWER_Y
	MapLook.solid(col, Vector3(w + 1.2, 1.0, 4), Vector3(cx, LOWER_Y - 0.5, 0))
	MapLook.box(ship, Vector3(w + 1.2, 0.2, 4.0), Vector3(cx, LOWER_Y - 0.1, 0), deck)
	for side in [-1, 1]:
		var x: float = cx + side * (w / 2.0 + 0.3)
		MapLook.solid(col, Vector3(0.6, h, 4), Vector3(x, LOWER_Y + h / 2.0, 0))
		MapLook.box(ship, Vector3(0.7, h, 4.2), Vector3(x, LOWER_Y + h / 2.0, 0), hull)
	# Rumpf unter Wasser, Kiel und eine niedrige Bordwand vorne.
	MapLook.box(ship, Vector3(w + 2.0, 1.6, 4.6), Vector3(cx, LOWER_Y - 1.4, 0), hull)
	MapLook.box(ship, Vector3(w - 1.0, 1.0, 3.4), Vector3(cx, LOWER_Y - 2.6, 0), dark)
	MapLook.box(ship, Vector3(w + 1.2, 0.5, 0.2), Vector3(cx, LOWER_Y + 0.25, 2.1), hull)
	MapLook.box(ship, Vector3(w + 1.2, 0.08, 0.22), Vector3(cx, LOWER_Y + 0.5, 2.1), red)
	MapLook.box(ship, Vector3(w + 1.2, h, 0.3), Vector3(cx, LOWER_Y + h / 2.0, -2.0), dark)
	# Balken an der Decke.
	for i in 8:
		MapLook.box(ship, Vector3(0.25, 0.25, 4.0), Vector3(x1 + 1.0 + i * (w - 2.0) / 7.0, -0.75, 0), wood)
	# Kanonen an den Stückpforten der hinteren Bordwand.
	for x in [-9.0, -2.8, 4.0]:
		MapLook.box(ship, Vector3(0.9, 0.7, 0.1), Vector3(x, LOWER_Y + 1.2, -1.82), MapLook.mat(Color(0.05, 0.05, 0.06)))
		MapLook.cylinder(ship, 0.2, 1.4, Vector3(x, LOWER_Y + 1.1, -1.2), iron, 0.16, Vector3(90, 0, 0), 12)
		MapLook.box(ship, Vector3(0.8, 0.35, 0.9), Vector3(x, LOWER_Y + 0.55, -1.2), wood)
		for k in 3:
			MapLook.sphere(ship, 0.13, Vector3(x + 0.7 + k * 0.27, LOWER_Y + 0.13, -1.4), iron)
	# Hängematten, Fässer und eine Schatztruhe mit Goldglanz.
	var cloth := MapLook.mat(Color(0.85, 0.8, 0.65), 1.0)
	for x in [-6.6, 0.8]:
		MapLook.box(ship, Vector3(1.8, 0.1, 0.6), Vector3(x, LOWER_Y + 2.0, -1.5), cloth, Vector3(0, 0, 4))
	for x in [-10.2, 6.2, 7.0]:
		MapLook.cylinder(ship, 0.35, 0.8, Vector3(x, LOWER_Y + 0.4, -1.3), hull, 0.32, Vector3.ZERO, 12)
	var gold := MapLook.mat(Color(1.0, 0.8, 0.3), 0.3, 0.8, 0.6)
	MapLook.box(ship, Vector3(1.0, 0.6, 0.65), Vector3(-0.4, LOWER_Y + 0.3, -1.4), MapLook.mat(Color(0.45, 0.28, 0.15)))
	MapLook.box(ship, Vector3(1.05, 0.1, 0.7), Vector3(-0.4, LOWER_Y + 0.62, -1.4), gold)
	MapLook.sphere(ship, 0.3, Vector3(-0.4, LOWER_Y + 0.7, -1.4), gold, Vector3(1.4, 0.5, 0.8))
	for x in [-6.0, 2.4]:
		MapLook.sphere(ship, 0.16, Vector3(x, LOWER_Y + 2.3, -1.6), MapLook.mat(Color(1, 0.75, 0.3), 0.5, 0.0, 2.5))
		MapLook.light(ship, Vector3(x, LOWER_Y + 2.2, -0.8), Color(1, 0.7, 0.35), 1.0, 5.0)
