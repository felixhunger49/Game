extends CharacterBody3D

## Wird ausgelöst, wenn die Figur aus der Arena gefallen ist.
signal fell_off(player)
## Nur beim Endboss: seine Lebensleiste ist leer.
signal boss_defeated

## 1 oder 2: bestimmt, welche Tasten die Figur steuern (p1_... oder p2_...).
@export var player_id := 1
@export var color := Color(1, 0.82, 0.4)
@export var start_facing := 1
@export var speed := 7.0
@export var jump_velocity := 13.0
@export var gravity := 30.0
@export var max_jumps := 2

## Die Angriffe. damage = Schaden in %, base/scale = Rückstoß (base + Schaden * scale),
## range = Reichweite nach vorne und nach oben/unten, startup = Ausholzeit bis zum Treffer,
## cooldown = Zeit bis zum nächsten Angriff, angle = Flugrichtung des Getroffenen.
const ATTACKS := {
	"weak": {"damage": 4.0, "base": 3.0, "scale": 0.07, "range": Vector2(1.5, 1.2), "startup": 0.05,
		"cooldown": 0.25, "angle": Vector2(1, 0.35), "anim_speed": 2.2},
	"strong": {"damage": 13.0, "base": 6.5, "scale": 0.22, "range": Vector2(1.9, 1.4), "startup": 0.3,
		"cooldown": 0.75, "angle": Vector2(1, 0.7), "anim_speed": 1.4},
	"kick": {"damage": 8.0, "base": 5.0, "scale": 0.15, "range": Vector2(1.7, 1.0), "startup": 0.12,
		"cooldown": 0.45, "angle": Vector2(1, 0.25), "anim_speed": 1.8},
	"feuerball": {"damage": 9.0, "base": 4.0, "scale": 0.12, "startup": 0.2, "cooldown": 1.0,
		"angle": Vector2(1, 0.3), "anim_speed": 1.6},
	"sturm": {"damage": 10.0, "base": 5.5, "scale": 0.16, "range": Vector2(1.3, 1.2), "startup": 0.05,
		"cooldown": 1.0, "angle": Vector2(1, 0.4), "anim_speed": 1.6},
	"wirbel": {"damage": 11.0, "base": 6.0, "scale": 0.18, "range": Vector2(2.2, 1.5), "startup": 0.15,
		"cooldown": 1.1, "angle": Vector2(1, 0.8), "anim_speed": 1.5},
	"aufwaerts": {"damage": 9.0, "base": 6.0, "scale": 0.15, "range": Vector2(1.4, 2.8), "startup": 0.1,
		"cooldown": 0.9, "angle": Vector2(0.2, 1), "anim_speed": 1.6},
	# Paladin: 1,6 s unverwundbar in einer Lichtkuppel, dann explodiert sie.
	"lichtschild": {"damage": 12.0, "base": 7.0, "scale": 0.18, "range": Vector2(2.8, 2.2), "startup": 1.6,
		"cooldown": 1.8, "angle": Vector2(1, 0.6), "anim_speed": 1.0},
	# Brummbart: kleiner Sprung, dann Stampfer, dessen Schockwelle über den Boden läuft.
	"erdbeben": {"damage": 12.0, "base": 7.5, "scale": 0.16, "range": Vector2(4.5, 1.3), "startup": 0.4,
		"cooldown": 1.0, "angle": Vector2(0.25, 1), "anim_speed": 1.2},
	# Hexe: grüne Zauberkugel, verwandelt den Gegner kurz in ein Schwein (siehe pigify).
	"schwein": {"damage": 5.0, "base": 2.5, "scale": 0.04, "startup": 0.2, "cooldown": 1.0,
		"angle": Vector2(1, 0.3), "anim_speed": 1.6},
	# Frostkugel, friert den Gegner ein.
	"frost": {"damage": 7.0, "base": 2.0, "scale": 0.05, "startup": 0.2, "cooldown": 1.0,
		"angle": Vector2(1, 0.2), "anim_speed": 1.6},
	# Mönch: sechs blitzschnelle Faustschläge, der letzte schleudert weg (siehe FLURRY_*).
	"hundert_faeuste": {"damage": 2.5, "base": 1.2, "scale": 0.0, "range": Vector2(1.7, 1.4), "startup": 0.08,
		"cooldown": 0.9, "angle": Vector2(1, 0.15), "anim_speed": 2.5},
	# Piratin: Kanonenkugel im Bogen, explodiert (siehe Cannonball).
	"breitseite": {"damage": 13.0, "base": 7.0, "scale": 0.17, "startup": 0.25, "cooldown": 1.0,
		"angle": Vector2(1, 0.6), "anim_speed": 1.4},
	# Kampfroboter: lädt im Bauch auf und schießt dann einen Laserstrahl quer über die Arena.
	"laser": {"damage": 12.0, "base": 6.5, "scale": 0.17, "range": Vector2(10.0, 1.3), "startup": 0.45,
		"cooldown": 1.1, "angle": Vector2(1, 0.3), "anim_speed": 1.0},
	# Jägerin: Pfeilregen auf die Stelle, an der der Gegner steht.
	"pfeilregen": {"damage": 4.0, "base": 2.5, "scale": 0.08, "startup": 0.25, "cooldown": 0.9,
		"angle": Vector2(0.4, -0.2), "anim_speed": 1.4},
}

## Passive Fähigkeiten: wirken immer, ohne Taste. Beschreibungen stehen in Roster.PASSIVES.
const GIFT_TIME := 3.0
const GIFT_DAMAGE_PER_SECOND := 2.0
const HEAL_DELAY := 3.0
const HEAL_PER_SECOND := 0.7
const GLIDE_FALL_SPEED := 2.5
const CRIT_CHANCE := 0.25
## Hundert Fäuste: so viele Schläge im Abstand von FLURRY_INTERVAL, der letzte mit FLURRY_FINISH.
const FLURRY_HITS := 6
const FLURRY_INTERVAL := 0.11
const FLURRY_FINISH := {"damage": 7.0, "base": 7.5, "scale": 0.18, "range": Vector2(1.8, 1.5), "angle": Vector2(1, 0.5)}
## Innere Ruhe: wer still steht, lädt die Spezialattacke so viel schneller.
const STILL_CHARGE_FACTOR := 2.0
## Plündern: so viel Spezial-Energie stiehlt die Piratin pro Treffer.
const PLUNDER_ENERGY := 8.0
## Schweinezauber (Hexe): so lange ist der Gegner ein Schwein (kann nicht angreifen, langsamer, nimmt mehr Schaden).
const PIG_TIME := 3.0
const PIG_DAMAGE_TAKEN := 1.3
## Overcharge (Kampfroboter): alle OVERCHARGE_INTERVAL Sekunden ein Stromschlag rundherum,
## OVERCHARGE_WARN Sekunden vorher knistert es blau als Warnung.
const OVERCHARGE_INTERVAL := 7.0
const OVERCHARGE_WARN := 0.8
const OVERCHARGE := {"damage": 3.0, "base": 3.5, "scale": 0.06, "range": Vector2(2.4, 2.0), "angle": Vector2(1, 0.6)}
## Schildmeister: nach einem abgewehrten Treffer ist der nächste Angriff so lange verstärkt.
const COUNTER_TIME := 1.5
const COUNTER_BONUS := 0.6

