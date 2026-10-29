class_name BouncePad
extends Area3D
## Feld, das Kämpfer nach oben befördert: als Sprungfeld (Riesenblüte im Dschungel) schleudert es
## sie hoch, als Aufwind (Lüftungsschacht in der Neonstadt) hebt es sie sanft an, solange sie drin sind.

## Geschwindigkeit nach oben.
var strength := 17.0
## true = sanfter Aufwind statt Schleudern.
var updraft := false
var visual: Node3D


static func create(parent: Node, size: Vector3, pos: Vector3, up_speed: float, gentle := false) -> BouncePad:
	var pad := BouncePad.new()
	pad.strength = up_speed
	pad.updraft = gentle
	pad.position = pos
	pad.collision_layer = 0
	pad.collision_mask = 4
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	pad.add_child(shape)
	parent.add_child(pad)
	return pad


func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if not body is CharacterBody3D or not body.visible:
			continue
		if updraft:
			body.velocity.y = move_toward(body.velocity.y, strength, 45.0 * delta)
		elif body.velocity.y <= 1.0:
			body.velocity.y = strength
			body.jumps_left = body.max_jumps
			Audio.sfx("jump", 0.7)
			if visual:
				var tween := visual.create_tween()
				tween.tween_property(visual, "scale", Vector3(1.25, 0.6, 1.25), 0.06)
				tween.tween_property(visual, "scale", Vector3.ONE, 0.25)
