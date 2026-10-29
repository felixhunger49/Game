extends Node3D
## Burg: großer Burghof mit den beiden Holzplattformen und dem Wehrturm in der Mitte. Links und rechts erheben sich
## die Wehrmauern mit Zinnen, darauf zwei Ecktürme mit spitzen Dächern. Unter dem Hof liegt das Burgverlies
## (außen über die Mauerkanten erreichbar, Holzgerüste führen wieder hinauf).

const HALF := 8.0
const WALL_X := 12.0
const WALL_Y := 2.0
const DUNGEON_Y := -4.8
const DUNGEON_HALF := 13.0


func _ready() -> void:
	var col := Node3D.new()
	add_child(col)
	var stone := MapLook.mat(Color(0.36, 0.34, 0.34))
	var stone_dark := MapLook.mat(Color(0.24, 0.22, 0.22))
	var stone_light := MapLook.mat(Color(0.5, 0.48, 0.46))
	var wood := MapLook.mat(Color(0.45, 0.3, 0.18))
	var red := MapLook.mat(Color(0.75, 0.12, 0.1))
	var roof := MapLook.mat(Color(0.32, 0.18, 0.2), 0.7)
	$Spawn1.position = Vector3(-3.0, 0.2, 0)
	$Spawn2.position = Vector3(3.0, 0.2, 0)
	MapLook.stage_area(self, Rect2(-15.2, DUNGEON_Y, 30.4, 8.4 - DUNGEON_Y), WALL_X)

	# Der Hofboden wird dünner (darunter ist das Verlies), die Fundamentsteine vorne verschwinden.
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(HALF * 2.0, 1.4, 4)
	$Stage/CollisionShape3D.shape = floor_shape
	$Stage/CollisionShape3D.position = Vector3(0, -0.7, 0)
	for node in $StageLook.get_children():
		if node.name.begins_with("floor_foundation") or node.name == "Core":
			node.queue_free()
	MapLook.box(self, Vector3(HALF * 2.0, 1.0, 4.0), Vector3(0, -0.9, 0), stone_dark)

	_dungeon(col, stone, stone_dark, wood)

	# Wehrmauern links und rechts mit Zinnen hinten und Ecktürmen.
	for side in [-1, 1]:
		var w := WALL_X - HALF
		var cx: float = side * (HALF + w / 2.0)
		var h := WALL_Y + 1.4
		MapLook.solid(col, Vector3(w, h, 4), Vector3(cx, WALL_Y - h / 2.0, 0))
		MapLook.box(self, Vector3(w, h, 4.2), Vector3(cx, WALL_Y - h / 2.0, 0), stone)
		MapLook.box(self, Vector3(w + 0.1, 0.15, 4.3), Vector3(cx, WALL_Y - 0.07, 0), stone_light)
		for i in 5:
			MapLook.box(self, Vector3(0.5, 0.6, 0.4), Vector3(cx - w / 2.0 + 0.4 + i * 0.8, WALL_Y + 0.3, -1.9), stone)
		MapLook.box(self, Vector3(0.6, 1.0, 0.08), Vector3(cx, WALL_Y - 1.2, 2.12), MapLook.mat(Color(0.08, 0.07, 0.07)))
		MapFX.cloth(self, Vector2(0.9, 1.8), Vector3(cx - side * 0.8, WALL_Y - 0.9, 2.15), Color(0.75, 0.12, 0.1) if side < 0 \
			else Color(0.15, 0.3, 0.7), null, true, 0.12)
		# Eckturm: Plattform oben, darüber das spitze Dach mit kleiner Spitze zum Draufstellen.
		var tx: float = side * 10.2
		var top_y := 5.0 if side < 0 else 5.4
		MapLook.box(self, Vector3(2.4, top_y - WALL_Y, 1.6), Vector3(tx, (WALL_Y + top_y) / 2.0, -1.4), stone)
		MapLook.box(self, Vector3(0.4, 0.8, 0.08), Vector3(tx, WALL_Y + 1.6, -0.58), MapLook.mat(Color(1, 0.75, 0.4), 0.5, 0.0, 1.5))
		MapLook.platform(col, Vector3(3.0, 0.3, 2.4), Vector3(tx, top_y, 0))
		MapLook.box(self, Vector3(3.2, 0.4, 2.6), Vector3(tx, top_y - 0.05, 0), stone)
		MapLook.box(self, Vector3(3.3, 0.15, 2.7), Vector3(tx, top_y - 0.32, 0), stone_dark)
		MapLook.cylinder(self, 1.5, 2.2, Vector3(tx, top_y + 1.3, -1.3), roof, 0.0, Vector3.ZERO, 8)
		MapLook.platform(col, Vector3(1.6, 0.3, 1.6), Vector3(tx, top_y + 2.6, 0))
		MapLook.box(self, Vector3(1.6, 0.2, 1.6), Vector3(tx, top_y + 2.55, -0.2), wood)
		MapLook.box(self, Vector3(0.05, 1.4, 0.05), Vector3(tx + 0.5, top_y + 3.3, -0.6), wood)
		MapFX.cloth(self, Vector2(0.8, 0.5), Vector3(tx + 0.9, top_y + 3.75, -0.6), Color(0.8, 0.12, 0.1) if side < 0 \
			else Color(0.15, 0.3, 0.7), null, false, 0.2)
		# Holzgerüst außen an der Mauer: von hier kommt man aus dem Verlies wieder hinauf.
		var sc := Vector3(side * 13.6, -1.6, 0)
		MapLook.platform(col, Vector3(2.2, 0.3, 2.0), sc)
		MapLook.box(self, Vector3(2.3, 0.15, 2.0), sc, wood)
		for k in [-1, 1]:
			MapLook.box(self, Vector3(0.14, 3.4, 0.14), sc + Vector3(k * 0.95, -1.7, -0.7), wood)
		MapLook.box(self, Vector3(0.1, 2.6, 0.1), sc + Vector3(0, -1.6, -0.7), wood, Vector3(0, 0, side * 40.0))

	# Turm hinten in der Mitte, oben eine Plattform mit Zinnen.
	var top := Vector3(0, 5.0, 0)
	MapLook.platform(col, Vector3(3.0, 0.3, 2.4), top)
	MapLook.box(self, Vector3(2.2, 5.0, 1.4), Vector3(0, 2.5, -1.5), stone)
	MapLook.box(self, Vector3(3.2, 0.4, 2.6), top + Vector3(0, -0.05, 0), stone)
	MapLook.box(self, Vector3(3.3, 0.15, 2.7), top + Vector3(0, -0.32, 0), stone_dark)
	for i in 4:
		MapLook.box(self, Vector3(0.5, 0.5, 0.4), Vector3(-1.2 + i * 0.8, 5.4, -1.1), stone)
	MapLook.box(self, Vector3(0.5, 0.9, 0.08), Vector3(0, 2.6, -0.78), wood)
	MapLook.box(self, Vector3(0.05, 1.8, 0.05), Vector3(0.9, 6.1, -0.9), wood)
	MapFX.cloth(self, Vector2(1.0, 0.6), Vector3(1.4, 6.7, -0.9), Color(0.8, 0.12, 0.1), null, false, 0.2)
	# Wehrgang hoch über dem Turm: eine Holzbrücke zwischen den Ecktürmen-Höhen.
	var walk := Vector3(0, 7.6, 0)
	MapLook.platform(col, Vector3(5.0, 0.3, 2.0), walk)
	MapLook.box(self, Vector3(5.1, 0.2, 2.0), walk, wood)
	for k in 6:
		MapLook.box(self, Vector3(0.1, 0.6, 0.1), walk + Vector3(-2.4 + k * 0.96, 0.4, -0.9), wood)
	MapLook.box(self, Vector3(5.1, 0.08, 0.1), walk + Vector3(0, 0.7, -0.9), wood)
	for side in [-1, 1]:
		MapLook.cylinder(self, 0.03, 2.2, walk + Vector3(side * 2.4, 1.1, -0.9), MapLook.mat(Color(0.2, 0.2, 0.22), 0.4, 0.7),
			-1.0, Vector3.ZERO, 5)

	# Stimmung: warmes Abendlicht, flackernde Fackeln, Tauben um den Turm, Glut über den Fackeln.
	var fx := MapFX.attach(self)
	fx.flicker_all($Lights, 0.3)
	fx.flicker_all(self, 0.15)
	fx.flock(Vector3(0, 11.0, -5.0), 5, Color(0.55, 0.55, 0.6), Vector3(12, 0.8, 3), 0.3, 0.35)
	MapLook.particles(self, Vector3(0, 3.5, -1.2), Vector3(9, 0.3, 0.3), Color(1, 0.6, 0.2, 0.9), 20,
		Vector3(0, 0.9, 0), 0.05, 2.0)
	MapFX.mood(self, Color(0.95, 0.65, 0.45), 0.004, 0.2, 1.08, 1.1, 0.82)

	# Vordergrund: Holzbalken in den oberen Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.box(fg, Vector3(1.2, 0.18, 0.2), Vector3(side * 2.02, 1.17, -3.0), MapLook.mat(Color(0.2, 0.13, 0.08)), Vector3(0, 0, side * 25.0))
	MapLook.light(self, Vector3(0, 4.2, 0.6), Color(1, 0.75, 0.45), 0.8, 4.0)
	MapLook.light(self, Vector3(0, 6.0, 4.0), Color(1, 0.8, 0.6), 0.6, 16.0)


