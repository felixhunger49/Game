class_name BossAI
extends CpuPlayer
## Endboss "Riesen-Kampfroboter": kämpft wie der Computer (Stufe Schwer) und hat dazu eigene Angriffe:
## - Laser aus dem Bauch in festen Abständen (man kann darüber springen),
## - Raketenregen: rote Kreise am Boden, kurz danach schlagen Raketen ein,
## - Overcharge (seine Passive) alle paar Sekunden.
## Ab halber Lebensleiste wird er WÜTEND: glüht rot, ist schneller und schießt öfter.

const PHASES := [
	{"laser": 7.0, "rockets": 6.0, "volley": 3, "speed": 1.0},
	{"laser": 4.5, "rockets": 3.5, "volley": 5, "speed": 1.25},
]

var phase := 0
var laser_timer := 4.0
var rocket_timer := 3.0
var rage_light: OmniLight3D


func setup(player: CharacterBody3D, opponent: CharacterBody3D, _difficulty: int) -> void:
	super.setup(player, opponent, 2)
	# Blockt seltener als der normale Computer, sonst wird es zäh.
	level = LEVELS[2].duplicate()
	level.block = 0.2


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if me == null or not me.controls_enabled:
		return
	if phase == 0 and me.boss_hp <= me.boss_hp_max * 0.5:
		_enrage()
	var p: Dictionary = PHASES[phase]
	laser_timer -= delta
	rocket_timer -= delta
	if laser_timer <= 0.0 and me.attack_timer <= 0.0 and me.hitstun <= 0.0:
		laser_timer = p.laser * randf_range(0.85, 1.15)
		me.special_energy = me.SPECIAL_MAX
		_turn_to("right" if foe.global_position.x > me.global_position.x else "left")
		_tap("special")
	if rocket_timer <= 0.0:
		rocket_timer = p.rockets * randf_range(0.85, 1.15)
		_rocket_volley(p.volley)


## Mehrere Raketen: eine genau auf den Spieler, die anderen daneben verteilt.
func _rocket_volley(count: int) -> void:
	var world := me.get_parent()
	var ground := 0.0 if foe.global_position.y < 1.0 else foe.global_position.y
	for i in count:
		var x: float = foe.global_position.x + (0.0 if i == 0 else randf_range(-6.0, 6.0))
		var r := BossRocket.new()
		world.add_child(r)
		r.launch(me, foe, clampf(x, -9.0, 9.0), ground if i == 0 else 0.0)
	Audio.sfx("warning", 0.8, -4.0)


## Wütend: rotes Glühen, schneller, schießt öfter.
func _enrage() -> void:
	phase = 1
	level = LEVELS[2].duplicate()
	level.reaction *= 0.7
	me.speed *= PHASES[1].speed
	SpecialFX.popup(me, "WÜTEND!", Color(1, 0.2, 0.1))
	SpecialFX.shake(me, 0.5, 0.6)
	Audio.sfx("thunder", 0.8)
	rage_light = OmniLight3D.new()
	rage_light.light_color = Color(1, 0.15, 0.1)
	rage_light.light_energy = 3.0
	rage_light.omni_range = 4.0
	rage_light.position = Vector3(0, 2.0, 0.8)
	me.add_child(rage_light)
	for mi in me.model_root.find_children("*", "MeshInstance3D", true, false):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0.2, 0.1, 0.25)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_overlay = mat
