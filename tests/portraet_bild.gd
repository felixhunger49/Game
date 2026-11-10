extends Node
## Hilfsskript: macht von jedem Kämpfer ein Kopfbild (für die Anzeige im Kampf).
## Aufruf (mit Fenster): godot res://tests/portraet_bild.tscn
## Die Bilder landen in assets/portraits/<name>.png.

const SIZE := 256


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/portraits")
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.9)
	env.ambient_light_energy = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 35, 0)
	sun.light_energy = 1.3
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	var scene: PackedScene = load("res://scenes/player.tscn")
	for i in Roster.count():
		var p: CharacterBody3D = scene.instantiate()
		vp.add_child(p)
		p.set_physics_process(false)
		p.set_fighter(i)
		p.get_node("Tag").visible = false
		p.get_node("Shield").visible = false
		# Etwas zur Seite gedreht sieht ein Gesicht lebendiger aus.
		p.get_node("Model").rotation_degrees.y = 25.0
		await get_tree().create_timer(0.4).timeout
		var head := _head(p)
		cam.position = head + Vector3(0.1, 0.02, 1.75)
		cam.look_at(head)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.save_png("res://assets/portraits/%s.png" % Roster.slug(p.fighter.name))
		print("Bild: ", p.fighter.name, " Kopf bei ", head)
		p.queue_free()
		await get_tree().process_frame
	get_tree().quit()


## Mitte des Kopfes: der Kopfknochen, sonst eine übliche Höhe.
func _head(p: Node3D) -> Vector3:
	var sk: Skeleton3D = p.find_child("Skeleton3D", true, false)
	if sk:
		for bone in ["mixamorig_Head", "head", "Head"]:
			var b := sk.find_bone(bone)
			if b >= 0:
				var pos: Vector3 = sk.global_transform * sk.get_bone_global_pose(b).origin
				return pos + Vector3(0, 0.12, 0)
	return p.global_position + Vector3(0, 1.45, 0)