## Alles außerhalb dieses Bereichs zählt als heruntergefallen (x links, y unten, Breite, Höhe).
const BLAST_ZONE := Rect2(-19, -10, 38, 28)
## Die Figuren drehen sich nicht ganz zur Seite, damit man ihr Gesicht sieht (wie bei Smash Bros.).
const SIDE_ANGLE := deg_to_rad(70)
## Physik-Ebene, auf der die schwebenden Plattformen liegen (man kann von unten durchspringen).
const PLATFORM_LAYER := 2
const SHIELD_MAX := 100.0
const POWER_MULTIPLIER := 1.4
## Energie für die Spezialattacke: füllt sich mit der Zeit, durch Treffen und durch Getroffenwerden.
const SPECIAL_MAX := 100.0
const SPECIAL_PER_SECOND := 5.0
const SPECIAL_PER_DAMAGE_DEALT := 3.5
const SPECIAL_PER_DAMAGE_TAKEN := 2.0
const SPECIAL_KINDS := ["feuerball", "sturm", "wirbel", "aufwaerts", "lichtschild", "erdbeben", "frost", "pfeilregen",
	"hundert_faeuste", "breitseite", "laser", "schwein"]
const SHOUTS := ["ha", "hja", "hah"]

## Kunststücke am höchsten Punkt eines Sprungs. axis: Drehachse der Figur (x = Salto vorwärts,
## -x = rückwärts, y = Pirouette, z = Rad), turns = Umdrehungen, time = Dauer in Sekunden.
## hover: schwebt währenddessen kurz in der Luft.
const FLIPS := {
	"salto": {"axis": Vector3(1, 0, 0), "turns": 1.0, "time": 0.45},
	"rueckwaerts": {"axis": Vector3(-1, 0, 0), "turns": 1.0, "time": 0.5},
	"doppelsalto": {"axis": Vector3(1, 0, 0), "turns": 2.0, "time": 0.6},
	"doppel_rueckwaerts": {"axis": Vector3(-1, 0, 0), "turns": 2.0, "time": 0.65},
	"rad": {"axis": Vector3(0, 0, 1), "turns": 1.0, "time": 0.5},
	"pirouette": {"axis": Vector3(0, 1, 0), "turns": 2.0, "time": 0.55},
	"schraube": {"axis": Vector3(1, 1, 0), "turns": 1.0, "time": 0.6},
	"purzeln": {"axis": Vector3(1, 0, 1), "turns": 1.0, "time": 0.6},
	"schweben": {"axis": Vector3(0, 1, 0), "turns": 1.0, "time": 0.9, "hover": true},
	"propeller": {"axis": Vector3(0, 1, 0), "turns": 3.0, "time": 0.6},
}
## Doppelt tippen: zwei Tastendrücke innerhalb dieser Zeit (Sekunden).
const DOUBLE_TAP_TIME := 0.25
## Ausweichrolle: Dauer, Geschwindigkeit und Wartezeit bis zur nächsten Rolle.
const ROLL_TIME := 0.35
const ROLL_SPEED := 12.0
const ROLL_COOLDOWN := 0.6
## So lange fällt man nach doppeltem Runter durch eine Plattform.
const DROP_TIME := 0.45

## Höhe der Körpermitte: um diesen Punkt drehen sich die Kunststücke.
const FLIP_PIVOT_HEIGHT := 0.9
const CLOTH_SHADER := preload("res://scripts/cloth.gdshader")

var opponent: CharacterBody3D
var fighter: Dictionary = {}
var controls_enabled := false
var damage := 0.0
var stocks := 3
var facing := 1
var jumps_left := 0
var hitstun := 0.0
var stunned := 0.0
var attack_timer := 0.0
var pending_attack := ""
var pending_time := 0.0
var dash_time := 0.0
var dash_hit_done := false
var special_air_used := false
var shielding := false
var shield_hp := SHIELD_MAX
var power_time := 0.0
var speed_time := 0.0
var special_energy := 0.0
## Windgeschwindigkeit der Map (Dorf): schiebt die Figur zur Seite.
var wind_speed := 0.0
## Wie gut man am Boden Halt findet (1 = normal, weniger = glatt wie Eis).
var ground_grip := 1.0
var spawn_position := Vector3.ZERO
var anim_player: AnimationPlayer
var current_anim := ""
## Drehpunkt in der Körpermitte für Saltos; darunter hängt das Modell.
var flip_pivot: Node3D
var flip_time := -1.0
var jumped := false
var was_rising := false
## Materialien der flatternden Teile (Umhänge, Hutspitzen, Haare).
var cloth_materials: Array[ShaderMaterial] = []
var fall_wind := 0.0
## Zeitpunkt des letzten Tastendrucks je Richtung, um doppeltes Tippen zu erkennen.
var last_tap := {"left": -1.0, "right": -1.0, "shield": -1.0}
var roll_time := 0.0
var roll_dir := 1
var roll_cooldown := 0.0
var drop_time := 0.0
var on_platform := false
## Leuchtende Funken um die Füße, solange die Spezialattacke bereit ist.
var ready_aura: CPUParticles3D
## Passive Fähigkeit des Kämpfers (siehe Roster.PASSIVES).
var passive := ""
var base_speed := 0.0
var base_jump := 0.0
var base_jumps := 0
## Lichtkuppel des Paladins: solange > 0, prallen alle Treffer ab.
var dome_time := 0.0
var dome: MeshInstance3D
var frozen := 0.0
var pig_time := 0.0
var pig: Node3D
var ice_block: MeshInstance3D
var poison_time := 0.0
var poison_fx: CPUParticles3D
var since_hit := 0.0
## Endboss: hat Lebenspunkte statt Prozent, ist größer, wird kaum weggeschleudert und hat mehr Reichweite.
var boss := false
var boss_hp := 0.0
var boss_hp_max := 0.0
var reach_scale := 1.0
var size_scale := 1.0
var overcharge_time := 0.0
var overcharge_warned := false
var counter_time := 0.0
var flurry_left := 0
var flurry_timer := 0.0
var still_time := 0.0

@onready var model_root: Node3D = $Model
@onready var tag: Label3D = $Tag
@onready var shield_bubble: MeshInstance3D = $Shield


func _ready() -> void:
	base_speed = speed
	base_jump = jump_velocity
	base_jumps = max_jumps
	spawn_position = position
	facing = start_facing
	jumps_left = max_jumps
	tag.modulate = color
	var mat: StandardMaterial3D = shield_bubble.material_override.duplicate()
	mat.albedo_color = Color(color, 0.35)
	mat.emission = color
	shield_bubble.material_override = mat
	shield_bubble.visible = false
	_create_ready_aura()


## Tauscht das 3D-Modell gegen den Kämpfer an Stelle `index` im Roster.
func set_fighter(index: int) -> void:
	fighter = Roster.get_fighter(index)
	_apply_passive()
	for child in model_root.get_children():
		model_root.remove_child(child)
		child.queue_free()
	current_anim = ""
	flip_time = -1.0

	flip_pivot = Node3D.new()
	flip_pivot.position.y = FLIP_PIVOT_HEIGHT
	model_root.add_child(flip_pivot)
	var model: Node3D = load(fighter.scene).instantiate()
	flip_pivot.add_child(model)
	model.position.y = -FLIP_PIVOT_HEIGHT
	_setup_weapons(model)
	_setup_cloth(model)
	model.scale = Vector3.ONE * fighter.get("scale", 0.8)
	model.rotation_degrees.y = fighter.get("rotation_y", 0.0)

	anim_player = model.find_child("AnimationPlayer", true, false)
	_load_anim_files()
	if anim_player:
		for action in ["idle", "run", "jump", "fall", "shield", "stunned"]:
			if action == "jump" and fighter.has("anim_dir"):
				continue  # Mixamo-Sprung ist ein einmaliger Absprung, danach kommt "fall"
			var anim_name := Roster.anim_name(fighter, action)
			if anim_player.has_animation(anim_name):
				anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	_play("idle")


