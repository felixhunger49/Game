extends Node3D
## Dorf: schwebende Wiesen-Insel mit Marktstand in der Mitte, die rechte Wiesen-Insel schwebt höher.
## Links führt ein Brunnenschacht hinunter in die Brunnenhöhle unter dem Dorf (auch über die Inselkanten erreichbar).
## Außen schweben zwei kleine Inseln: links eine Scheune mit Heuboden, rechts der Kirchturm mit Glockenstube
## und Turmspitze. Ganz oben treibt ein Heißluftballon hin und her.

const RIGHT_ISLAND_SHIFT := Vector3(0.4, 1.35, 0)
const HALF := 8.0
const CAVE_Y := -4.8
const CAVE_HALF := 10.0
## Brunnenschacht im Boden (von WELL_X1 bis WELL_X2).
const WELL_X1 := -5.9
const WELL_X2 := -4.1


func _ready() -> void:
	for path in ["RightPlatform", "Platforms/hex_grass3", "Platforms/hex_grass4", "Platforms/mountain_B_grass2"]:
		get_node(path).position += RIGHT_ISLAND_SHIFT

	var col := Node3D.new()
	add_child(col)
	var wood := MapFX.surface("holz", Color(0.5, 0.33, 0.18))
	var red := MapFX.surface("stoff", Color(0.82, 0.18, 0.15))
	var white := MapFX.surface("stoff", Color(0.95, 0.93, 0.88))
	var green := MapLook.mat(Color(0.35, 0.6, 0.25))
	var orange := MapLook.mat(Color(0.95, 0.55, 0.15))
	var soil := MapFX.surface("fels_dunkel", Color(0.45, 0.32, 0.2))
	var rock := MapFX.surface("burgstein", Color(0.5, 0.47, 0.42))
	var grass := MapFX.surface("gras", Color(0.4, 0.68, 0.3))
	$Spawn1.position = Vector3(-2.5, 0.2, 0)
	$Spawn2.position = Vector3(3.0, 0.2, 0)
	MapLook.stage_area(self, Rect2(-15.2, CAVE_Y, 30.4, 8.2 - CAVE_Y), HALF)

	# Boden der Insel in zwei Teilen mit dem Brunnenschacht dazwischen; die alten Felsen unter der Insel weichen
	# der Höhle.
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(HALF - WELL_X2, 1.4, 4)
	$Stage/CollisionShape3D.shape = floor_shape
	$Stage/CollisionShape3D.position = Vector3((WELL_X2 + HALF) / 2.0, -0.7, 0)
	MapLook.solid(col, Vector3(WELL_X1 + HALF, 1.4, 4), Vector3((WELL_X1 - HALF) / 2.0, -0.7, 0))
	for node in $StageLook.get_children():
		var p: Vector3 = node.position
		if node.name.begins_with("mountain_B_grass") or node.name == "SoilFront":
			node.queue_free()
		elif node.name.begins_with("hex_grass") and absf(p.x + 5.0) < 1.5 and p.z > -1.0:
			node.queue_free()
	for piece in [[-HALF, WELL_X1], [WELL_X2, HALF]]:
		var w: float = piece[1] - piece[0]
		MapLook.box(self, Vector3(w, 1.2, 4.0), Vector3((piece[0] + piece[1]) / 2.0, -0.8, 0), soil)
	# Brunnenrand aus Stein mit Dach und Seil.
	for x in [WELL_X1 - 0.15, WELL_X2 + 0.15]:
		MapLook.box(self, Vector3(0.3, 0.6, 2.6), Vector3(x, 0.3, -0.2), rock)
		MapLook.box(self, Vector3(0.12, 2.2, 0.12), Vector3(x, 1.1, -1.2), wood)
	MapLook.box(self, Vector3(2.6, 0.12, 1.0), Vector3(-5.0, 2.25, -1.2), red, Vector3(0, 0, 0))
	MapLook.cylinder(self, 0.02, 3.0, Vector3(-5.0, 0.7, -1.2), MapLook.mat(Color(0.75, 0.65, 0.45)), -1.0, Vector3.ZERO, 5)

	_cave(col, soil, rock, wood, grass)

	# Marktstand: vier Pfosten, Theke hinten und ein gestreiftes Dach als Plattform.
	var roof := Vector3(0.6, 2.0, 0)
	MapLook.platform(col, Vector3(2.8, 0.3, 2.4), roof)
	for x in [-1.25, 1.25]:
		for z in [-1.0, 1.0]:
			MapLook.box(self, Vector3(0.14, 2.0, 0.14), Vector3(roof.x + x, 1.0, z), wood)
	for i in 6:
		MapLook.box(self, Vector3(0.5, 0.18, 2.6), Vector3(roof.x - 1.25 + i * 0.5, roof.y + 0.02, 0), red if i % 2 == 0 else white)
	MapLook.box(self, Vector3(2.6, 0.8, 0.5), Vector3(roof.x, 0.4, -0.9), wood)
	for i in 4:
		MapLook.sphere(self, 0.13, Vector3(roof.x - 0.9 + i * 0.55, 0.92, -0.9), orange if i % 2 else green)
	MapFX.cloth(self, Vector2(0.8, 0.5), Vector3(roof.x + 1.7, 2.6, -1.0), Color(0.2, 0.45, 0.85), null, false, 0.2)
	MapLook.cylinder(self, 0.03, 1.4, Vector3(roof.x + 1.3, 2.2, -1.0), wood)

	# Zwei kleine schwebende Inseln außen: links die Scheune, rechts der Kirchturm.
	for side in [-1, 1]:
		var cx: float = side * 12.2
		MapLook.solid(col, Vector3(4.0, 1.0, 3.6), Vector3(cx, 0.0, 0))
		MapLook.box(self, Vector3(4.2, 0.3, 3.8), Vector3(cx, 0.4, 0), grass)
		MapLook.box(self, Vector3(4.0, 0.8, 3.6), Vector3(cx, -0.1, 0), soil)
		var under := MapLook.cylinder(self, 0.3, 3.0, Vector3(cx, -2.0, -0.2), rock, 2.0, Vector3.ZERO, 8)
		under.scale = Vector3(1.0, 1.0, 0.8)
	# Scheune links: Heuboden als Plattform und das Dach ganz oben.
	var barn := -12.2
	MapLook.box(self, Vector3(3.0, 2.6, 2.0), Vector3(barn, 1.8, -0.8), red)
	MapLook.box(self, Vector3(1.0, 1.6, 0.08), Vector3(barn, 1.3, 0.22), wood)
	MapLook.platform(col, Vector3(3.2, 0.3, 2.2), Vector3(barn, 3.2, 0))
	MapLook.box(self, Vector3(3.3, 0.2, 2.2), Vector3(barn, 3.2, 0), wood)
	MapLook.sphere(self, 0.5, Vector3(barn - 0.8, 3.6, -0.5), MapLook.mat(Color(0.95, 0.85, 0.4), 1.0), Vector3(1.4, 0.7, 1.0))
	MapLook.platform(col, Vector3(2.4, 0.3, 2.0), Vector3(barn, 5.6, 0))
	MapLook.box(self, Vector3(3.6, 0.3, 2.4), Vector3(barn, 5.5, -0.3), MapLook.mat(Color(0.35, 0.2, 0.15)))
	MapLook.box(self, Vector3(3.2, 2.0, 1.2), Vector3(barn, 4.4, -1.2), red)
	# Kirchturm rechts: Glockenstube und Turmspitze.
	var tower := 12.2
	var yellow := MapLook.mat(Color(0.95, 0.85, 0.5))
	MapLook.box(self, Vector3(2.2, 6.4, 1.6), Vector3(tower, 3.7, -1.0), yellow)
	MapLook.box(self, Vector3(0.6, 1.0, 0.08), Vector3(tower, 1.0, -0.18), wood)
	MapLook.platform(col, Vector3(2.8, 0.3, 2.2), Vector3(tower, 3.8, 0))
	MapLook.box(self, Vector3(2.9, 0.2, 2.2), Vector3(tower, 3.8, 0), wood)
	MapLook.cylinder(self, 0.3, 0.6, Vector3(tower, 4.6, -0.6), MapLook.mat(Color(0.8, 0.6, 0.2), 0.3, 0.8), 0.18, Vector3.ZERO, 12)
	MapLook.platform(col, Vector3(2.4, 0.3, 2.0), Vector3(tower, 6.6, 0))
	MapLook.box(self, Vector3(2.5, 0.25, 2.0), Vector3(tower, 6.6, -0.2), red)
	MapLook.cylinder(self, 1.2, 2.2, Vector3(tower, 7.8, -1.0), red, 0.0, Vector3.ZERO, 4)
	MapLook.cylinder(self, 0.03, 0.8, Vector3(tower, 9.2, -1.0), MapLook.mat(Color(0.8, 0.6, 0.2), 0.3, 0.8), -1.0)

	# Heißluftballon: treibt hoch über dem Dorf hin und her, im Korb kann man stehen.
	var balloon := MovingPlatform.create($Platforms, Vector3(2.4, 0.3, 1.8), Vector3(-5.0, 7.6, 0), Vector3(5.0, 7.6, 0), 14.0)
	MapLook.box(balloon, Vector3(2.4, 0.6, 1.6), Vector3(0, -0.3, 0), MapLook.mat(Color(0.6, 0.42, 0.25)))
	MapLook.sphere(balloon, 1.6, Vector3(0, 3.2, -0.6), red, Vector3(1.0, 1.15, 0.9))
	for k in 2:
		MapLook.cylinder(balloon, 1.62 - k * 0.25, 0.3, Vector3(0, 3.2 + k * 1.0, -0.6), white if k == 0 else orange, -1.0,
			Vector3.ZERO, 24).scale = Vector3(1.0, 1.0, 0.9)
	for x in [-1.0, 1.0]:
		MapLook.cylinder(balloon, 0.02, 1.8, Vector3(x, 0.9, -0.3), MapLook.mat(Color(0.75, 0.65, 0.45)), -1.0, Vector3.ZERO, 4)

	# Stimmung: sonnig, Schmetterlinge, Vögel, fallende Blüten.
	var fx := MapFX.attach(self)
	fx.flock(Vector3(0, 12.0, -8.0), 5, Color(0.2, 0.2, 0.25), Vector3(16, 1.0, 5), 0.25, 0.4)
	fx.flock(Vector3(0, 1.6, 0.8), 4, Color(1.0, 0.85, 0.2), Vector3(7, 0.6, 1.0), 0.6, 0.18)
	MapLook.particles(self, Vector3(0, 11.0, 0), Vector3(20, 1, 4), Color(1.0, 0.75, 0.85, 0.95), 50,
		Vector3(0.8, -0.7, 0), 0.1, 12.0)
	MapFX.mood(self, Color(0.82, 0.9, 1.0), 0.004, 0.3, 1.18, 1.05)

	# Vordergrund: Blätter in den oberen Ecken.
	var fg := MapFX.foreground(self)
	var leaves := MapFX.surface("blaetter", Color(0.2, 0.42, 0.18))
	for side in [-1, 1]:
		MapLook.sphere(fg, 0.35, Vector3(side * 2.11, 1.22, -3.0), leaves, Vector3(1.5, 0.8, 0.6))
		MapLook.sphere(fg, 0.25, Vector3(side * 1.72, 1.26, -3.0), leaves, Vector3(1.4, 0.7, 0.6))
	MapLook.light(self, Vector3(0, 6.0, 4.0), Color(1, 0.95, 0.85), 0.5, 16.0)


