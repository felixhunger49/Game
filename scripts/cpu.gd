class_name CpuPlayer
extends Node
## Computer-Gegner für den Solo-Modus: steuert einen Spieler, indem er dieselben Tasten "drückt"
## wie ein Mensch (p2_left, p2_weak, …). So gelten für ihn alle Regeln, Specials und Passiven genauso.

## Je Schwierigkeit: Reaktionszeit (s), Angriffslust (0..1), Blocken (0..1), Fehler (0..1).
const LEVELS := [
	{"name": "Leicht", "reaction": 0.45, "aggression": 0.35, "block": 0.10, "mistakes": 0.30},
	{"name": "Mittel", "reaction": 0.25, "aggression": 0.60, "block": 0.30, "mistakes": 0.12},
	{"name": "Schwer", "reaction": 0.12, "aggression": 0.85, "block": 0.55, "mistakes": 0.03},
]
## Specials, die aus der Ferne treffen (die anderen nur aus der Nähe einsetzen).
const RANGED_SPECIALS := ["feuerball", "frost", "schwein", "pfeilregen", "breitseite", "laser", "erdbeben"]
## Weiter weg vom Mittelpunkt läuft der Computer zurück zur Mitte, statt herunterzufallen.
const EDGE := 7.0

var me: CharacterBody3D
var foe: CharacterBody3D
var level: Dictionary
var think_timer := 0.0
var held := {}
var shield_time := 0.0
var wander := 0


func setup(player: CharacterBody3D, opponent: CharacterBody3D, difficulty: int) -> void:
	me = player
	foe = opponent
	level = LEVELS[clampi(difficulty, 0, LEVELS.size() - 1)]


func _physics_process(delta: float) -> void:
	if me == null or not me.controls_enabled or not me.visible:
		_hold([])
		return
	shield_time = maxf(shield_time - delta, 0.0)
	think_timer -= delta
	var want: Array = []
	var pos := me.global_position
	var to_foe := foe.global_position - pos
	var dist := absf(to_foe.x)
	var toward := "right" if to_foe.x > 0.0 else "left"
	var to_center := "right" if pos.x < 0.0 else "left"

	# 1) Zurück auf die Bühne: Richtung Mitte und springen, solange es geht.
	if pos.y < -0.6 or absf(pos.x) > EDGE + 1.0:
		want.append(to_center)
		if me.velocity.y < 1.0 and me.jumps_left > 0 and think_timer <= 0.0:
			_tap("jump", 0.3)
			think_timer = 0.25
		elif me.jumps_left == 0 and me.special_ready() and me.fighter.get("special", "") == "aufwaerts":
			_tap("special")
		_hold(want)
		return

	# 2) Blocken, wenn der Gegner nah ist und gerade zuschlägt.
	var foe_attacking: bool = foe.pending_attack != "" or foe.attack_timer > 0.15
	if shield_time > 0.0 or (dist < 2.2 and foe_attacking and think_timer <= 0.0 and randf() < level.block):
		if shield_time == 0.0:
			shield_time = 0.35
		_hold(["shield"])
		return

	# 3) Nicht über die Kante laufen (außer der Gegner steht dort auf festem Boden, z. B. am Bug des Schiffs).
	if absf(pos.x) > EDGE and signf(to_foe.x) == signf(pos.x) and not foe.is_on_floor():
		want.append(to_center)
	elif dist > 1.5:
		want.append(toward)
	elif dist < 0.6:
		# Zu nah dran: kurz zurück, damit die Schläge treffen.
		want.append("left" if toward == "right" else "right")

	if think_timer <= 0.0:
		think_timer = level.reaction * randf_range(0.7, 1.3)
		_decide(to_foe, dist, toward)
	_hold(want)


## Entscheidung im Takt der Reaktionszeit: springen, schlagen, treten, Spezial.
func _decide(to_foe: Vector3, dist: float, toward: String) -> void:
	# Gegner deutlich tiefer und man steht auf einer Plattform: hindurchfallen (wie doppelt "runter").
	if to_foe.y < -1.2 and me.on_platform:
		me._drop_through()
		return
	# Gegner deutlich höher (auf einer Plattform): hinterherspringen, oben noch ein zweites Mal.
	if to_foe.y > 1.2 and dist < 4.0 and me.jumps_left > 0 and (me.is_on_floor() or me.velocity.y < 1.0):
		_tap("jump", 0.3)
		return
	if randf() < level.mistakes:
		# Fehler: zufällig ins Leere schlagen oder herumhüpfen.
		_tap(["weak", "jump", "kick"].pick_random(), 0.1)
		return
	var special: String = me.fighter.get("special", "feuerball")
	if me.special_ready() and absf(to_foe.y) < 1.5:
		var in_range := dist < 9.0 if special in RANGED_SPECIALS else dist < 2.0
		if in_range and randf() < level.aggression:
			_turn_to(toward)
			_tap("special")
			return
	if dist < 1.9 and absf(to_foe.y) < 1.4 and randf() < level.aggression:
		_turn_to(toward)
		var r := randf()
		_tap("weak" if r < 0.5 else "strong" if r < 0.75 else "kick")


## Kurz in Richtung des Gegners drehen, damit der Schlag nach vorne geht.
func _turn_to(dir: String) -> void:
	var want := 1 if dir == "right" else -1
	if me.facing != want:
		me.facing = want


func _action(name: String) -> String:
	return "p%d_%s" % [me.player_id, name]


## Tasten gedrückt halten (Richtungen, Schild); alles andere wird losgelassen.
## Gehaltene Richtungen bleiben gedrückt, sonst würde doppeltes Antippen eine Ausweichrolle auslösen.
func _hold(actions: Array) -> void:
	for a in held.keys():
		if a not in actions:
			Input.action_release(_action(a))
			held.erase(a)
	for a in actions:
		if not held.has(a):
			Input.action_press(_action(a))
			held[a] = true


## Taste kurz drücken (Sprung, Schlag, Spezial). Beim Sprung bestimmt die Haltezeit die Höhe.
func _tap(name: String, hold := 0.06) -> void:
	var action := _action(name)
	Input.action_press(action)
	get_tree().create_timer(hold).timeout.connect(func(): Input.action_release(action))


func _exit_tree() -> void:
	for a in held.keys():
		Input.action_release(_action(a))
