class_name MovingPlatform
extends AnimatableBody3D
## Plattform, die zwischen zwei Punkten hin und her fährt (Hover-Taxi, Steinaufzug, schwebende Korallen).
## Wer darauf steht, fährt mit. Wie die schwebenden Plattformen kann man von unten durchspringen.

var from := Vector3.ZERO
var to := Vector3.ZERO
## Sekunden für einmal hin und zurück.
var period := 6.0
var time := 0.0


## Baut eine fahrende Plattform. Das Aussehen hängt man als Kinder an (Positionen relativ zur Plattform).
static func create(parent: Node, size: Vector3, a: Vector3, b: Vector3, seconds: float, phase := 0.0) -> MovingPlatform:
	var body := MovingPlatform.new()
	body.collision_layer = 0
	body.set_collision_layer_value(MapLook.PLATFORM_LAYER, true)
	body.sync_to_physics = true
	body.from = a
	body.to = b
	body.period = seconds
	body.time = phase * seconds
	body.position = a
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	return body


func _physics_process(delta: float) -> void:
	time += delta
	position = from.lerp(to, 0.5 - 0.5 * cos(time * TAU / period))