## Brunnenhöhle unter dem Dorf: Erdwände mit Wurzeln, ein Wasserbecken unter dem Brunnen, Kartoffelkeller-Regale
## und Laternen. Im Brunnenschacht hängt ein Eimerbrett, außen wächst die Insel als Fels nach unten.
func _cave(col: Node3D, soil: Material, rock: Material, wood: Material, grass: Material) -> void:
	MapLook.solid(col, Vector3(CAVE_HALF * 2.0, 1.6, 4), Vector3(0, CAVE_Y - 0.8, 0))
	MapLook.box(self, Vector3(CAVE_HALF * 2.0 + 0.2, 1.7, 4.2), Vector3(0, CAVE_Y - 0.85, 0), rock)
	MapLook.box(self, Vector3(CAVE_HALF * 2.0 + 0.3, 0.12, 4.3), Vector3(0, CAVE_Y - 0.06, 0), soil)
	var island := MapLook.cylinder(self, 1.0, 7.0, Vector3(0, CAVE_Y - 5.0, -0.8), rock, CAVE_HALF + 0.5, Vector3.ZERO, 14)
	island.scale = Vector3(1.0, 1.0, 0.3)
	var h := -1.4 - CAVE_Y
	MapLook.box(self, Vector3(HALF * 2.0, h, 0.4), Vector3(0, CAVE_Y + h / 2.0, -2.0), MapLook.mat(Color(0.3, 0.22, 0.15)))
	# Wurzeln von der Decke.
	var root_mat := MapLook.mat(Color(0.35, 0.25, 0.15), 1.0)
	for x in [-7.0, -2.6, 1.4, 3.8, 6.6]:
		MapLook.cylinder(self, 0.06, 1.2, Vector3(x, -2.0, -1.4), root_mat, 0.02, Vector3(0, 0, 12), 5)
	# Wasserbecken unter dem Brunnen.
	MapLook.box(self, Vector3(2.6, 0.04, 2.0), Vector3(-5.0, CAVE_Y + 0.02, -0.6), MapLook.mat(Color(0.4, 0.7, 0.9, 0.7), 0.1, 0.0, 0.4))
	MapLook.light(self, Vector3(-5.0, -1.0, 0.5), Color(0.9, 0.95, 1.0), 0.8, 5.0)
	# Kellerregale mit Gläsern, Kartoffelsäcke und Laternen.
	for x in [2.5, 6.5]:
		for k in 3:
			MapLook.box(self, Vector3(1.8, 0.08, 0.5), Vector3(x, CAVE_Y + 0.5 + k * 0.7, -1.6), wood)
			for j in 3:
				MapLook.cylinder(self, 0.1, 0.3, Vector3(x - 0.5 + j * 0.5, CAVE_Y + 0.7 + k * 0.7, -1.6),
					MapLook.mat([Color(0.9, 0.5, 0.2), Color(0.7, 0.15, 0.2), Color(0.5, 0.7, 0.2)][j], 0.3), -1.0, Vector3.ZERO, 8)
	for x in [-8.6, 0.0]:
		MapLook.sphere(self, 0.4, Vector3(x, CAVE_Y + 0.35, -1.3), MapLook.mat(Color(0.75, 0.65, 0.45)), Vector3(1.0, 0.9, 0.8))
	for x in [-2.0, 4.5, 8.5]:
		MapLook.sphere(self, 0.15, Vector3(x, CAVE_Y + 2.4, -1.6), MapLook.mat(Color(1, 0.8, 0.4), 0.5, 0.0, 2.5))
		MapLook.light(self, Vector3(x, CAVE_Y + 2.2, -0.9), Color(1.0, 0.75, 0.4), 1.0, 4.5)
	# Eimerbrett im Brunnenschacht.
	var plank := Vector3(-5.0, -2.4, 0)
	MapLook.platform(col, Vector3(WELL_X2 - WELL_X1 - 0.2, 0.3, 1.6), plank)
	MapLook.box(self, Vector3(WELL_X2 - WELL_X1 - 0.1, 0.15, 1.6), plank, wood)
	MapLook.cylinder(self, 0.25, 0.4, plank + Vector3(0.4, 0.3, -0.3), MapFX.surface("holz", Color(0.45, 0.3, 0.18)), 0.3, Vector3.ZERO, 10)
	# Gras an den Höhlenkanten draußen.
	for side in [-1, 1]:
		MapLook.box(self, Vector3(2.0, 0.1, 3.8), Vector3(side * (CAVE_HALF - 1.0), CAVE_Y + 0.02, 0), grass)
	# Holzleiter außen: von der Höhlenkante wieder hinauf zur Insel.
	for side in [-1, 1]:
		var pos := Vector3(side * 9.4, -2.4, 0)
		MapLook.platform(col, Vector3(1.6, 0.3, 1.6), pos)
		MapLook.box(self, Vector3(1.7, 0.15, 1.6), pos, wood)
		MapLook.box(self, Vector3(0.1, 2.4, 0.1), pos + Vector3(side * 0.7, -1.2, -0.6), wood)