func _physics_process(delta: float) -> void:
	attack_timer = max(attack_timer - delta, 0.0)
	hitstun = max(hitstun - delta, 0.0)
	stunned = max(stunned - delta, 0.0)
	power_time = max(power_time - delta, 0.0)
	speed_time = max(speed_time - delta, 0.0)
	roll_cooldown = max(roll_cooldown - delta, 0.0)
	drop_time = max(drop_time - delta, 0.0)
	if controls_enabled:
		add_special_energy(SPECIAL_PER_SECOND * delta)
		# Mönch: Still stehen = meditieren, die Leiste füllt sich schneller.
		if passive == "innere_ruhe" and is_on_floor() and absf(velocity.x) < 0.3 and attack_timer == 0.0 \
				and hitstun == 0.0:
			still_time += delta
			if still_time > 0.3:
				add_special_energy(SPECIAL_PER_SECOND * (STILL_CHARGE_FACTOR - 1.0) * delta)
		else:
			still_time = 0.0
	_update_flurry(delta)
	_update_passive(delta)
	_update_status_effects(delta)

	velocity.y -= gravity * delta
	# Von unten durch die schwebenden Plattformen springen, beim Fallen darauf landen.
	# Nach doppeltem Runter fällt man kurz durch sie hindurch.
	set_collision_mask_value(PLATFORM_LAYER, velocity.y <= 0.0 and drop_time <= 0.0)
	if is_on_floor():
		jumps_left = max_jumps
		special_air_used = false
		jumped = false

	_update_pending_attack(delta)
	_update_dash(delta)

	var can_act := controls_enabled and hitstun == 0.0 and stunned == 0.0
	if can_act and roll_time <= 0.0 and dash_time <= 0.0:
		_check_double_taps()
	shielding = can_act and pig_time <= 0.0 and is_on_floor() and Input.is_action_pressed(_action("shield")) and shield_hp > 0.0 \
		and roll_time <= 0.0 and drop_time <= 0.0
	if shielding:
		shield_hp = max(shield_hp - 18.0 * delta * (0.5 if passive == "schildmeister" else 1.0), 0.0)
	else:
		shield_hp = min(shield_hp + 12.0 * delta, SHIELD_MAX)

	if hitstun > 0.0:
		# Getroffen: keine Kontrolle, die Figur fliegt weiter.
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta) + wind_speed * delta
	elif dash_time > 0.0:
		pass
	elif roll_time > 0.0:
		_update_roll(delta)
	elif can_act and not shielding:
		_handle_input(delta)
	else:
		velocity.x = move_toward(velocity.x, wind_speed * 0.5, 60.0 * (ground_grip if is_on_floor() else 1.0) * delta)
		if shielding and Input.is_action_just_pressed(_action("jump")):
			velocity.y = jump_velocity
			jumps_left -= 1
			Audio.sfx("jump")

	# Kunststück am höchsten Punkt eines Sprungs (nicht beim Wegfliegen nach einem Treffer).
	var rising := velocity.y > 0.0 and not is_on_floor()
	if was_rising and not rising and jumped and flip_time < 0.0 and hitstun == 0.0 and dash_time <= 0.0 \
			and pending_attack == "" and not is_on_floor():
		_start_flip()
	was_rising = rising
	if flip_time >= 0.0 and FLIPS[fighter.get("flip", "salto")].get("hover", false):
		velocity.y = maxf(velocity.y, -1.5)
	# Hexe: Sprungtaste in der Luft halten zum Gleiten.
	if passive == "gleiten" and not is_on_floor() and velocity.y < -GLIDE_FALL_SPEED and can_act \
			and Input.is_action_pressed(_action("jump")):
		velocity.y = -GLIDE_FALL_SPEED

	move_and_slide()
	on_platform = false
	if is_on_floor():
		for i in get_slide_collision_count():
			var body := get_slide_collision(i).get_collider() as CollisionObject3D
			if body and body.get_collision_layer_value(PLATFORM_LAYER):
				on_platform = true
	_update_visuals(delta)

	if not BLAST_ZONE.has_point(Vector2(position.x, position.y)):
		_lose_stock()


func _handle_input(delta: float) -> void:
	var direction := Input.get_axis(_action("left"), _action("right"))
	var top_speed := speed * (1.4 if speed_time > 0.0 else 1.0) * (0.75 if pig_time > 0.0 else 1.0)
	var accel := 60.0 * ground_grip if is_on_floor() else 28.0
	if attack_timer > 0.0 and is_on_floor():
		# Beim Zuschlagen bleibt man fast stehen.
		direction = 0.0
	# Wind schiebt in der Luft stärker als am Boden.
	var wind := wind_speed * (0.6 if is_on_floor() else 1.0)
	velocity.x = move_toward(velocity.x, direction * top_speed + wind, accel * delta)
	if direction != 0.0:
		facing = int(sign(direction))

	if Input.is_action_just_pressed(_action("jump")) and jumps_left > 0:
		velocity.y = jump_velocity * (1.12 if speed_time > 0.0 else 1.0)
		Audio.sfx("jump", 1.0 if jumps_left == max_jumps else 1.25)
		jumps_left -= 1
		jumped = true
		# Ein neuer Sprung bricht ein laufendes Kunststück nicht ab, startet aber oben ein neues.
		if flip_time >= 0.0:
			_end_flip()

	if attack_timer > 0.0 or pig_time > 0.0:
		return
	for kind in ["weak", "strong", "kick"]:
		if Input.is_action_just_pressed(_action(kind)):
			start_attack(kind)
			return
	if Input.is_action_just_pressed(_action("special")):
		start_special()


## Holt zum Angriff aus. Der Treffer kommt nach der Ausholzeit (startup).
func start_attack(kind: String) -> void:
	var atk: Dictionary = ATTACKS[kind]
	attack_timer = atk.cooldown
	pending_attack = kind
	pending_time = atk.startup
	_end_flip()
	_play(kind, atk.anim_speed)
	match kind:
		"weak":
			Audio.sfx("swing_weak")
		"strong":
			Audio.sfx("swing_strong")
			_shout()
		"kick":
			Audio.sfx("kick")


