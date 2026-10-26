class_name BossRocket
extends Node3D
## Rakete des Riesen-Kampfroboters: erst blinkt ein roter Kreis am Boden (Zeit zum Ausweichen),
## dann fällt die Rakete vom Himmel und explodiert.

const WARN_TIME := 1.1
const FALL_SPEED := 22.0
const START_HEIGHT := 13.0
const RADIUS := 1.5
const ATTACK := {"damage": 9.0, "base": 6.0, "scale": 0.12, "angle": Vector2(0.6, 1.0)}

var shooter: CharacterBody3D
var target: CharacterBody3D
var ground_y := 0.0
var age := 0.0
var marker: MeshInstance3D
var rocket: Node3D


func launch(from: CharacterBody3D, victim: CharacterBody3D, x: float, y: float) -> void:
	shooter = from
	target = victim
	ground_y = y
	global_position = Vector3(x, y, 0)
	marker = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = 0.04
	marker.mesh = disc
	marker.material_override = SpecialFX._glow_material(Color(1, 0.15, 0.1, 0.7), 2.5)
	add_child(marker)
	marker.position.y = 0.05
	rocket = Node3D.new()
	add_child(rocket)
	rocket.position.y = START_HEIGHT
	var body := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = 0.22
	c.height = 0.5
	body.mesh = c
	var tip := StandardMaterial3D.new()
	tip.albedo_color = Color(0.85, 0.85, 0.9)
	tip.metallic = 0.6
	body.material_override = tip
	body.rotation.x = PI
	rocket.add_child(body)
	var tube := MeshInstance3D.new()
	var t := CylinderMesh.new()
	t.top_radius = 0.22
	t.bottom_radius = 0.22
	t.height = 0.9
	tube.mesh = t
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.8, 0.1, 0.1)
	tube.material_override = red
	tube.position.y = 0.7
	rocket.add_child(tube)
	var flame := SpecialFX._particles(Color(1, 0.6, 0.2), 30, 0.3, 0.25)
	flame.one_shot = false
	flame.explosiveness = 0.0
	flame.direction = Vector3.UP
	flame.initial_velocity_min = 2.0
	flame.initial_velocity_max = 4.0
	flame.position.y = 1.2
	rocket.add_child(flame)
	flame.emitting = true
	rocket.visible = false


func _physics_process(delta: float) -> void:
	age += delta
	if age < WARN_TIME:
		# Kreis pulsiert immer schneller.
		marker.scale = Vector3.ONE * (0.85 + 0.15 * sin(age * (8.0 + age * 14.0)))
		return
	rocket.visible = true
	rocket.position.y -= FALL_SPEED * delta
	if rocket.position.y > 0.3:
		return
	_explode()


func _explode() -> void:
	var world := get_parent()
	var center := global_position + Vector3(0, 0.5, 0)
	SpecialFX._flash_sphere(world, center, Color(1, 0.5, 0.15), 0.3, RADIUS * 1.3, 0.3)
	SpecialFX._ring(world, global_position + Vector3(0, 0.1, 0), Color(1, 0.4, 0.1), 0.3, RADIUS * 1.6, 0.35)
	SpecialFX._sparks(world, center, Color(1, 0.55, 0.15), 50, 9.0, 0.6)
	SpecialFX._flash_light(world, center, Color(1, 0.5, 0.2), 10.0, 6.0, 0.35)
	SpecialFX.shake(shooter, 0.25, 0.3)
	Audio.sfx("explosion", 1.2, -3.0)
	if target and target.visible:
		var offset := target.global_position + Vector3(0, 0.9, 0) - center
		if absf(offset.x) < RADIUS + 0.4 and absf(offset.y) < RADIUS + 0.6:
			var side := 1.0 if offset.x >= 0.0 else -1.0
			target.take_hit(ATTACK, Vector3(ATTACK.angle.x * side, ATTACK.angle.y, 0).normalized(), false,
				shooter.outgoing_multiplier())
	queue_free()
