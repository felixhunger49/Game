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
	MapLook.box(self, Vector3(0.9, 0.55, 0.04), Vector3(1.35, 6.7, -0.9), red)
	MapLook.light(self, Vector3(0, 4.2, 0.6), Color(1, 0.75, 0.45), 0.8, 4.0)