func start_special() -> void:
	var kind: String = fighter.get("special", "feuerball")
	if not special_ready():
		# Noch nicht aufgeladen.
		Audio.sfx("fizzle")
		attack_timer = 0.2
		return
	if kind == "aufwaerts":
		if special_air_used:
			return
		special_air_used = true
		velocity.y = 14.0
	elif kind == "sturm":
		dash_time = 0.25
		dash_hit_done = false
	elif kind == "erdbeben":
		velocity.y = 8.0
	elif kind == "lichtschild":
		_start_dome()
	elif kind == "hundert_faeuste":
		flurry_left = FLURRY_HITS
		flurry_timer = 0.12
	elif kind == "laser":
		SpecialFX.laser_charge(self, ATTACKS.laser.startup)
	special_energy = 0.0
	start_attack(kind)
	_play("special", ATTACKS[kind].anim_speed)
	var sounds := {"feuerball": "fireball", "sturm": "dash", "wirbel": "whirl", "aufwaerts": "uppercut",
		"lichtschild": "pickup_heal", "erdbeben": "swing_strong", "frost": "fireball", "pfeilregen": "swing_weak",
		"hundert_faeuste": "swing_strong", "breitseite": "swing_weak", "laser": "special_start", "schwein": "fireball"}
	Audio.sfx(sounds.get(kind, "swing_strong"))
	Audio.sfx("special_start")
	say("spezial")
	SpecialFX.special_start(self, kind)
	if kind == "sturm":
		SpecialFX.dash_trail(self, dash_time)
	elif kind == "aufwaerts":
		SpecialFX.pillar(self)


func _create_ready_aura() -> void:
	ready_aura = CPUParticles3D.new()
	ready_aura.amount = 40
	ready_aura.lifetime = 0.9
	ready_aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	ready_aura.emission_ring_axis = Vector3.UP
	ready_aura.emission_ring_radius = 0.7
	ready_aura.emission_ring_inner_radius = 0.5
	ready_aura.emission_ring_height = 0.05
	ready_aura.direction = Vector3.UP
	ready_aura.spread = 5.0
	ready_aura.initial_velocity_min = 1.5
	ready_aura.initial_velocity_max = 3.0
	ready_aura.gravity = Vector3.ZERO
	ready_aura.orbit_velocity_min = 0.4
	ready_aura.orbit_velocity_max = 0.8
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = color * 2.0
	quad.material = mat
	ready_aura.mesh = quad
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	ready_aura.color_ramp = fade
	ready_aura.emitting = false
	add_child(ready_aura)


func add_special_energy(amount: float) -> void:
	if not Settings.special_charge or special_energy >= SPECIAL_MAX:
		return
	if passive == "arkan":
		amount *= 1.6
	special_energy = minf(special_energy + amount, SPECIAL_MAX)
	if special_energy >= SPECIAL_MAX:
		Audio.sfx("special_ready")


func special_ready() -> bool:
	return not Settings.special_charge or special_energy >= SPECIAL_MAX


## Stimmlage der Figur (aus dem Roster), damit z. B. der Barbar tiefer und die Hexe höher klingt.
func voice_pitch() -> float:
	return fighter.get("voice", 1.0)


## Spruch in der eigenen Stimme der Figur (z. B. "auswahl", "au", "spezial", "jubel").
## Ohne eigene Stimme spricht die gemeinsame Stimme "fallback" in der Stimmlage der Figur.
func say(line: String, fallback := "", pitch := 1.0, volume_db := 0.0) -> void:
	var folder: String = fighter.get("name", "").replace("ä", "ae").replace("ö", "oe").replace("ü", "ue")
	Audio.fighter_voice(folder, line, fallback if fallback else line, voice_pitch(), pitch, volume_db)


func _shout() -> void:
	if randf() < 0.6:
		var line: String = SHOUTS.pick_random()
		say(line, line, randf_range(0.97, 1.03), -2.0)


func _update_pending_attack(delta: float) -> void:
	if pending_attack == "":
		return
	pending_time -= delta
	if pending_time > 0.0:
		return
	var kind := pending_attack
	pending_attack = ""
	var atk: Dictionary = ATTACKS[kind]
	match kind:
		"feuerball", "frost", "schwein":
			var ball := Projectile.new()
			get_parent().add_child(ball)
			ball.launch(self, atk, global_position + Vector3(0.8 * facing, 1.1, 0), facing, kind == "frost", kind == "schwein")
		"pfeilregen":
			var rain := ArrowRain.new()
			get_parent().add_child(rain)
			var target_x: float = opponent.global_position.x if opponent and opponent.visible else global_position.x + facing * 4.0
			rain.launch(self, target_x, 0.0 if not opponent else minf(opponent.global_position.y, 3.0))
		"lichtschild":
			_end_dome()
			SpecialFX.impact(self, global_position + Vector3(0, 1.0, 0), Color(1, 0.9, 0.5))
			_try_hit(atk, true)
		"erdbeben":
			SpecialFX.quake(self)
			_quake_hit(atk)
		"hundert_faeuste":
			pass  # die einzelnen Schläge kommen aus _update_flurry
		"laser":
			SpecialFX.laser(self, atk.range.x)
			_try_hit(atk, false)
		"breitseite":
			var shot := Cannonball.new()
			get_parent().add_child(shot)
			shot.launch(self, atk, global_position + Vector3(0.9 * facing, 1.0, 0), facing)
		"sturm":
			pass  # trifft während des Stoßes, siehe _update_dash
		"wirbel":
			SpecialFX.whirl(self)
			_try_hit(atk, true)
		_:
			_try_hit(atk, false)


func _update_dash(delta: float) -> void:
	if dash_time <= 0.0:
		return
	dash_time -= delta
	velocity.x = facing * 16.0
	velocity.y = max(velocity.y, 0.0)
	if not dash_hit_done and _try_hit(ATTACKS.sturm, false):
		dash_hit_done = true
		dash_time = 0.0
		velocity.x = 0.0


## Trifft den Gegner, wenn er in Reichweite ist. both_sides: trifft vorne und hinten.
func _try_hit(atk: Dictionary, both_sides: bool) -> bool:
	Target.hit_melee(self, atk.range, both_sides)
	if opponent == null or not opponent.visible:
		return false
	var offset := opponent.global_position - global_position
	var forward := offset.x * facing
	var reach: Vector2 = atk.range * reach_scale
	var in_range := false
	if both_sides:
		in_range = absf(offset.x) <= reach.x and absf(offset.y) <= reach.y
	elif atk == ATTACKS.aufwaerts:
		in_range = absf(offset.x) <= reach.x and offset.y > -1.6 and offset.y <= reach.y
	else:
		in_range = forward > -0.3 and forward <= reach.x and absf(offset.y) <= reach.y
	if not in_range:
		return false
	var side := facing
	if both_sides:
		side = 1 if offset.x >= 0.0 else -1
	var angle: Vector2 = atk.angle
	var landed: bool = opponent.take_hit(atk, Vector3(angle.x * side, angle.y, 0).normalized(), power_time > 0.0,
		outgoing_multiplier())
	if landed:
		add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_DEALT)
		on_hit_landed(opponent)
	for kind in SPECIAL_KINDS:
		if atk == ATTACKS[kind] and landed:
			SpecialFX.impact(self, opponent.global_position + Vector3(0, 1.0, 0), color)
	return true


