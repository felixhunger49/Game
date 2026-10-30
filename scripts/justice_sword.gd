class_name JusticeSword
extends Node3D
## "Justice" (Spezial des Helden): ein goldener Lichtkreis erscheint unter dem Gegner, dann stürzt
## ein riesiges goldenes Lichtschwert vom Himmel und schlägt mit einer Lichtexplosion ein.

const WARN_TIME := 0.7
const FALL_SPEED := 30.0
const START_HEIGHT := 14.0
const RADIUS := 1.4
const GOLD := Color(1.0, 0.82, 0.3)

var shooter: CharacterBody3D
var age := 0.0
var marker: MeshInstance3D
var sword: Node3D
var done := false


func launch(from: CharacterBody3D, x: float, y: float) -> void:
	shooter = from
	global_position = Vector3(clampf(x, -11.0, 11.0), maxf(y, 0.0), 0)
	marker = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = 0.04
	marker.mesh = disc
	marker.material_override = SpecialFX._glow_material(Color(GOLD, 0.8), 1.4)
	add_child(marker)
	marker.position.y = 0.05
	sword = _build_sword()
	add_child(sword)
	sword.position.y = START_HEIGHT
	sword.visible = false
	Audio.sfx("special_ready", 1.2, -2.0)


## Riesiges Schwert aus Licht: Klinge, Parierstange, Griff und Knauf, Spitze nach unten.
func _build_sword() -> Node3D:
	var root := Node3D.new()
	var blade_mat := SpecialFX._glow_material(Color(1.0, 0.9, 0.55, 0.95), 2.2)
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = GOLD
	gold_mat.metallic = 0.9
	gold_mat.roughness = 0.25
	gold_mat.emission_enabled = true
	gold_mat.emission = GOLD
	gold_mat.emission_energy_multiplier = 0.8
	var parts := [
		[Vector3(0.42, 3.2, 0.1), Vector3(0, 1.6, 0), blade_mat],     # Klinge
		[Vector3(1.5, 0.22, 0.25), Vector3(0, 3.3, 0), gold_mat],     # Parierstange
		[Vector3(0.18, 0.8, 0.18), Vector3(0, 3.8, 0), gold_mat],     # Griff
		[Vector3(0.32, 0.32, 0.32), Vector3(0, 4.3, 0), gold_mat],    # Knauf
	]
	for p in parts:
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = p[0]
		m.mesh = box
		m.material_override = p[2]
		m.position = p[1]
		root.add_child(m)
	var tip := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.42, 0.5, 0.1)
	tip.mesh = prism
	tip.material_override = blade_mat
	tip.rotation.z = PI
	tip.position = Vector3(0, -0.25, 0)
	root.add_child(tip)
	var glow := MeshInstance3D.new()
	var outer := BoxMesh.new()
	outer.size = Vector3(0.9, 3.6, 0.4)
	glow.mesh = outer
	glow.material_override = SpecialFX._glow_material(Color(GOLD, 0.35), 1.5)
	glow.position = Vector3(0, 1.6, 0)
	root.add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = GOLD
	light.light_energy = 4.0
	light.omni_range = 5.0
	light.position = Vector3(0, 1.0, 0.5)
	root.add_child(light)
	return root


func _physics_process(delta: float) -> void:
	if done:
		return
	age += delta
	if age < WARN_TIME:
		marker.scale = Vector3.ONE * (0.8 + 0.2 * sin(age * 25.0))
		return
	sword.visible = true
	sword.position.y -= FALL_SPEED * delta
	if sword.position.y > 0.0:
		return
	done = true
	_impact()


func _impact() -> void:
	var world := get_parent()
	var center := global_position + Vector3(0, 0.6, 0)
	SpecialFX._flash_sphere(world, center, GOLD, 0.4, RADIUS * 1.6, 0.35)
	SpecialFX._flash_sphere(world, center, Color(1, 1, 1), 0.3, RADIUS, 0.18)
	SpecialFX._ring(world, global_position + Vector3(0, 0.1, 0), GOLD, 0.4, RADIUS * 2.2, 0.45)
	SpecialFX._sparks(world, center, GOLD, 80, 11.0, 0.7)
	SpecialFX._flash_light(world, center, GOLD, 9.0, 8.0, 0.4)
	SpecialFX.shake(shooter, 0.45, 0.4)
	Audio.sfx("special_hit")
	Audio.sfx("sword_clash", 0.8)
	marker.queue_free()
	for target in shooter._enemies():
		var offset: Vector3 = target.global_position + Vector3(0, 0.9, 0) - center
		if absf(offset.x) < RADIUS + 0.4 and absf(offset.y) < 2.2:
			var atk: Dictionary = shooter.ATTACKS.justice
			var side := 1.0 if offset.x >= 0.0 else -1.0
			if target.take_hit(atk, Vector3(atk.angle.x * side, atk.angle.y, 0).normalized(), shooter.power_time > 0.0,
					shooter.outgoing_multiplier()):
				shooter.add_special_energy(atk.damage * shooter.SPECIAL_PER_DAMAGE_DEALT)
				shooter.on_hit_landed(target)
	Target.hit_near(self, center, RADIUS + 0.6)
	# Das Schwert steckt kurz im Boden und verblasst.
	var tween := sword.create_tween()
	tween.tween_property(sword, "scale", Vector3(1, 0.01, 1), 0.5).set_delay(0.4)
	tween.tween_callback(queue_free)
