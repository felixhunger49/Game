extends Node3D
## Burg: zusätzlich zu den beiden Holzplattformen ein Wehrturm in der Mitte mit Zinnen,
## auf dessen Spitze man mit Doppelsprung kommt.


func _ready() -> void:
	var col := Node3D.new()
	add_child(col)
	var stone := MapLook.mat(Color(0.36, 0.34, 0.34))
	var stone_dark := MapLook.mat(Color(0.24, 0.22, 0.22))
	var wood := MapLook.mat(Color(0.45, 0.3, 0.18))
	var red := MapLook.mat(Color(0.75, 0.12, 0.1))

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

	# Stimmung: warmes Abendlicht, flackernde Fackeln, Tauben um den Turm, Glut über den Fackeln.
	var fx := MapFX.attach(self)
	fx.flicker_all($Lights, 0.3)
	fx.flicker_all(self, 0.15)
	fx.flock(Vector3(0, 9.0, -5.0), 5, Color(0.55, 0.55, 0.6), Vector3(9, 0.8, 3), 0.3, 0.35)
	MapLook.particles(self, Vector3(0, 3.5, -1.2), Vector3(7, 0.3, 0.3), Color(1, 0.6, 0.2, 0.9), 20,
		Vector3(0, 0.9, 0), 0.05, 2.0)
	MapFX.mood(self, Color(0.95, 0.65, 0.45), 0.006, 0.45, 1.12, 1.05)

	# Vordergrund: Holzbalken in den oberen Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.box(fg, Vector3(1.2, 0.18, 0.2), Vector3(side * 2.02, 1.17, -3.0), MapLook.mat(Color(0.2, 0.13, 0.08)), Vector3(0, 0, side * 25.0))
	MapLook.light(self, Vector3(0, 4.2, 0.6), Color(1, 0.75, 0.45), 0.8, 4.0)