## Getroffen werden. Je mehr Schaden die Figur schon hat, desto weiter fliegt sie.
## Gibt false zurück, wenn der Treffer abgewehrt wurde.
func take_hit(atk: Dictionary, direction: Vector3, powered := false, attacker_multiplier := 1.0) -> bool:
	if roll_time > 0.0:
		# Mitten in der Ausweichrolle: der Treffer geht ins Leere.
		Audio.sfx("swing_weak", 1.4, -4.0)
		return false
	if dome_time > 0.0:
		# In der Lichtkuppel des Paladins prallt alles ab.
		Audio.sfx("shield_block", 1.3)
		return false
	var multiplier := (POWER_MULTIPLIER if powered else 1.0) * attacker_multiplier
	if shielding:
		shield_hp -= atk.damage * 3.0 * multiplier * (0.5 if passive == "schildmeister" else 1.0)
		if passive == "schildmeister":
			counter_time = COUNTER_TIME
			SpecialFX.popup(self, "KONTER!", Color(0.6, 0.85, 1.0))
		velocity.x = direction.x * 3.0
		if shield_hp <= 0.0:
			# Schild zerbrochen: kurz betäubt.
			shield_hp = SHIELD_MAX * 0.4
			shielding = false
			stunned = 2.5
			velocity.y = 6.0
			Audio.sfx("shield_break")
			say("au")
		else:
			Audio.sfx("shield_block")
		return false
	if frozen > 0.0:
		_unfreeze()
	if pig_time > 0.0:
		_unpig()
	if boss:
		return _boss_hit(atk, direction, multiplier)
	flurry_left = 0
	damage += atk.damage * multiplier * _damage_taken_multiplier()
	since_hit = 0.0
	var knockback: float = (atk.base + damage * atk.scale) * multiplier * _knockback_multiplier()
	velocity = direction * knockback
	hitstun = 0.12 + knockback * 0.02
	pending_attack = ""
	dash_time = 0.0
	_end_flip()
	_play("hit", 1.5)
	add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_TAKEN)
	var heavy: bool = atk.damage * multiplier >= 10.0
	Audio.sfx("hit_strong" if heavy else "hit_weak")
	if heavy or randf() < 0.3:
		say("au", "au", randf_range(0.97, 1.03), -2.0)
	return true


## Macht aus der Figur einen Endboss: größer, Lebenspunkte statt Prozent, kaum wegzuschleudern.
func make_boss(hp: float, size: float) -> void:
	boss = true
	boss_hp = hp
	boss_hp_max = hp
	reach_scale = size * 0.65
	size_scale = size
	stocks = 99
	model_root.scale *= size
	var shape := ($CollisionShape3D.shape as CapsuleShape3D).duplicate()
	shape.radius *= size
	shape.height *= size
	$CollisionShape3D.shape = shape
	$CollisionShape3D.position.y *= size
	$Tag.position.y *= size
	$Shield.visible = false


## Treffer auf den Endboss: zieht Lebenspunkte ab, er wankt nur kurz.
func _boss_hit(atk: Dictionary, direction: Vector3, multiplier: float) -> bool:
	var amount: float = atk.damage * multiplier
	boss_hp = maxf(boss_hp - amount, 0.0)
	velocity += direction * minf(atk.base * 0.3, 2.5)
	hitstun = 0.05
	var heavy := amount >= 10.0
	if heavy:
		_play("hit", 1.5)
	Audio.sfx("hit_strong" if heavy else "hit_weak", 0.7)
	SpecialFX._sparks(get_parent(), global_position + Vector3(0, 2.0, 0), Color(1, 0.8, 0.3), 12, 5.0, 0.3)
	if boss_hp <= 0.0:
		boss_defeated.emit()
	return true


func heal(amount: float) -> void:
	damage = max(damage - amount, 0.0)


func give_power(seconds: float) -> void:
	power_time = seconds


func give_speed(seconds: float) -> void:
	speed_time = seconds


func cheer() -> void:
	controls_enabled = false
	_play("cheer")
	say("jubel")


func _lose_stock() -> void:
	stocks -= 1
	damage = 0.0
	hitstun = 0.0
	stunned = 0.0
	power_time = 0.0
	speed_time = 0.0
	shield_hp = SHIELD_MAX
	pending_attack = ""
	dash_time = 0.0
	roll_time = 0.0
	drop_time = 0.0
	poison_time = 0.0
	flurry_left = 0
	_end_dome()
	if frozen > 0.0:
		_unfreeze()
	if pig_time > 0.0:
		_unpig()
	_end_flip()
	velocity = Vector3.ZERO
	Audio.sfx("ko")
	if stocks > 0:
		position = spawn_position + Vector3(0, 4, 0)
	else:
		visible = false
		set_physics_process(false)
	fell_off.emit(self)


func _update_visuals(delta: float) -> void:
	# Vor dem Kampf schauen die Figuren in die Kamera, im Kampf zum Gegner.
	var target_angle := facing * SIDE_ANGLE if controls_enabled or hitstun > 0.0 else 0.0
	model_root.rotation.y = lerp_angle(model_root.rotation.y, target_angle, 15.0 * delta)

	if roll_time <= 0.0:
		_update_flip(delta)
	_update_cloth(delta)

	shield_bubble.visible = shielding
	shield_bubble.scale = Vector3.ONE * lerpf(0.5, 1.0, shield_hp / SHIELD_MAX)

	var text := "P%d" % player_id
	if frozen > 0.0:
		text += "\nEingefroren!"
	elif stunned > 0.0:
		text += "\nBetäubt!"
	elif poison_time > 0.0:
		text += "\nVergiftet!"
	elif passive == "innere_ruhe" and still_time > 0.3 and controls_enabled and not special_ready():
		text += "\nMeditiert …"
	elif passive == "heldenmut" and damage >= 80.0 and controls_enabled:
		text += "\nHeldenmut!"
	elif power_time > 0.0 and speed_time > 0.0:
		text += "\nKraft + Tempo"
	elif power_time > 0.0:
		text += "\nKraft!"
	elif speed_time > 0.0:
		text += "\nTempo!"
	elif Settings.special_charge and special_energy >= SPECIAL_MAX and controls_enabled:
		text += "\nSpezial bereit!"
	tag.text = text
	if ready_aura:
		ready_aura.emitting = controls_enabled and special_ready() and Settings.special_charge

	if current_anim == "cheer" or frozen > 0.0:
		return
	if hitstun > 0.0:
		_play("hit", 1.5)
	elif stunned > 0.0:
		_play("stunned")
	elif roll_time > 0.0:
		return
	elif current_anim in ATTACKS or current_anim in ["weak", "strong", "kick", "special"]:
		if attack_timer > 0.0:
			return
		_play_movement()
	elif shielding:
		_play("shield")
	else:
		_play_movement()


## Lädt bei Figuren mit "anim_dir" jede Aktion aus einer eigenen Datei (z. B. von Mixamo) in eine
## Animations-Bibliothek. Die Vorwärtsbewegung der Hüfte wird entfernt, damit nur das Spiel die Figur bewegt.
func _load_anim_files() -> void:
	var dir: String = fighter.get("anim_dir", "")
	if dir == "" or anim_player == null:
		return
	var lib := AnimationLibrary.new()
	for action in ["idle", "run", "jump", "fall", "weak", "strong", "kick", "special", "shield",
			"hit", "stunned", "dodge", "cheer"]:
		var path: String = dir + fighter.get("anim_files", {}).get(action, action + ".fbx")
		if not ResourceLoader.exists(path):
			continue
		var scene: Node = load(path).instantiate()
		var source: AnimationPlayer = scene.find_child("AnimationPlayer", true, false)
		if source and not source.get_animation_list().is_empty():
			var anim: Animation = source.get_animation(source.get_animation_list()[0]).duplicate()
			_strip_root_motion(anim)
			var trim: Array = fighter.get("anim_trim", {}).get(action, [])
			if trim.size() == 2:
				anim = _trim_animation(anim, trim[0], trim[1])
			lib.add_animation(action, anim)
		scene.free()
	if anim_player.has_animation_library(Roster.ANIM_LIB):
		anim_player.remove_animation_library(Roster.ANIM_LIB)
	anim_player.add_animation_library(Roster.ANIM_LIB, lib)