## Burgverlies unter dem Hof und den Mauern: Gitterzellen, Ketten, Fackeln, Fässer und eine Schatztruhe.
func _dungeon(col: Node3D, stone: Material, dark: Material, wood: Material) -> void:
	MapLook.solid(col, Vector3(DUNGEON_HALF * 2.0, 1.6, 4), Vector3(0, DUNGEON_Y - 0.8, 0))
	MapLook.box(self, Vector3(DUNGEON_HALF * 2.0 + 0.2, 1.7, 4.2), Vector3(0, DUNGEON_Y - 0.85, 0), dark)
	MapLook.box(self, Vector3(DUNGEON_HALF * 2.0 + 0.3, 0.12, 4.3), Vector3(0, DUNGEON_Y - 0.06, 0), stone)
	var h := -1.4 - DUNGEON_Y
	MapLook.box(self, Vector3(WALL_X * 2.0, h, 0.4), Vector3(0, DUNGEON_Y + h / 2.0, -2.0), MapLook.mat(Color(0.16, 0.14, 0.14)))
	MapLook.box(self, Vector3(DUNGEON_HALF * 2.0 - 1.0, 2.0, 3.6), Vector3(0, DUNGEON_Y - 2.6, 0), dark)
	var iron := MapLook.mat(Color(0.2, 0.2, 0.22), 0.4, 0.7)
	# Gitterzellen an der Rückwand.
	for x in [-9.0, -4.5, 4.5, 9.0]:
		MapLook.box(self, Vector3(2.2, 2.4, 0.1), Vector3(x, DUNGEON_Y + 1.2, -1.75), MapLook.mat(Color(0.06, 0.05, 0.05)))
		for k in 6:
			MapLook.box(self, Vector3(0.05, 2.4, 0.05), Vector3(x - 1.0 + k * 0.4, DUNGEON_Y + 1.2, -1.65), iron)
		MapLook.box(self, Vector3(2.3, 0.08, 0.08), Vector3(x, DUNGEON_Y + 2.4, -1.65), iron)
	# Säulen, Ketten an der Decke, Fackeln.
	for x in [-11.0, -6.8, -2.2, 2.2, 6.8, 11.0]:
		MapLook.box(self, Vector3(0.5, h, 0.5), Vector3(x, DUNGEON_Y + h / 2.0, -1.5), stone)
	for x in [-1.0, 0.6, 7.6]:
		MapLook.cylinder(self, 0.03, 1.2, Vector3(x, -2.0, -1.0), iron, -1.0, Vector3.ZERO, 5)
		MapLook.box(self, Vector3(0.25, 0.25, 0.1), Vector3(x, -2.65, -1.0), iron)
	for x in [-6.8, 2.2, 11.0]:
		MapLook.prop(self, "res://assets/maps/burg/torch_mounted.glb", Vector3(x, DUNGEON_Y + 1.8, -1.15), 0.8)
		MapLook.light(self, Vector3(x, DUNGEON_Y + 2.4, -0.6), Color(1.0, 0.65, 0.3), 1.2, 5.0)
	# Fässer, Kisten und eine Schatztruhe.
	MapLook.prop(self, "res://assets/maps/burg/barrel_small_stack.glb", Vector3(-11.8, DUNGEON_Y, -1.2), 1.0)
	MapLook.prop(self, "res://assets/maps/burg/crates_stacked.glb", Vector3(11.7, DUNGEON_Y, -1.2), 1.2)
	MapLook.prop(self, "res://assets/maps/burg/chest_gold.glb", Vector3(0, DUNGEON_Y, -1.3), 0.7)
	MapLook.light(self, Vector3(0, DUNGEON_Y + 1.0, 0.2), Color(1.0, 0.8, 0.4), 0.8, 3.5)
	MapLook.particles(self, Vector3(0, DUNGEON_Y + 1.5, -0.5), Vector3(10, 1.0, 1.0), Color(0.8, 0.75, 0.65, 0.5), 20,
		Vector3(0, 0.1, 0), 0.04, 4.0)