func _strip_root_motion(anim: Animation) -> void:
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_POSITION_3D or not str(anim.track_get_path(t)).ends_with("Hips"):
			continue
		var start: Vector3 = anim.track_get_key_value(t, 0)
		for k in anim.track_get_key_count(t):
			var p: Vector3 = anim.track_get_key_value(t, k)
			anim.track_set_key_value(t, k, Vector3(start.x, p.y, start.z))


## Schneidet eine Animation auf den Bereich von `from` bis `to` Sekunden zu
## (z. B. nur der eigentliche Schlag ohne langes Ausholen).
func _trim_animation(anim: Animation, from: float, to: float) -> Animation:
	var out := Animation.new()
	out.length = to - from
	for t in anim.get_track_count():
		var type := anim.track_get_type(t)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var nt := out.add_track(type)
		out.track_set_path(nt, anim.track_get_path(t))
		out.track_set_interpolation_type(nt, anim.track_get_interpolation_type(t))
		var times: Array[float] = [from]
		for k in anim.track_get_key_count(t):
			var key_time := anim.track_get_key_time(t, k)
			if key_time > from and key_time < to:
				times.append(key_time)
		times.append(to)
		for time in times:
			var value: Variant
			match type:
				Animation.TYPE_POSITION_3D: value = anim.position_track_interpolate(t, time)
				Animation.TYPE_ROTATION_3D: value = anim.rotation_track_interpolate(t, time)
				_: value = anim.scale_track_interpolate(t, time)
			out.track_insert_key(nt, time - from, value)
	return out


func _has_anim(action: String) -> bool:
	return anim_player != null and anim_player.has_animation(Roster.anim_name(fighter, action))


func _play_movement() -> void:
	if not is_on_floor():
		_play("fall" if velocity.y < 0.0 and _has_anim("fall") else "jump")
	elif absf(velocity.x) > 0.5:
		_play("run")
	else:
		_play("idle")


func _play(action: String, speed_scale := 1.0) -> void:
	var is_attack := action in ["weak", "strong", "kick", "special"]
	if anim_player == null:
		# Figur ohne Animationen (z. B. der Mönch vor Mixamo): bei Angriffen kurz nach vorne stoßen.
		if is_attack:
			current_anim = action
			_lunge()
		return
	# Eigene Abspielgeschwindigkeit der Figur (z. B. für zugeschnittene Mixamo-Schläge).
	speed_scale = fighter.get("anim_speeds", {}).get(action, speed_scale)
	var anim_name := Roster.anim_name(fighter, action)
	if anim_name == "" or not anim_player.has_animation(anim_name):
		# Figur ohne Schlag-Animation: dann kurz nach vorne stoßen.
		if is_attack:
			current_anim = action
			_lunge()
		return
	if action == current_anim and not is_attack:
		return
	current_anim = action
	anim_player.play(anim_name, 0.08, speed_scale)
	if is_attack:
		anim_player.seek(0.0, true)


## Doppelt links/rechts: Ausweichrolle. Doppelt runter auf einer Plattform: hindurchfallen.
func _check_double_taps() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for dir in last_tap:
		if not Input.is_action_just_pressed(_action(dir)):
			continue
		var double: bool = now - last_tap[dir] <= DOUBLE_TAP_TIME
		last_tap[dir] = -1.0 if double else now
		if not double:
			continue
		if dir == "shield":
			if on_platform:
				_drop_through()
		elif roll_cooldown <= 0.0 and attack_timer <= 0.0:
			_start_roll(1 if dir == "right" else -1)


func _start_roll(dir: int) -> void:
	roll_dir = dir
	facing = dir
	roll_time = ROLL_TIME
	roll_cooldown = ROLL_COOLDOWN
	_end_flip()
	pending_attack = ""
	Audio.sfx("dash", 0.8, -3.0)
	_play("dodge", 1.6)


func _update_roll(delta: float) -> void:
	roll_time = maxf(roll_time - delta, 0.0)
	# Schnell los, zum Ende hin langsamer; in der Luft etwas kürzer.
	var progress := 1.0 - roll_time / ROLL_TIME
	var speed_now := ROLL_SPEED * (1.0 - progress * 0.6) * (1.0 if is_on_floor() else 0.75)
	velocity.x = roll_dir * speed_now
	# Die Figur rollt einmal vorwärts um ihre Körpermitte.
	flip_pivot.rotation = Vector3(TAU * progress * progress * (3.0 - 2.0 * progress), 0, 0)
	if roll_time <= 0.0:
		flip_pivot.rotation = Vector3.ZERO


func _drop_through() -> void:
	drop_time = DROP_TIME
	velocity.y = -3.0
	shielding = false
	Audio.sfx("swing_weak", 0.6, -4.0)


func _start_flip() -> void:
	flip_time = 0.0
	Audio.sfx("swing_weak", 0.7, -6.0)


func _end_flip() -> void:
	flip_time = -1.0
	if flip_pivot:
		flip_pivot.rotation = Vector3.ZERO


func _update_flip(delta: float) -> void:
	if flip_time < 0.0:
		return
	if is_on_floor():
		_end_flip()
		return
	var flip: Dictionary = FLIPS[fighter.get("flip", "salto")]
	flip_time += delta
	var progress := clampf(flip_time / flip.time, 0.0, 1.0)
	# Langsam rein, schnell durch, langsam raus.
	var eased := progress * progress * (3.0 - 2.0 * progress)
	flip_pivot.rotation = flip.axis * flip.turns * TAU * eased
	if progress >= 1.0:
		_end_flip()


## Teile mit eingebackener Flatter-Stärke (Vertex-Farbe) bekommen den Stoff-Shader.
func _setup_cloth(model: Node3D) -> void:
	cloth_materials.clear()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = node.mesh
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		if not (mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR):
			continue
		if _max_red(mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]) <= 0.0:
			continue
		var original := mesh.surface_get_material(0) as BaseMaterial3D
		var mat := ShaderMaterial.new()
		mat.shader = CLOTH_SHADER
		if original:
			mat.set_shader_parameter("albedo_tex", original.albedo_texture)
		node.material_override = mat
		cloth_materials.append(mat)


func _max_red(colors: PackedColorArray) -> float:
	var m := 0.0
	for c in colors:
		m = maxf(m, c.r)
	return m


func _update_cloth(delta: float) -> void:
	if cloth_materials.is_empty():
		return
	var target := clampf(-velocity.y / 14.0, 0.0, 1.0) if not is_on_floor() else 0.0
	fall_wind = lerpf(fall_wind, target, 8.0 * delta)
	var run := clampf(absf(velocity.x) / 12.0, 0.0, 1.0)
	for mat in cloth_materials:
		mat.set_shader_parameter("fall_wind", fall_wind)
		mat.set_shader_parameter("run_wind", run)


func _lunge() -> void:
	var tween := create_tween()
	tween.tween_property(model_root, "position:x", 0.4 * facing, 0.08)
	tween.tween_property(model_root, "position:x", 0.0, 0.15)


## Blendet alle Waffen aus, die nicht in "keep" stehen, und hängt "attach"-Waffen an die Hände.
func _setup_weapons(model: Node3D) -> void:
	var keep: Array = fighter.get("keep", [])
	for node in model.find_children("*", "MeshInstance3D", true, false):
		if node.get_parent() is BoneAttachment3D:
			node.visible = node.name in keep

	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	if skeleton == null:
		return
	# Waffen aus einem anderen Modell (z. B. Schwert und Schild des KayKit-Ritters) an Knochen hängen.
	var attach_from: Dictionary = fighter.get("attach_from", {})
	for bone_name in attach_from:
		if skeleton.find_bone(bone_name) == -1:
			continue
		var source: Node = load(attach_from[bone_name][0]).instantiate()
		var weapon: Node3D = source.find_child(attach_from[bone_name][1], true, false)
		if weapon:
			weapon = weapon.duplicate()
			var slot := BoneAttachment3D.new()
			slot.bone_name = bone_name
			skeleton.add_child(slot)
			slot.add_child(weapon)
			# Optional: [Modell, Knoten, Drehung in Grad, Versatz, Größe]. Größe 1 wie beim KayKit-Ritter (Skala 0.8).
			# Die Drehung hängt von der Figur ab: Mixamo legt die Handknochen je nach Modell etwas anders
			# (siehe tools_tmp/hand_rotation.gd, rechnet sie aus der Haltung beim Held aus).
			var entry: Array = attach_from[bone_name]
			var rot: Vector3 = entry[2] if entry.size() > 2 else Vector3.ZERO
			var offset: Vector3 = entry[3] if entry.size() > 3 else Vector3.ZERO
			var s: float = 0.8 / fighter.get("scale", 0.8) * (entry[4] if entry.size() > 4 else 1.0)
			weapon.transform = Transform3D(Basis.from_euler(rot * PI / 180.0).scaled(Vector3.ONE * s), offset * s)
			weapon.visible = true
		source.free()

	var attach: Dictionary = fighter.get("attach", {})
	if attach.is_empty():
		return
	for bone_name in attach:
		if skeleton.find_bone(bone_name) == -1:
			continue
		var slot := BoneAttachment3D.new()
		slot.bone_name = bone_name
		skeleton.add_child(slot)
		slot.add_child(load(attach[bone_name]).instantiate())


# --- Passive Fähigkeiten und Zustände ------------------------------------------

func _apply_passive() -> void:
	passive = fighter.get("passive", "")
	speed = base_speed * (0.9 if passive == "panzerung" else 1.1 if passive == "flink" else 1.0)
	jump_velocity = base_jump * (0.92 if passive == "schwergewicht" else 1.0)
	max_jumps = base_jumps + (1 if passive in ["dreifachsprung", "flink"] else 0)
	jumps_left = max_jumps


## Zusätzlicher Schaden, den dieser Kämpfer austeilt.
func outgoing_multiplier() -> float:
	var m := 0.85 if boss else 1.0
	match passive:
		"berserker":
			# Je mehr Schaden er hat, desto härter schlägt er zu (bis +40 % bei 100 %).
			m += minf(damage, 100.0) / 250.0
		"heldenmut":
			if damage >= 80.0:
				m += 0.3
		"schildmeister":
			if counter_time > 0.0:
				m += COUNTER_BONUS
				counter_time = 0.0
		"kritisch":
			if randf() < CRIT_CHANCE:
				m *= 2.0
				SpecialFX.popup(self, "KRITISCH!", Color(1, 0.3, 0.2))
	return m


func _damage_taken_multiplier() -> float:
	return (0.8 if passive == "panzerung" else 1.0) * (PIG_DAMAGE_TAKEN if pig_time > 0.0 else 1.0)


func _knockback_multiplier() -> float:
	match passive:
		"schwergewicht": return 0.75
		"panzerung": return 0.9
	return 1.0


## Wird aufgerufen, wenn dieser Kämpfer jemanden getroffen hat.
func on_hit_landed(target: CharacterBody3D) -> void:
	if passive == "gift":
		target.poison(GIFT_TIME)
	elif passive == "pluendern":
		var stolen: float = minf(target.special_energy, PLUNDER_ENERGY)
		if stolen > 0.0:
			target.special_energy -= stolen
			add_special_energy(stolen)
			SpecialFX._sparks(get_parent(), target.global_position + Vector3(0, 1.4, 0), Color(1, 0.85, 0.2), 10, 3.0, 0.4)


func _update_passive(delta: float) -> void:
	since_hit += delta
	counter_time = maxf(counter_time - delta, 0.0)
	if passive == "heilung" and controls_enabled and since_hit > HEAL_DELAY and damage > 0.0:
		damage = maxf(damage - HEAL_PER_SECOND * delta, 0.0)
	if passive == "schwergewicht":
		wind_speed *= 0.3
	if passive == "overcharge" and controls_enabled:
		overcharge_time += delta
		if not overcharge_warned and overcharge_time >= OVERCHARGE_INTERVAL - OVERCHARGE_WARN:
			overcharge_warned = true
			SpecialFX.overcharge_warn(self, OVERCHARGE_WARN)
		if overcharge_time >= OVERCHARGE_INTERVAL:
			overcharge_time = 0.0
			overcharge_warned = false
			SpecialFX.overcharge(self, OVERCHARGE.range.x)
			_try_hit(OVERCHARGE, true)


func poison(seconds: float) -> void:
	poison_time = seconds
	if poison_fx == null:
		poison_fx = SpecialFX._particles(Color(0.4, 1.0, 0.3, 0.9), 20, 0.8, 0.1)
		poison_fx.one_shot = false
		poison_fx.explosiveness = 0.0
		poison_fx.direction = Vector3.UP
		poison_fx.initial_velocity_min = 0.5
		poison_fx.initial_velocity_max = 1.2
		poison_fx.gravity = Vector3.ZERO
		poison_fx.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		poison_fx.emission_sphere_radius = 0.5
		poison_fx.position.y = 1.0
		add_child(poison_fx)
	poison_fx.emitting = true


func freeze(seconds: float) -> void:
	frozen = seconds
	stunned = maxf(stunned, seconds)
	velocity = Vector3(0, minf(velocity.y, 0.0), 0)
	if anim_player:
		anim_player.speed_scale = 0.0
	if ice_block == null:
		ice_block = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.3, 2.0, 1.3)
		ice_block.mesh = box
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.6, 0.9, 1.0, 0.45)
		mat.metallic = 0.3
		mat.roughness = 0.05
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.6, 1.0)
		mat.emission_energy_multiplier = 0.4
		ice_block.material_override = mat
		ice_block.position.y = 1.0
		add_child(ice_block)
	ice_block.visible = true
	Audio.sfx("shield_break", 1.4)


func _unfreeze() -> void:
	frozen = 0.0
	stunned = 0.0
	if anim_player:
		anim_player.speed_scale = 1.0
	if ice_block:
		ice_block.visible = false
		SpecialFX._sparks(get_parent(), global_position + Vector3(0, 1, 0), Color(0.7, 0.95, 1.0), 40, 6.0, 0.5)


## Schweinezauber: die Figur wird für ein paar Sekunden zu einem kleinen rosa Schwein.
func pigify(seconds: float) -> void:
	if boss:
		return
	pig_time = seconds
	if pig == null:
		pig = _build_pig()
		add_child(pig)
	pig.visible = true
	model_root.visible = false
	SpecialFX._flash_sphere(get_parent(), global_position + Vector3(0, 0.8, 0), Color(0.6, 1.0, 0.5), 0.3, 1.6, 0.3)
	SpecialFX._sparks(get_parent(), global_position + Vector3(0, 0.8, 0), Color(1, 0.6, 0.8), 40, 6.0, 0.5)
	SpecialFX.popup(self, "OINK!", Color(1, 0.55, 0.75))
	Audio.sfx("fizzle", 1.3)
	Audio.sfx("oink")


func _unpig() -> void:
	pig_time = 0.0
	if pig:
		pig.visible = false
	model_root.visible = true
	SpecialFX._flash_sphere(get_parent(), global_position + Vector3(0, 0.8, 0), Color(0.6, 1.0, 0.5), 0.3, 1.6, 0.3)
	Audio.sfx("fizzle", 0.9)


## Kleines Schwein aus einfachen Formen: Körper, Kopf, Rüssel, Ohren, Beine und Ringelschwanz.
func _build_pig() -> Node3D:
	var root := Node3D.new()
	var pink := StandardMaterial3D.new()
	pink.albedo_color = Color(1.0, 0.65, 0.72)
	pink.roughness = 0.6
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.25, 0.1, 0.12)
	var parts := [
		[Vector3(0, 0.55, 0), Vector3(0.5, 0.42, 0.62), pink],            # Körper
		[Vector3(0, 0.78, 0.5), Vector3(0.32, 0.3, 0.3), pink],           # Kopf
		[Vector3(0, 0.74, 0.78), Vector3(0.14, 0.11, 0.08), pink],        # Rüssel
		[Vector3(-0.05, 0.75, 0.85), Vector3(0.025, 0.03, 0.02), dark],   # Nasenlöcher
		[Vector3(0.05, 0.75, 0.85), Vector3(0.025, 0.03, 0.02), dark],
		[Vector3(-0.12, 0.88, 0.74), Vector3(0.035, 0.04, 0.03), dark],   # Augen
		[Vector3(0.12, 0.88, 0.74), Vector3(0.035, 0.04, 0.03), dark],
		[Vector3(-0.2, 1.05, 0.45), Vector3(0.1, 0.12, 0.05), pink],      # Ohren
		[Vector3(0.2, 1.05, 0.45), Vector3(0.1, 0.12, 0.05), pink],
	]
	for leg in [Vector3(-0.25, 0.18, 0.3), Vector3(0.25, 0.18, 0.3), Vector3(-0.25, 0.18, -0.3), Vector3(0.25, 0.18, -0.3)]:
		parts.append([leg, Vector3(0.11, 0.2, 0.11), pink])
	for p in parts:
		var m := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		m.mesh = s
		m.material_override = p[2]
		m.position = p[0]
		m.scale = p[1]
		root.add_child(m)
	var tail := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.05
	torus.outer_radius = 0.1
	tail.mesh = torus
	tail.material_override = pink
	tail.position = Vector3(0, 0.75, -0.65)
	tail.rotation.x = PI / 2.0
	root.add_child(tail)
	return root


func _update_status_effects(delta: float) -> void:
	if pig_time > 0.0:
		pig_time -= delta
		pig.rotation.y = model_root.rotation.y
		pig.position.y = absf(sin(Time.get_ticks_msec() * 0.012)) * 0.08 if absf(velocity.x) > 0.5 else 0.0
		if pig_time <= 0.0:
			_unpig()
	if frozen > 0.0:
		frozen -= delta
		velocity.x = 0.0
		if frozen <= 0.0:
			_unfreeze()
	if poison_time > 0.0:
		poison_time -= delta
		damage += GIFT_DAMAGE_PER_SECOND * delta
		if poison_time <= 0.0 and poison_fx:
			poison_fx.emitting = false
	if dome_time > 0.0:
		dome_time -= delta
		if dome:
			dome.rotation.y += 2.0 * delta
			dome.scale = Vector3.ONE * (1.0 + 0.04 * sin(Time.get_ticks_msec() * 0.02))


func _start_dome() -> void:
	dome_time = ATTACKS.lichtschild.startup
	if dome == null:
		dome = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.4
		sphere.height = 2.8
		dome.mesh = sphere
		dome.material_override = SpecialFX._glow_material(Color(1, 0.85, 0.4, 0.35), 2.0)
		dome.position.y = 0.9
		add_child(dome)
	dome.visible = true


func _end_dome() -> void:
	dome_time = 0.0
	if dome:
		dome.visible = false


## Hundert Fäuste: in kurzen Abständen ein Schlag nach dem anderen; der Mönch rückt dabei nach.
func _update_flurry(delta: float) -> void:
	if flurry_left <= 0:
		return
	velocity.x = facing * 2.5
	attack_timer = maxf(attack_timer, 0.3)
	flurry_timer -= delta
	if flurry_timer > 0.0:
		return
	flurry_timer = FLURRY_INTERVAL
	flurry_left -= 1
	var last := flurry_left == 0
	var atk: Dictionary = FLURRY_FINISH if last else ATTACKS.hundert_faeuste
	var fist := global_position + Vector3(facing * 1.0, 1.0 + randf_range(-0.3, 0.3), 0)
	SpecialFX.fist(self, fist, last)
	_lunge()
	Audio.sfx("hit_weak" if not last else "swing_strong", 1.0 + 0.08 * (FLURRY_HITS - flurry_left))
	Target.hit_melee(self, atk.range, false)
	if opponent == null or not opponent.visible:
		return
	var offset := opponent.global_position - global_position
	var forward := offset.x * facing
	var reach: Vector2 = atk.range * reach_scale
	if forward > -0.3 and forward <= reach.x and absf(offset.y) <= reach.y:
		var angle: Vector2 = atk.angle
		if opponent.take_hit(atk, Vector3(angle.x * facing, angle.y, 0).normalized(), power_time > 0.0,
				outgoing_multiplier()):
			add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_DEALT * 0.5)
			on_hit_landed(opponent)
			if last:
				SpecialFX.impact(self, opponent.global_position + Vector3(0, 1.0, 0), Color(1, 0.8, 0.3))


## Erdbeben: trifft alle, die in Reichweite am Boden (oder knapp darüber) stehen, und schleudert sie hoch.
func _quake_hit(atk: Dictionary) -> void:
	Target.hit_melee(self, atk.range, true)
	if opponent == null or not opponent.visible:
		return
	var offset := opponent.global_position - global_position
	var reach: Vector2 = atk.range * reach_scale
	if absf(offset.x) > reach.x or absf(offset.y) > reach.y:
		return
	var side := 1.0 if offset.x >= 0.0 else -1.0
	var angle: Vector2 = atk.angle
	if opponent.take_hit(atk, Vector3(angle.x * side, angle.y, 0).normalized(), power_time > 0.0, outgoing_multiplier()):
		add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_DEALT)
		on_hit_landed(opponent)
		SpecialFX.impact(self, opponent.global_position + Vector3(0, 0.6, 0), color)


func _action(action_name: String) -> String:
	return "p%d_%s" % [player_id, action_name]
