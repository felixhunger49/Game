extends CharacterBody3D

## Wird ausgelöst, wenn die Figur aus der Arena gefallen ist.
signal fell_off(player)
## Ein Treffer, der die Figur aus der Arena schleudern wird (für Zeitlupe und Zoom wie bei Smash Bros.).
signal ko_hit(player)
## Der Final Smash beginnt (die Kamera zoomt heran, siehe Fight).
signal final_smash_started(player)
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
	# Pfeilschuss der Jägerin (starker Angriff aus der Ferne, daher etwas schwächer als ein Schlag).
	"pfeil": {"damage": 9.0, "base": 5.0, "scale": 0.15, "startup": 0.3, "cooldown": 0.75, "angle": Vector2(1, 0.4)},
	"kick": {"damage": 8.0, "base": 5.0, "scale": 0.15, "range": Vector2(1.7, 1.0), "startup": 0.12,
		"cooldown": 0.45, "angle": Vector2(1, 0.25), "anim_speed": 1.8},
	"feuerball": {"damage": 9.0, "base": 4.0, "scale": 0.12, "startup": 0.2, "cooldown": 1.0,
		"angle": Vector2(1, 0.3), "anim_speed": 1.6},
	"sturm": {"damage": 10.0, "base": 5.5, "scale": 0.16, "range": Vector2(1.3, 1.2), "startup": 0.05,
		"cooldown": 1.0, "angle": Vector2(1, 0.4), "anim_speed": 1.6},
	"wirbel": {"damage": 11.0, "base": 6.0, "scale": 0.18, "range": Vector2(2.2, 1.5), "startup": 0.15,
		"cooldown": 1.1, "angle": Vector2(1, 0.8), "anim_speed": 1.5},
	# Konter: Rückschlag, wenn man in der Konter-Haltung getroffen wird (mindestens so stark, sonst 1,3× der Treffer).
	"konter": {"damage": 9.0, "base": 7.0, "scale": 0.2, "range": Vector2(2.0, 1.6), "startup": 0.0, "cooldown": 0.35,
		"angle": Vector2(1, 0.6), "anim_speed": 2.2},
	"aufwaerts": {"damage": 9.0, "base": 6.0, "scale": 0.15, "range": Vector2(1.4, 2.8), "startup": 0.1,
		"cooldown": 0.9, "angle": Vector2(0.2, 1), "anim_speed": 1.6, "zone": "oben"},
	# Alle: in der Luft hoch + schlagen = Uppercut nach oben (Animation vom Himmelshieb des Helden).
	"luft": {"damage": 6.0, "base": 4.5, "scale": 0.12, "range": Vector2(1.4, 2.2), "startup": 0.08,
		"cooldown": 0.55, "angle": Vector2(0.25, 1), "anim_speed": 1.5, "zone": "oben"},
	# Richtungs-Angriffe wie bei Smash: Richtung (hoch/runter, in der Luft auch nach hinten) halten und angreifen.
	# "zone": wo der Schlag trifft (oben = über einem, unten = unter einem, hinten, beide = vorne und hinten).
	"weak_hoch": {"damage": 5.0, "base": 3.5, "scale": 0.08, "range": Vector2(1.3, 2.3), "startup": 0.12,
		"cooldown": 0.3, "angle": Vector2(0.15, 1), "anim_speed": 1.8, "zone": "oben"},
	"weak_tief": {"damage": 4.5, "base": 3.0, "scale": 0.07, "range": Vector2(1.8, 0.8), "startup": 0.1,
		"cooldown": 0.28, "angle": Vector2(1, 0.6), "anim_speed": 2.2},
	"strong_hoch": {"damage": 14.0, "base": 7.0, "scale": 0.22, "range": Vector2(1.6, 2.8), "startup": 0.35,
		"cooldown": 0.8, "angle": Vector2(0.1, 1), "anim_speed": 1.3, "zone": "oben"},
	"strong_tief": {"damage": 12.0, "base": 6.5, "scale": 0.2, "range": Vector2(2.2, 0.9), "startup": 0.25,
		"cooldown": 0.8, "angle": Vector2(1, 0.3), "anim_speed": 1.4, "zone": "beide"},
	"luft_vor": {"damage": 7.0, "base": 4.5, "scale": 0.13, "range": Vector2(1.6, 1.3), "startup": 0.15,
		"cooldown": 0.5, "angle": Vector2(1, 0.45), "anim_speed": 1.5},
	"luft_hinten": {"damage": 9.0, "base": 5.5, "scale": 0.16, "range": Vector2(1.6, 1.3), "startup": 0.2,
		"cooldown": 0.55, "angle": Vector2(1, 0.35), "anim_speed": 1.6, "zone": "hinten"},
	# Nach unten in der Luft: schlägt den Gegner nach unten (am Boden prallt er ab und fliegt hoch).
	"luft_tief": {"damage": 8.0, "base": 4.0, "scale": 0.14, "range": Vector2(1.2, 2.2), "startup": 0.28,
		"cooldown": 0.6, "angle": Vector2(0.1, -1), "anim_speed": 1.8, "zone": "unten"},
	# Held: ein riesiges goldenes Lichtschwert fällt auf den Gegner (siehe JusticeSword).
	"justice": {"damage": 14.0, "base": 8.0, "scale": 0.2, "startup": 0.3, "cooldown": 1.1,
		"angle": Vector2(0.35, 1), "anim_speed": 1.4},
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
	# Alle: Abwehren + schwacher Angriff = Gegner packen (macht keinen Schaden, geht durch den Schild).
	"griff": {"damage": 0.0, "base": 0.0, "scale": 0.0, "range": GRAB_RANGE, "startup": 0.1,
		"cooldown": 0.5, "angle": Vector2(1, 0), "anim_speed": 2.0},
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
## Luft-Uppercut: Mixamo-Animation vom Himmelshieb des Helden, passt auf jedes Mixamo-Skelett.
const LUFT_ANIM := "res://assets/ritter_neu/special.fbx"
const LUFT_TRIM := [0.40, 1.30]
## Mixamo-Animationen für Kante, Greifen, Werfen und Smash-Aufladen. Alle Mixamo-Figuren haben dasselbe Skelett,
## daher reicht ein Satz für alle (eine Figur kann in ihrem anim_dir eine eigene Datei gleichen Namens haben).
## Wert: [von, bis] in Sekunden ([] = ganze Animation).
const SMASH_ANIM_DIR := "res://assets/smash/"
## Konter (runter + Spezial): so lange fängt man Treffer ab, dann so lange warten bis zum nächsten Konter.
const KONTER_TIME := 0.45
const KONTER_COOLDOWN := 1.6
## Rettungssprung (hoch + Spezial): Sprungkraft nach oben.
const UP_SPECIAL_JUMP := 14.0
## Richtungs-Angriffe: eigene Animation aus assets/smash (oder dem Figurenordner), sonst die hier genannte.
const DIR_ATTACKS := {"aufwaerts": "luft", "konter": "shield", "weak_hoch": "luft", "weak_tief": "kick", "strong_hoch": "luft", "strong_tief": "kick",
	"luft_vor": "weak", "luft_hinten": "kick", "luft_tief": "strong"}
## Zuschnitt der Richtungs-Animationen aus assets/smash (Mixamo) in Sekunden.
const DIR_TRIM := {"aufwaerts": [0.0, 1.0], "konter": [0.0, 0.6], "weak_hoch": [0.15, 1.0], "weak_tief": [0.0, 1.0], "strong_hoch": [0.35, 1.35],
	"strong_tief": [0.3, 1.35], "luft_vor": [0.1, 0.85], "luft_hinten": [0.5, 1.5], "luft_tief": [1.0, 2.2]}
const SMASH_ANIMS := {"ledge_hang": [], "ledge_climb": [], "grab": [0.0, 0.9], "grab_hold": [],
	"throw": [0.3, 1.4], "smash_charge": [0.0, 1.2],
	"hit_front": [0.0, 0.9], "hit_back": [0.0, 1.0], "launch_front": [0.0, 0.6], "launch_back": [0.0, 0.8],
	"knockdown_back": [0.55, 2.0], "knockdown_front": [0.9, 2.2], "getup_back": [0.6, 1.6], "getup_front": [3.0, 5.2]}
## Hinfallen nach einem harten Treffer: so lange liegt man höchstens, so lange dauert das Aufstehen (unverwundbar).
## Ab DOWN_QUICK Sekunden Liegen kann man mit einer Taste früher aufstehen.
const DOWN_TIME := 0.7
const DOWN_QUICK := 0.25
const GETUP_TIME := 0.7
## Zweihandwaffe (z. B. Axt des Barbaren): zeigt immer von der rechten zur linken Hand, damit beide Hände am Stiel sind.
var two_hand_weapon: Node3D
## Stelle auf dem Stiel (in Waffen-Einheiten, KayKit-Axt: Griff 0, Kopf ab ca. 0,9), an der die linke Hand greift.
const TWO_HAND_GRIP := 0.75
var two_hand_skeleton: Skeleton3D
## Overcharge (Kampfroboter): alle OVERCHARGE_INTERVAL Sekunden ein Stromschlag rundherum,
## OVERCHARGE_WARN Sekunden vorher knistert es blau als Warnung.
const OVERCHARGE_INTERVAL := 7.0
const OVERCHARGE_WARN := 0.8
const OVERCHARGE := {"damage": 3.0, "base": 3.5, "scale": 0.06, "range": Vector2(2.4, 2.0), "angle": Vector2(1, 0.6)}
## Schildmeister: nach einem abgewehrten Treffer ist der nächste Angriff so lange verstärkt.
const COUNTER_TIME := 1.5
const COUNTER_BONUS := 0.6

## Alles außerhalb dieses Bereichs zählt als heruntergefallen (x links, y unten, Breite, Höhe).
var blast_zone := Rect2(-19, -10, 38, 28)
## Die Figuren drehen sich nicht ganz zur Seite, damit man ihr Gesicht sieht (wie bei Smash Bros.).
const SIDE_ANGLE := deg_to_rad(70)
## Physik-Ebene, auf der die schwebenden Plattformen liegen (man kann von unten durchspringen).
const PLATFORM_LAYER := 2
const SHIELD_MAX := 100.0
## Perfektes Abwehren: Schild in diesem Zeitfenster (Sekunden) vor dem Treffer gedrückt.
const PARRY_WINDOW := 0.15
## So lange taumelt man, wenn das Schild zerbricht.
const SHIELD_BREAK_STUN := 3.0
const POWER_MULTIPLIER := 1.4
## Energie für die Spezialattacke: füllt sich mit der Zeit, durch Treffen und durch Getroffenwerden.
const SPECIAL_MAX := 100.0
const SPECIAL_PER_SECOND := 5.0
const SPECIAL_PER_DAMAGE_DEALT := 3.5
const SPECIAL_PER_DAMAGE_TAKEN := 2.0
const SPECIAL_KINDS := ["feuerball", "sturm", "wirbel", "aufwaerts", "lichtschild", "erdbeben", "frost", "pfeilregen",
	"hundert_faeuste", "breitseite", "laser", "schwein", "justice"]
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

## Schnell fallen: so schnell fällt man, wenn man in der Luft Abwehren gedrückt hält.
const FAST_FALL_SPEED := 22.0
## Ausweichen in der Luft (Abwehren in der Luft): so lange unverwundbar, einmal pro Sprung.
const AIR_DODGE_TIME := 0.3
const AIR_DODGE_SPEED := 6.0
## Smash-Angriff: starken Angriff am Boden gedrückt halten hält die Figur oben in der Ausholbewegung an
## und lädt bis zu CHARGE_MAX Sekunden auf. Volle Ladung gibt CHARGE_BONUS mehr Schaden und Rückstoß.
const CHARGE_MAX := 1.0
const CHARGE_BONUS := 0.6
## An der Kante festhalten: höchstens so lange hängen, so lange unverwundbar (nur wenn man seit
## dem letzten Festhalten gelandet ist) und so lange warten, bis man wieder greifen kann.
const LEDGE_HANG_MAX := 2.5
const LEDGE_INVULN := 0.6
const LEDGE_REGRAB := 0.6
## So lange dauert das Hochklettern, wenn die Figur eine Kletter-Animation hat.
const CLIMB_TIME := 0.35
## So weit unter der Kante hängt die Figur (Füße), damit die Hände oben am Rand sind.
const LEDGE_HANG_DROP := 1.75
## Greifen (Abwehren + schwacher Angriff): Reichweite, Haltezeit und Schaden beim Zuschlagen im Griff.
const GRAB_RANGE := Vector2(1.4, 1.2)
const GRAB_HOLD_TIME := 1.1
const GRAB_PUMMEL_DAMAGE := 1.5
## Würfe: angle zeigt nach vorne (x = 1). "hinten" wirft hinter sich.
const THROWS := {
	"vorne": {"damage": 8.0, "base": 6.0, "scale": 0.16, "angle": Vector2(1, 0.55)},
	"hinten": {"damage": 10.0, "base": 6.5, "scale": 0.18, "angle": Vector2(-1, 0.6)},
	"oben": {"damage": 9.0, "base": 6.0, "scale": 0.15, "angle": Vector2(0.1, 1)},
	"unten": {"damage": 6.0, "base": 4.5, "scale": 0.08, "angle": Vector2(0.3, 1)},
}

## Höhe der Körpermitte: um diesen Punkt drehen sich die Kunststücke.
const FLIP_PIVOT_HEIGHT := 0.9
const CLOTH_SHADER := preload("res://scripts/cloth.gdshader")

## Alle anderen Kämpfer im Kampf (bei zwei Spielern nur einer).
var rivals: Array = []
## Team im Team-Modus (1 Rot, 2 Blau); 0 = jeder gegen jeden. Das eigene Team kann man nicht treffen.
var team := 0
## Der nächste Gegner (zum Zielen, Kontern, Greifen). Zuweisen setzt den einzigen Gegner.
var opponent: CharacterBody3D:
	get:
		return _nearest_enemy()
	set(value):
		rivals = [value] if value else []
var fighter: Dictionary = {}
var controls_enabled := false
## In der Kämpferauswahl dreht sich die Figur langsam, damit man sie von allen Seiten sieht.
var showcase_spin := false
const SHOWCASE_SPIN_SPEED := 1.2
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
var konter_time := 0.0
## Smash-Kugel zerschlagen: der nächste Druck auf Spezial löst den Final Smash aus.
var final_smash_ready := false
## Läuft der Final Smash: Aufladen, dann der riesige Strahl. Solange ist die Figur unverwundbar.
var final_time := 0.0
## Im Final Smash eines Gegners gefangen: festgehalten, bis der Abschlussschlag kommt (siehe FinalSmash).
var caught := false
var final_aura: CPUParticles3D
var konter_cooldown := 0.0
var shielding := false
var shield_hp := SHIELD_MAX
## Wie lange das Schild schon gehalten wird (für perfektes Abwehren).
var shield_hold := 0.0
## Sterne über dem Kopf nach einem Schildbruch.
var dizzy_fx: Node3D
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
var last_tap := {"left": -1.0, "right": -1.0, "down": -1.0}
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
## Schnell fallen und Ausweichen in der Luft.
var fast_falling := false
var fast_fall_armed := false
var air_dodge_time := 0.0
var air_dodge_used := false
## Smash-Angriff aufladen: charging = Taste wird noch gehalten, charge_time = so lange wird schon aufgeladen.
var charging := false
var charge_time := 0.0
## Kante: ledge_side = Richtung zur Bühne (0 = hängt nicht), ledge_top = Höhe der Kante.
var ledge_side := 0
var ledge_top := 0.0
var ledge_x := 0.0
var hang_time := 0.0
var ledge_invuln := 0.0
var ledge_invuln_ready := true
var ledge_regrab := 0.0
## Hochklettern läuft (mit Animation) noch so lange; danach steht die Figur oben. climb_attack: dabei treten.
var climb_time := 0.0
var climb_attack := false
## Treffer-Animation je nach Richtung (von vorne/hinten, leicht/weggeschleudert).
var hit_anim := "hit"
## Weit weggeschleudert: beim Landen fällt man hin (down_time), dann steht man auf (getup_time).
var launched := false
var down_time := 0.0
var down_elapsed := 0.0
var getup_time := 0.0
var down_front := false
## Greifen: holding = der gepackte Gegner, held_by = wer einen selbst gepackt hat.
var holding: CharacterBody3D
var held_by: CharacterBody3D
var grab_hold := 0.0
var pummel_cooldown := 0.0
var grab_lag := 0.0

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
	if anim_player == null and fighter.has("anim_dir"):
		# In Blender reparierte Modelle (modell.fbx) haben keine eigene Animation: Player dazu bauen.
		# Die Spuren heißen "Skeleton3D:<Knochen>", also zeigt root_node auf den Knoten über dem Skelett.
		var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
		if skeleton:
			anim_player = AnimationPlayer.new()
			model.add_child(anim_player)
			anim_player.root_node = anim_player.get_path_to(skeleton.get_parent())
	_load_anim_files()
	if anim_player:
		for action in ["idle", "run", "jump", "fall", "shield", "stunned", "ledge_hang", "grab_hold"]:
			if action == "jump" and fighter.has("anim_dir"):
				continue  # Mixamo-Sprung ist ein einmaliger Absprung, danach kommt "fall"
			var anim_name := Roster.anim_name(fighter, action)
			if anim_player.has_animation(anim_name):
				anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	_play("idle")


func _process(_delta: float) -> void:
	_aim_two_hand_weapon()


## Zweihandwaffe zwischen beide Hände legen: Stiel von der rechten zur linken Hand, Kopf darüber hinaus.
func _aim_two_hand_weapon() -> void:
	if two_hand_weapon == null or not is_instance_valid(two_hand_weapon):
		return
	var sk := two_hand_skeleton
	var right: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_RightHand")).origin
	var left: Vector3 = sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_LeftHand")).origin
	var along := left - right
	if along.length() < 0.05:
		return
	var y := along.normalized()
	var side := y.cross(Vector3(0, 0, 1))
	if side.length() < 0.1:
		side = y.cross(Vector3(1, 0, 0))
	var x := side.normalized()
	var z := x.cross(y)
	var size := two_hand_weapon.global_transform.basis.get_scale().x
	# Die linke Hand greift kurz unter dem Kopf (bei TWO_HAND_GRIP auf dem Stiel), die rechte entsprechend weiter unten.
	var right_on_handle := maxf(TWO_HAND_GRIP - along.length() / size, -0.4)
	two_hand_weapon.global_transform = Transform3D(Basis(x, y, z).scaled(Vector3.ONE * size), right - y * right_on_handle * size)


func _physics_process(delta: float) -> void:
	attack_timer = max(attack_timer - delta, 0.0)
	konter_time = maxf(konter_time - delta, 0.0)
	konter_cooldown = maxf(konter_cooldown - delta, 0.0)
	hitstun = max(hitstun - delta, 0.0)
	stunned = max(stunned - delta, 0.0)
	power_time = max(power_time - delta, 0.0)
	speed_time = max(speed_time - delta, 0.0)
	roll_cooldown = max(roll_cooldown - delta, 0.0)
	drop_time = max(drop_time - delta, 0.0)
	air_dodge_time = maxf(air_dodge_time - delta, 0.0)
	ledge_regrab = maxf(ledge_regrab - delta, 0.0)
	ledge_invuln = maxf(ledge_invuln - delta, 0.0)
	pummel_cooldown = maxf(pummel_cooldown - delta, 0.0)
	grab_lag = maxf(grab_lag - delta, 0.0)
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

	# Gepackt oder an der Kante: eigene Steuerung, keine Schwerkraft.
	if held_by:
		_update_held()
		_update_visuals(delta)
		return
	if ledge_side != 0:
		_update_ledge(delta)
		_update_visuals(delta)
		return
	if holding:
		_update_holding(delta)
		_update_visuals(delta)
		return

	var fall_speed := -velocity.y
	velocity.y -= gravity * delta
	# Von unten durch die schwebenden Plattformen springen, beim Fallen darauf landen.
	# Nach doppeltem Runter fällt man kurz durch sie hindurch.
	set_collision_mask_value(PLATFORM_LAYER, velocity.y <= 0.0 and drop_time <= 0.0)
	if is_on_floor():
		jumps_left = max_jumps
		special_air_used = false
		jumped = false
		fast_falling = false
		fast_fall_armed = false
		air_dodge_used = false
		ledge_invuln_ready = true

	_update_pending_attack(delta)
	_update_dash(delta)

	var can_act := controls_enabled and hitstun == 0.0 and stunned == 0.0 and down_time <= 0.0 and getup_time <= 0.0 \
		and not caught and final_time <= 0.0
	if can_act and roll_time <= 0.0 and dash_time <= 0.0:
		_check_double_taps()
	shielding = can_act and pig_time <= 0.0 and is_on_floor() and Input.is_action_pressed(_action("shield")) and shield_hp > 0.0 \
		and roll_time <= 0.0 and drop_time <= 0.0 and not charging and pending_attack != "griff" and grab_lag <= 0.0 and holding == null
	if shielding:
		shield_hold += delta
		shield_hp = max(shield_hp - 18.0 * delta * (0.5 if passive == "schildmeister" else 1.0), 0.0)
		if shield_hp <= 0.0:
			# Zu lange gehalten: das Schild ist leer und zerbricht.
			_break_shield()
	else:
		shield_hold = 0.0
		shield_hp = min(shield_hp + 12.0 * delta, SHIELD_MAX)

	if caught:
		velocity = Vector3.ZERO
	elif down_time > 0.0 or getup_time > 0.0:
		_update_down(delta)
	elif hitstun > 0.0:
		# Getroffen: keine Kontrolle, die Figur fliegt weiter.
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta) + wind_speed * delta
	elif final_time > 0.0:
		_update_final_smash(delta)
	elif dash_time > 0.0:
		pass
	elif roll_time > 0.0:
		_update_roll(delta)
	elif air_dodge_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.y = maxf(velocity.y, -3.0)
	elif can_act and not shielding:
		_handle_input(delta)
	else:
		velocity.x = move_toward(velocity.x, wind_speed * 0.5, 60.0 * (ground_grip if is_on_floor() else 1.0) * delta)
		if shielding and Input.is_action_just_pressed(_action("jump")):
			velocity.y = jump_velocity
			jumps_left -= 1
			Audio.sfx("jump")
		elif shielding and Input.is_action_just_pressed(_action("weak")):
			# Abwehren + schwacher Angriff: Gegner packen.
			start_grab()
		elif shielding and roll_cooldown <= 0.0 and (Input.is_action_just_pressed(_action("left")) \
				or Input.is_action_just_pressed(_action("right"))):
			# Aus dem Schild zur Seite rollen.
			_start_roll(1 if Input.is_action_just_pressed(_action("right")) else -1)

	# In der Luft: Abwehren = ausweichen, Runter halten = schnell fallen.
	if can_act and not is_on_floor() and roll_time <= 0.0 and dash_time <= 0.0:
		_update_air_moves()
	if fast_falling and hitstun == 0.0:
		velocity.y = minf(velocity.y, -FAST_FALL_SPEED)

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

	var was_on_floor := is_on_floor()
	move_and_slide()
	if can_act and not is_on_floor() and velocity.y < 0.0 and ledge_regrab <= 0.0 and pending_attack == "" \
			and dash_time <= 0.0 and air_dodge_time <= 0.0 and pig_time <= 0.0:
		_try_grab_ledge()
	if is_on_floor() and launched:
		launched = false
		if not was_on_floor and _has_anim("knockdown_back") and stocks > 0:
			_fall_down()
	if is_on_floor() and not was_on_floor and fall_speed > 7.0 and visible:
		SpecialFX.dust(get_parent(), global_position, 12 if fall_speed > 14.0 else 7, 3.0 if fall_speed > 14.0 else 2.0)
	on_platform = false
	if is_on_floor():
		for i in get_slide_collision_count():
			var body := get_slide_collision(i).get_collider() as CollisionObject3D
			if body and body.get_collision_layer_value(PLATFORM_LAYER):
				on_platform = true
	_update_visuals(delta)

	if not blast_zone.has_point(Vector2(position.x, position.y)):
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
	# Wie bei Smash dreht man sich nur am Boden (und beim Absprung) um: so geht in der Luft auch ein Angriff nach hinten.
	if direction != 0.0 and (is_on_floor() or Input.is_action_just_pressed(_action("jump"))):
		facing = int(sign(direction))

	if Input.is_action_just_pressed(_action("jump")) and jumps_left > 0:
		if is_on_floor():
			SpecialFX.dust(get_parent(), global_position, 6, 1.6)
		velocity.y = jump_velocity * (1.12 if speed_time > 0.0 else 1.0)
		Audio.sfx("jump", 1.0 if jumps_left == max_jumps else 1.25)
		jumps_left -= 1
		jumped = true
		launched = false
		fast_falling = false
		fast_fall_armed = false
		# Ein neuer Sprung bricht ein laufendes Kunststück nicht ab, startet aber oben ein neues.
		if flip_time >= 0.0:
			_end_flip()

	if attack_timer > 0.0 or pig_time > 0.0:
		return
	for kind in ["weak", "strong", "kick"]:
		if Input.is_action_just_pressed(_action(kind)):
			var dir := _held_dir()
			if kind != "kick" and not is_on_floor():
				var air := _air_attack(dir)
				start_attack(air)
				velocity.y = maxf(velocity.y, 5.0 if air == "luft" else 1.5)
			elif kind == "strong":
				_start_charge("strong" + ("_" + dir if dir != "" else ""))
			elif kind == "weak" and dir != "":
				start_attack("weak_" + dir)
			else:
				start_attack(kind)
			return
	if Input.is_action_just_pressed(_action("special")) and final_smash_ready:
		start_final_smash()
		return
	if Input.is_action_just_pressed(_action("special")):
		# Spezial je Richtung: hoch = Rettungssprung, runter = Konter, sonst das eigene Spezial der Figur.
		match _held_dir():
			"hoch": start_up_special()
			"tief": start_counter()
			_: start_special()


## Richtung, die gerade gehalten wird: "hoch", "tief" oder "" (keine).
func _held_dir() -> String:
	if InputMap.has_action(_action("up")) and Input.is_action_pressed(_action("up")):
		return "hoch"
	if InputMap.has_action(_action("down")) and Input.is_action_pressed(_action("down")):
		return "tief"
	return ""


## Luftangriff nach Richtung: hoch = Uppercut, runter = nach unten, zurück = nach hinten, sonst nach vorne.
func _air_attack(dir: String) -> String:
	if dir == "hoch":
		return "luft"
	if dir == "tief":
		return "luft_tief"
	if Input.get_axis(_action("left"), _action("right")) * facing < -0.5:
		return "luft_hinten"
	return "luft_vor"


## Holt zum Angriff aus. Der Treffer kommt nach der Ausholzeit (startup).
func start_attack(kind: String) -> void:
	launched = false
	var atk: Dictionary = ATTACKS[kind]
	attack_timer = atk.cooldown
	pending_attack = kind
	pending_time = atk.startup
	_end_flip()
	_play(kind, atk.anim_speed)
	match kind:
		"weak", "weak_hoch", "weak_tief", "luft_vor":
			Audio.sfx("swing_weak")
		"strong", "strong_hoch", "strong_tief", "luft_tief":
			Audio.sfx("swing_strong")
			if kind.begins_with("strong"):
				_shout()
		"kick", "luft_hinten":
			Audio.sfx("kick")


## Smash-Kugel zerschlagen: leuchtende Aura, bis man den Final Smash auslöst.
func gain_final_smash() -> void:
	if final_smash_ready or boss:
		return
	final_smash_ready = true
	SpecialFX.popup(self, "FINAL SMASH!", color)
	say("spezial")
	final_aura = SpecialFX._particles(color.lightened(0.3), 50, 0.8, 0.12)
	final_aura.one_shot = false
	final_aura.explosiveness = 0.0
	final_aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	final_aura.emission_sphere_radius = 0.8
	final_aura.direction = Vector3.UP
	final_aura.spread = 60.0
	final_aura.initial_velocity_min = 1.0
	final_aura.initial_velocity_max = 2.5
	final_aura.gravity = Vector3.ZERO
	add_child(final_aura)
	final_aura.position = Vector3(0, 1.0 * size_scale, 0)
	final_aura.emitting = true


## Final Smash: jede Figur hat ihre eigene Filmszene (siehe FinalSmash). Solange sie läuft, ist die Figur
## unverwundbar und wird von der Szene gesteuert.
func start_final_smash() -> void:
	final_smash_ready = false
	if is_instance_valid(final_aura):
		final_aura.queue_free()
	final_time = 99.0
	pending_attack = ""
	charging = false
	attack_timer = 99.0
	velocity = Vector3.ZERO
	_end_flip()
	var scene := FinalSmash.new()
	get_parent().add_child(scene)
	scene.start(self)
	final_smash_started.emit(self)


## Von der Szene aufgerufen, wenn sie vorbei ist.
func end_final_smash() -> void:
	final_time = 0.0
	attack_timer = 0.2
	model_root.visible = pig_time <= 0.0


func _update_final_smash(_delta: float) -> void:
	velocity = Vector3.ZERO


## Alle Gegner, die gerade im Spiel sind (ohne Mitspieler aus dem eigenen Team).
func _enemies() -> Array:
	return rivals.filter(func(r): return is_instance_valid(r) and r.visible and (team == 0 or r.team != team))


func _nearest_enemy() -> CharacterBody3D:
	return nearest_enemy_to(global_position)


## Der Gegner, der einer Stelle am nächsten ist (z. B. für Geschosse).
func nearest_enemy_to(pos: Vector3) -> CharacterBody3D:
	var best: CharacterBody3D = null
	var best_distance := INF
	for e in _enemies():
		var d: float = pos.distance_squared_to(e.global_position)
		if d < best_distance:
			best = e
			best_distance = d
	return best


## Hoch + Spezial (alle Figuren, kostet keine Energie): Rettungssprung mit Schlag nach oben,
## einmal pro Sprung, um von unten zurück auf die Bühne zu kommen.
func start_up_special() -> void:
	if special_air_used:
		Audio.sfx("fizzle")
		attack_timer = 0.2
		return
	special_air_used = true
	launched = false
	fast_falling = false
	fast_fall_armed = false
	_end_flip()
	velocity.y = UP_SPECIAL_JUMP
	velocity.x = Input.get_axis(_action("left"), _action("right")) * 4.0
	start_attack("aufwaerts")
	Audio.sfx("uppercut")
	SpecialFX.pillar(self)


## Runter + Spezial (alle Figuren, kostet keine Energie): kurz in Konter-Haltung. Wer jetzt zuschlägt,
## trifft ins Leere und bekommt selbst einen harten Schlag ab.
func start_counter() -> void:
	if konter_cooldown > 0.0:
		Audio.sfx("fizzle")
		attack_timer = 0.2
		return
	konter_time = KONTER_TIME
	konter_cooldown = KONTER_COOLDOWN
	attack_timer = KONTER_TIME + 0.25
	pending_attack = ""
	_end_flip()
	_play("konter")
	Audio.sfx("special_start", 1.4, -4.0)
	SpecialFX._ring(get_parent(), global_position + Vector3(0, 1.0, 0), Color(0.6, 0.85, 1.0), 0.3, 1.3, 0.3, false)


func _counter_strike(atk: Dictionary) -> void:
	konter_time = 0.0
	SpecialFX.popup(self, "KONTER!", Color(0.6, 0.85, 1.0))
	SpecialFX.slow_motion(self, 0.3, 0.25)
	Audio.sfx("hit_strong")
	if opponent == null or not opponent.visible or global_position.distance_to(opponent.global_position) > 3.5:
		# Fernangriff (z. B. Feuerball): nur abgefangen.
		return
	facing = 1 if opponent.global_position.x > global_position.x else -1
	var hit: Dictionary = ATTACKS.konter.duplicate()
	hit.damage = maxf(atk.get("damage", 0.0) * 1.3, hit.damage)
	_play("strong", 2.2)
	attack_timer = maxf(attack_timer, 0.35)
	if opponent.take_hit(hit, Vector3(facing, 0.6, 0).normalized(), false, outgoing_multiplier()):
		add_special_energy(hit.damage * SPECIAL_PER_DAMAGE_DEALT)
		SpecialFX.hit(self, opponent.global_position.lerp(global_position, 0.25) + Vector3(0, 1.0, 0), color, hit.damage)


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
		"hundert_faeuste": "swing_strong", "breitseite": "swing_weak", "laser": "special_start", "schwein": "fireball", "justice": "special_start"}
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
	quad.size = Vector2(0.22, 0.22)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = SpecialFX.soft_dot()
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
	if pending_attack.begins_with("strong") and charging and _update_charge(delta):
		return
	var kind := pending_attack
	pending_attack = ""
	var atk: Dictionary = ATTACKS[kind]
	if kind == "griff":
		if not _try_grab():
			# Daneben gegriffen: kurz ungeschützt.
			grab_lag = 0.4
		return
	if kind.begins_with("strong") and charge_time > 0.0:
		# Aufgeladener Smash-Angriff: mehr Schaden und Rückstoß.
		var bonus := 1.0 + CHARGE_BONUS * charge_time / CHARGE_MAX
		charge_time = 0.0
		atk = atk.duplicate()
		for key in ["damage", "base", "scale"]:
			atk[key] *= bonus
	# Jägerin: der starke Angriff ist ein Pfeilschuss quer über die Arena.
	if kind == "strong" and fighter.get("bow", false):
		var arrow := ArrowShot.new()
		get_parent().add_child(arrow)
		var pfeil: Dictionary = ATTACKS.pfeil
		if atk.damage > ATTACKS.strong.damage:
			pfeil = pfeil.duplicate()
			for key in ["damage", "base", "scale"]:
				pfeil[key] *= atk.damage / ATTACKS.strong.damage
		arrow.launch(self, pfeil, global_position + Vector3(0.7 * facing, 1.2, 0), facing)
		return
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
		"justice":
			var sword := JusticeSword.new()
			get_parent().add_child(sword)
			var target_x: float = opponent.global_position.x if opponent and opponent.visible else global_position.x + facing * 4.0
			sword.launch(self, target_x, opponent.global_position.y if opponent and opponent.visible else global_position.y)
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
	var any_in_range := false
	for foe in _enemies():
		if _try_hit_one(atk, both_sides, foe):
			any_in_range = true
	return any_in_range


func _try_hit_one(atk: Dictionary, both_sides: bool, foe: CharacterBody3D) -> bool:
	var offset := foe.global_position - global_position
	var forward := offset.x * facing
	var reach: Vector2 = atk.range * reach_scale
	var in_range := false
	var zone: String = atk.get("zone", "")
	if zone == "beide":
		both_sides = true
	if both_sides:
		in_range = absf(offset.x) <= reach.x and absf(offset.y) <= reach.y
	elif zone == "oben":
		in_range = absf(offset.x) <= reach.x and offset.y > -1.6 and offset.y <= reach.y
	elif zone == "unten":
		in_range = absf(offset.x) <= reach.x and offset.y < 0.8 and offset.y >= -reach.y
	elif zone == "hinten":
		in_range = forward < 0.3 and forward >= -reach.x and absf(offset.y) <= reach.y
	else:
		in_range = forward > -0.3 and forward <= reach.x and absf(offset.y) <= reach.y
	if not in_range:
		return false
	var side := -facing if zone == "hinten" else facing
	if both_sides:
		side = 1 if offset.x >= 0.0 else -1
	var angle: Vector2 = atk.angle
	if angle.y < 0.0 and foe.is_on_floor():
		# Nach unten geschlagen, aber der Gegner steht: er prallt vom Boden ab.
		angle = Vector2(0.6, 0.5)
	var landed: bool = foe.take_hit(atk, Vector3(angle.x * side, angle.y, 0).normalized(), power_time > 0.0,
		outgoing_multiplier())
	if landed:
		add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_DEALT)
		on_hit_landed(foe)
	var special := false
	for kind in SPECIAL_KINDS:
		if atk == ATTACKS[kind] and landed:
			SpecialFX.impact(self, foe.global_position + Vector3(0, 1.0, 0), color)
			special = true
	if landed and not special:
		# Trefferpunkt zwischen beiden Figuren, etwas näher am Getroffenen.
		var spot: Vector3 = foe.global_position.lerp(global_position, 0.25) + Vector3(0, 1.0, 0)
		SpecialFX.hit(self, spot, color, atk.damage * (POWER_MULTIPLIER if power_time > 0.0 else 1.0))
	return true


## Getroffen werden. Je mehr Schaden die Figur schon hat, desto weiter fliegt sie.
## Gibt false zurück, wenn der Treffer abgewehrt wurde.
func take_hit(atk: Dictionary, direction: Vector3, powered := false, attacker_multiplier := 1.0) -> bool:
	if roll_time > 0.0 or air_dodge_time > 0.0 or ledge_invuln > 0.0 or getup_time > 0.0:
		# Mitten in der Ausweichrolle (am Boden oder in der Luft) oder frisch an der Kante: der Treffer geht ins Leere.
		Audio.sfx("swing_weak", 1.4, -4.0)
		return false
	if dome_time > 0.0:
		# In der Lichtkuppel des Paladins prallt alles ab.
		Audio.sfx("shield_block", 1.3)
		return false
	if konter_time > 0.0:
		_counter_strike(atk)
		return false
	if final_time > 0.0 or caught:
		return false
	var multiplier := (POWER_MULTIPLIER if powered else 1.0) * attacker_multiplier
	if shielding:
		if shield_hold < PARRY_WINDOW:
			_perfect_shield()
			return false
		shield_hp -= atk.damage * 3.0 * multiplier * (0.5 if passive == "schildmeister" else 1.0)
		if passive == "schildmeister":
			counter_time = COUNTER_TIME
			SpecialFX.popup(self, "KONTER!", Color(0.6, 0.85, 1.0))
		velocity.x = direction.x * 3.0
		if shield_hp <= 0.0:
			_break_shield()
		else:
			Audio.sfx("shield_block")
		return false
	if frozen > 0.0:
		_unfreeze()
	if pig_time > 0.0:
		_unpig()
	if boss:
		return _boss_hit(atk, direction, multiplier)
	if held_by:
		held_by._release_grab(false)
	if holding:
		_release_grab(false)
	if ledge_side != 0:
		_let_go_ledge()
	_stop_charge()
	charge_time = 0.0
	fast_falling = false
	fast_fall_armed = false
	flurry_left = 0
	damage += atk.damage * multiplier * _damage_taken_multiplier()
	since_hit = 0.0
	var knockback: float = (atk.base + damage * atk.scale) * multiplier * _knockback_multiplier()
	velocity = direction * knockback
	hitstun = 0.12 + knockback * 0.02
	if knockback > 13.0:
		# Weit weggeschleudert: Rauchspur hinterherziehen.
		SpecialFX.launch_trail(self, clampf(knockback * 0.03, 0.3, 1.0))
	pending_attack = ""
	dash_time = 0.0
	_end_flip()
	down_time = 0.0
	getup_time = 0.0
	launched = knockback > 11.0
	if knockback > 13.0:
		# Harter Schlag: das Bild stockt kurz und wackelt, je härter, desto länger.
		SpecialFX.hit_stop(self, clampf(0.03 + knockback * 0.004, 0.09, 0.16))
		SpecialFX.shake(self, clampf(knockback * 0.015, 0.2, 0.5), 0.35)
	_play_hit(direction, knockback)
	if knockback > 13.0 and not boss and _flies_out():
		ko_hit.emit(self)
	add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_TAKEN)
	var heavy: bool = atk.damage * multiplier >= 10.0
	Audio.sfx("hit_strong" if heavy else "hit_weak")
	if heavy or randf() < 0.3:
		say("au", "au", randf_range(0.97, 1.03), -2.0)
	return true


## Schild genau im richtigen Moment gedrückt: kein Schaden am Schild, der Angreifer stockt kurz.
func _perfect_shield() -> void:
	Audio.sfx("shield_block", 1.8)
	SpecialFX.perfect_shield(self)
	if passive == "schildmeister":
		counter_time = COUNTER_TIME
	if opponent and is_instance_valid(opponent) and not opponent.boss \
			and opponent.global_position.distance_to(global_position) < 4.0:
		opponent.stunned = maxf(opponent.stunned, 0.45)


## Schild zerbrochen: die Figur springt hoch und taumelt mit Sternen über dem Kopf.
func _break_shield() -> void:
	shield_hp = SHIELD_MAX * 0.4
	shielding = false
	shield_hold = 0.0
	stunned = SHIELD_BREAK_STUN
	velocity.y = 10.0
	Audio.sfx("shield_break")
	say("au")
	SpecialFX.shield_break(self)
	_show_dizzy()


func _show_dizzy() -> void:
	if dizzy_fx == null:
		dizzy_fx = Node3D.new()
		dizzy_fx.position.y = 2.15 * size_scale
		add_child(dizzy_fx)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.9, 0.25)
		for i in 3:
			var star := MeshInstance3D.new()
			var mesh := PrismMesh.new()
			mesh.size = Vector3(0.32, 0.32, 0.08)
			star.mesh = mesh
			star.material_override = mat
			var a := TAU * i / 3.0
			star.position = Vector3(cos(a) * 0.55, 0, sin(a) * 0.55)
			dizzy_fx.add_child(star)
	dizzy_fx.visible = true


## Sagt voraus, ob die Figur mit ihrer jetzigen Geschwindigkeit aus der Arena fliegt
## (vereinfachte Flugbahn ohne Plattformen, wie im Spiel: Schwerkraft und Abbremsen in der Luft).
func _flies_out() -> bool:
	var pos := Vector2(position.x, position.y)
	var vel := Vector2(velocity.x, velocity.y)
	var dt := 1.0 / 30.0
	for i in 60:
		vel.x = move_toward(vel.x, 0.0, 8.0 * dt)
		vel.y -= gravity * dt
		pos += vel * dt
		if not blast_zone.has_point(pos):
			# Nach unten raus zählt nur, wenn die Figur dabei nicht über der Bühne ist.
			return pos.y > blast_zone.position.y or absf(pos.x - blast_zone.get_center().x) > blast_zone.size.x * 0.3
		if vel.y < 0.0 and pos.y < position.y - 1.0:
			return false
	return false


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
	if visible and not boss:
		SpecialFX.blast(self, blast_zone)
	stocks -= 1
	damage = 0.0
	# Wer rausfliegt, verliert auch einen nicht benutzten Final Smash.
	final_smash_ready = false
	caught = false
	if is_instance_valid(final_aura):
		final_aura.queue_free()
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
	if held_by:
		held_by._release_grab(false)
	if holding:
		_release_grab(false)
	ledge_side = 0
	model_root.position.z = 0.0
	climb_time = 0.0
	climb_attack = false
	launched = false
	down_time = 0.0
	getup_time = 0.0
	_stop_charge()
	charge_time = 0.0
	fast_falling = false
	air_dodge_time = 0.0
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
	if showcase_spin:
		model_root.rotation.y = wrapf(model_root.rotation.y + SHOWCASE_SPIN_SPEED * delta, -PI, PI)
	else:
		var target_angle := facing * SIDE_ANGLE if controls_enabled or hitstun > 0.0 else 0.0
		if ledge_side != 0:
			# An der Kante: mit dem Gesicht zur Bühnenwand (fast mit dem Rücken zur Kamera).
			target_angle = ledge_side * deg_to_rad(160.0)
		model_root.rotation.y = lerp_angle(model_root.rotation.y, target_angle, (6.0 if not controls_enabled else 15.0) * delta)

	if roll_time <= 0.0:
		_update_flip(delta)
	_update_cloth(delta)

	shield_bubble.visible = shielding
	var shield_left := shield_hp / SHIELD_MAX
	shield_bubble.scale = Vector3.ONE * lerpf(0.35, 1.0, shield_left)
	if shielding:
		# Fast leeres Schild wird rot und flackert.
		var mat := shield_bubble.material_override as StandardMaterial3D
		var tint := color.lerp(Color(1, 0.15, 0.1), clampf(1.0 - shield_left * 2.0, 0.0, 1.0))
		var alpha := 0.35
		if shield_left < 0.25:
			alpha = 0.2 + 0.25 * absf(sin(Time.get_ticks_msec() * 0.02))
		mat.albedo_color = Color(tint, alpha)
		mat.emission = tint
	if dizzy_fx and dizzy_fx.visible:
		dizzy_fx.visible = stunned > 0.0
		dizzy_fx.rotation.y += 5.0 * delta

	var text := "P%d" % player_id
	if held_by:
		text += "\nGepackt!"
	elif charging and charge_time > 0.05:
		text += "\nLädt auf!"
	elif frozen > 0.0:
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

	# Ausweichen in der Luft: die Figur blinkt.
	if flip_pivot:
		flip_pivot.visible = air_dodge_time <= 0.0 or int(air_dodge_time * 30.0) % 2 == 0
		if not charging and roll_time <= 0.0 and flip_time < 0.0 and flip_pivot.position.x != 0.0:
			flip_pivot.position.x = 0.0

	if current_anim == "cheer" or frozen > 0.0:
		return
	if held_by:
		_play("stunned" if _has_anim("stunned") else "hit")
		return
	if ledge_side != 0 or holding or down_time > 0.0 or getup_time > 0.0:
		return
	if caught:
		_play("stunned" if _has_anim("stunned") else "hit")
	elif hitstun > 0.0:
		_play(hit_anim, 1.5 if hit_anim == "hit" else 1.0)
	elif stunned > 0.0:
		_play("stunned")
	elif roll_time > 0.0:
		return
	elif konter_time > 0.0:
		if current_anim != "konter" and current_anim != "shield":
			_play("konter")
	elif current_anim in ATTACKS or current_anim in ["weak", "strong", "kick", "special", "grab", "throw", "smash_charge"]:
		if attack_timer > 0.0 or _attack_anim_running():
			return
		_play_movement()
	elif shielding:
		_play("shield")
	else:
		_play_movement()


## Ein Schlag darf ganz zu Ende gespielt werden (auch wenn man schon wieder angreifen könnte), solange die Figur
## still steht bzw. beim Luftangriff noch in der Luft ist. Laufen, Springen, Schild oder ein Treffer brechen ihn ab.
func _attack_anim_running() -> bool:
	if anim_player == null or not anim_player.is_playing() or shielding:
		return false
	if anim_player.current_animation != Roster.anim_name(fighter, current_anim):
		return false
	if current_anim == "luft" or current_anim.begins_with("luft_"):
		return not is_on_floor()
	return is_on_floor() and absf(velocity.x) < 0.5


## Lädt bei Figuren mit "anim_dir" jede Aktion aus einer eigenen Datei (z. B. von Mixamo) in eine
## Animations-Bibliothek. Die Vorwärtsbewegung der Hüfte wird entfernt, damit nur das Spiel die Figur bewegt.
func _load_anim_files() -> void:
	var dir: String = fighter.get("anim_dir", "")
	if dir == "" or anim_player == null:
		return
	var lib := AnimationLibrary.new()
	for action in ["idle", "run", "jump", "fall", "weak", "strong", "kick", "special", "shield",
			"hit", "stunned", "dodge", "cheer", "luft"] + SMASH_ANIMS.keys() + DIR_ATTACKS.keys():
		var path: String = dir + fighter.get("anim_files", {}).get(action, action + ".fbx")
		if action == "luft" and not ResourceLoader.exists(path):
			path = LUFT_ANIM
		if (action in SMASH_ANIMS or action in DIR_ATTACKS) and not ResourceLoader.exists(path):
			path = SMASH_ANIM_DIR + action + ".fbx"
		if not ResourceLoader.exists(path):
			continue
		var scene: Node = load(path).instantiate()
		var source: AnimationPlayer = scene.find_child("AnimationPlayer", true, false)
		if source and not source.get_animation_list().is_empty():
			var anim: Animation = source.get_animation(source.get_animation_list()[0]).duplicate()
			_strip_root_motion(anim, not action.begins_with("luft_") and action != "aufwaerts")
			var trim: Array = fighter.get("anim_trim", {}).get(action,
				LUFT_TRIM if action == "luft" else SMASH_ANIMS.get(action, DIR_TRIM.get(action, [])))
			if trim.size() == 2:
				anim = _trim_animation(anim, trim[0], trim[1])
			lib.add_animation(action, anim)
		scene.free()
	if anim_player.has_animation_library(Roster.ANIM_LIB):
		anim_player.remove_animation_library(Roster.ANIM_LIB)
	anim_player.add_animation_library(Roster.ANIM_LIB, lib)


## keep_height false: auch das Hoch und Runter der Hüfte entfernen (Luftangriffe, die im Original springen).
func _strip_root_motion(anim: Animation, keep_height := true) -> void:
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_POSITION_3D or not str(anim.track_get_path(t)).ends_with("Hips"):
			continue
		var start: Vector3 = anim.track_get_key_value(t, 0)
		for k in anim.track_get_key_count(t):
			var p: Vector3 = anim.track_get_key_value(t, k)
			anim.track_set_key_value(t, k, Vector3(start.x, p.y if keep_height else start.y, start.z))


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
	if action in DIR_ATTACKS and not _has_anim(action):
		# Noch keine eigene Animation für den Richtungs-Angriff: eine ähnliche nehmen.
		action = DIR_ATTACKS[action]
	var is_attack := action in ["weak", "strong", "kick", "special", "luft"] or action in DIR_ATTACKS
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


## Treffer-Animation: von vorne getroffen taumelt die Figur nach hinten, von hinten nach vorne.
## Harte Treffer (weit weggeschleudert) haben eigene Animationen. Ohne passende Datei: normale Treffer-Animation.
func _play_hit(direction: Vector3, knockback: float) -> void:
	# Fliegt die Figur entgegen ihrer Blickrichtung weg, kam der Schlag von vorne.
	var from_front := direction.x * facing <= 0.0
	var kind := ("launch_" if knockback > 13.0 else "hit_") + ("front" if from_front else "back")
	if not _has_anim(kind):
		kind = "hit_" + ("front" if from_front else "back")
	hit_anim = kind if _has_anim(kind) else "hit"
	_play(hit_anim, 1.5 if hit_anim == "hit" else 1.0)
	if anim_player and current_anim == hit_anim:
		anim_player.seek(0.0, true)


## Nach einem harten Treffer gelandet: hinfallen (von hinten getroffen auf den Bauch, sonst auf den Rücken).
func _fall_down() -> void:
	hitstun = 0.0
	down_front = hit_anim.ends_with("back")
	down_time = DOWN_TIME
	down_elapsed = 0.0
	_play("knockdown_front" if down_front and _has_anim("knockdown_front") else "knockdown_back", 1.6)
	anim_player.seek(0.0, true)
	SpecialFX.dust(get_parent(), global_position, 10, 2.2)
	Audio.sfx("hit_weak", 0.6, -4.0)


## Liegen und Aufstehen. Eine Taste drücken (nach kurzer Zeit) lässt früher aufstehen.
func _update_down(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	if not is_on_floor():
		# Im Liegen über die Kante gerutscht: sofort wieder handeln können, damit man zurückspringen kann.
		down_time = 0.0
		getup_time = 0.0
		return
	if down_time > 0.0:
		down_time -= delta
		down_elapsed += delta
		var pressed := false
		if controls_enabled and down_elapsed >= DOWN_QUICK:
			for a in ["left", "right", "up", "down", "jump", "shield", "weak", "strong", "kick", "special"]:
				if Input.is_action_just_pressed(_action(a)):
					pressed = true
		if down_time <= 0.0 or pressed:
			down_time = 0.0
			getup_time = GETUP_TIME
			var getup := "getup_front" if down_front and _has_anim("getup_front") else "getup_back"
			if _has_anim(getup):
				var anim := anim_player.get_animation(Roster.anim_name(fighter, getup))
				_play(getup, anim.length / GETUP_TIME)
				anim_player.seek(0.0, true)
	else:
		getup_time -= delta
		if getup_time <= 0.0:
			getup_time = 0.0
			_play("idle")


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
		if dir == "down":
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
	# Waffen aus einem anderen Modell (z. B. Schwert und Schild des KayKit-Ritters) in die Hände legen:
	# {Knochen: [Modell, Knotenname, Einstellungen]}. Wie die Waffe in der Faust liegt, wird aus den
	# Fingerknochen der Figur berechnet (siehe _hand_grip), deshalb passt sie bei jeder Figur.
	var attach_from: Dictionary = fighter.get("attach_from", {})
	for bone_name in attach_from:
		if skeleton.find_bone(bone_name) == -1:
			continue
		var entry: Array = attach_from[bone_name]
		var source: Node = load(entry[0]).instantiate()
		var weapon: Node3D = source.find_child(entry[1], true, false)
		if weapon:
			weapon = weapon.duplicate()
			var slot := BoneAttachment3D.new()
			slot.bone_name = bone_name
			skeleton.add_child(slot)
			slot.add_child(weapon)
			var opts: Dictionary = entry[2] if entry.size() > 2 else {}
			var s: float = 0.8 / fighter.get("scale", 0.8) * opts.get("groesse", 1.0)
			weapon.transform = _hold_transform(skeleton, bone_name, opts, s)
			weapon.visible = true
			if fighter.get("two_handed", false) and bone_name == "mixamorig_RightHand":
				two_hand_weapon = weapon
				two_hand_skeleton = skeleton
		source.free()

	# Gebauter Bogen in der linken Hand (siehe _make_bow), Einstellungen wie bei attach_from.
	if fighter.has("bow_hand") and skeleton.find_bone("mixamorig_LeftHand") != -1:
		var slot := BoneAttachment3D.new()
		slot.bone_name = "mixamorig_LeftHand"
		skeleton.add_child(slot)
		var bow := _make_bow()
		var opts: Dictionary = fighter.bow_hand
		bow.transform = _hold_transform(skeleton, "mixamorig_LeftHand", opts, 0.8 / fighter.get("scale", 0.8) * opts.get("groesse", 1.0))
		slot.add_child(bow)

	# Hände, die etwas halten, zur Faust schließen (die Animationen haben oft offene oder zeigende Hände).
	var holding_hands: Array = attach_from.keys()
	if fighter.has("bow_hand"):
		holding_hands.append("mixamorig_LeftHand")
	if not holding_hands.is_empty():
		var fist := FistModifier.new()
		skeleton.add_child(fist)
		fist.setup(skeleton, holding_hands)

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


## Faust einer Hand im Raum des Handknochens: origin = Mitte der Faust (dort, wo ein Griff durchgeht),
## x = Richtung, in die ein gehaltener Stiel zum Daumen hin herausschaut, y = Richtung der Fingerknöchel
## (nach vorne aus der Faust), z = Handfläche. Mixamo-Hände: Finger entlang +y, Daumen bei der rechten Hand
## auf +x, bei der linken auf -x, Handfläche +z. Die genaue Lage kommt aus den Fingerknochen der Figur.
func _hand_grip(skeleton: Skeleton3D, bone_name: String) -> Transform3D:
	var bone := skeleton.find_bone(bone_name)
	var hand := skeleton.get_bone_global_rest(bone).affine_inverse()
	var prefix := bone_name  # z. B. mixamorig_RightHand -> mixamorig_RightHandIndex1
	var knuckles: Array[Vector3] = []
	for finger in ["Index1", "Middle1", "Ring1", "Pinky1"]:
		var i := skeleton.find_bone(prefix + finger)
		if i != -1:
			knuckles.append(hand * skeleton.get_bone_global_rest(i).origin)
	var side := -1.0 if "Left" in bone_name else 1.0
	# Länge der Hand: Unterarm-Länge als Maß, falls die Fingerknochen fehlen oder komisch sitzen.
	var size := skeleton.get_bone_rest(bone).origin.length() * 0.85
	var knuckle := Vector3(0, size, 0)
	if not knuckles.is_empty():
		knuckle = Vector3.ZERO
		for k in knuckles:
			knuckle += k
		knuckle /= knuckles.size()
		if knuckles.size() == 1:
			# Nur der Zeigefinger: die Mitte der Knöchel liegt etwas weiter zum kleinen Finger hin.
			knuckle.x -= side * knuckle.length() * 0.2
		knuckle = knuckle.normalized() * clampf(knuckle.length(), size * 0.6, size * 1.3)
	var forward := knuckle.normalized()
	var up := (Vector3(side, 0, 0) - forward * forward.x * side).normalized()
	var palm := side * up.cross(forward)
	var length := knuckle.length()
	return Transform3D(Basis(up, forward, palm), knuckle * 0.92 + palm * length * 0.28)


## Lage einer gehaltenen Sache im Handknochen. opts: "art" (griff, schild, buch, bogen), "griff" (Stelle auf dem
## Stiel in Waffen-Einheiten, an der die Faust sitzt), "dreh" (zusätzliche Drehung in Grad), "versatz"
## (zusätzliche Verschiebung in Faust-Richtungen x = Daumen, y = Knöchel, z = Handfläche, in Waffen-Einheiten),
## "umgekehrt" (Rückhandgriff: Klinge zeigt zum kleinen Finger), "rolle" (Faust um die Knöchel-Richtung drehen,
## in Grad, für Hände, deren Knochen anders liegt als bei Mixamo üblich).
func _hold_transform(skeleton: Skeleton3D, bone_name: String, opts: Dictionary, s: float) -> Transform3D:
	var fist := _hand_grip(skeleton, bone_name)
	var forward := fist.basis.y
	# "rolle": Faust um die Knöchel-Richtung drehen, für Hände ohne Daumenknochen, deren Knochen anders liegt.
	var roll := deg_to_rad(opts.get("rolle", 0.0))
	var up := fist.basis.x.rotated(forward, roll)
	var palm := fist.basis.z.rotated(forward, roll)
	if opts.get("umgekehrt", false):
		up = -up
	var basis: Basis
	var origin := fist.origin
	match opts.get("art", "griff"):
		"schild":
			# Schild vor der Faust, Vorderseite (+z) nach vorne, oben (+y) Richtung Daumen.
			basis = Basis(up.cross(forward), up, forward)
		"buch":
			# Aufgeschlagenes Buch liegt auf der Handfläche.
			basis = Basis(up, palm.cross(up), palm)
		"bogen":
			# Bogen: Wurfarme entlang des Griffs, Bauch (+z) nach vorne, Sehne zum Körper.
			basis = Basis(up.cross(forward), up, forward)
		_:
			# Stielwaffe: Stiel (+y) zum Daumen hinaus, Schneide/Kopf (-x) nach vorne aus der Faust.
			basis = Basis(-forward, up, -forward.cross(up))
	var extra: Vector3 = opts.get("dreh", Vector3.ZERO)
	basis = basis * Basis.from_euler(extra * PI / 180.0)
	var shift: Vector3 = opts.get("versatz", Vector3.ZERO)
	origin += (up * shift.x + forward * shift.y + palm * shift.z) * s
	# Die Griffstelle der Waffe kommt in die Faust.
	var grip: float = opts.get("griff", 0.0)
	origin -= basis.y * grip * s
	return Transform3D(basis.scaled(Vector3.ONE * s), origin)


## Einfacher Holzbogen aus Zylindern: Griff in der Mitte (Ursprung), Wurfarme entlang y, Sehne dahinter (-z).
func _make_bow() -> Node3D:
	var bow := Node3D.new()
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.27, 0.12)
	wood.roughness = 0.7
	var grip := StandardMaterial3D.new()
	grip.albedo_color = Color(0.2, 0.12, 0.06)
	var string_mat := StandardMaterial3D.new()
	string_mat.albedo_color = Color(0.9, 0.88, 0.8)
	# Wurfarme: je 4 Stücke, die sich nach außen immer mehr nach vorne (+z) biegen.
	var tips := []
	for side in [1, -1]:
		var pos := Vector3.ZERO
		var angle := 0.0
		for i in 4:
			var length := 0.17
			angle += deg_to_rad(11.0)
			var dir := Vector3(0, side * cos(angle), sin(angle))
			var piece := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.022 - i * 0.003
			mesh.bottom_radius = 0.026 - i * 0.003
			mesh.height = length
			piece.mesh = _baked(mesh)
			piece.material_override = wood
			bow.add_child(piece)
			piece.position = pos + dir * length * 0.5
			piece.basis = Basis(Vector3.RIGHT, side * angle) if side > 0 else Basis(Vector3.RIGHT, PI - angle)
			pos += dir * length
		tips.append(pos)
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.032
	handle_mesh.bottom_radius = 0.032
	handle_mesh.height = 0.14
	handle.mesh = _baked(handle_mesh)
	handle.material_override = grip
	bow.add_child(handle)
	var bowstring := MeshInstance3D.new()
	var string_mesh := CylinderMesh.new()
	string_mesh.top_radius = 0.004
	string_mesh.bottom_radius = 0.004
	string_mesh.height = tips[0].y - tips[1].y
	bowstring.mesh = _baked(string_mesh)
	bowstring.material_override = string_mat
	bowstring.position = Vector3(0, (tips[0].y + tips[1].y) * 0.5, tips[0].z)
	bow.add_child(bowstring)
	return bow


## Grundform als ArrayMesh (der Stoff-Shader liest die Vertex-Daten aller Teile der Figur).
func _baked(mesh: PrimitiveMesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.get_mesh_arrays())
	return out


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
	for foe in _enemies():
		var offset: Vector3 = foe.global_position - global_position
		var forward := offset.x * facing
		var reach: Vector2 = atk.range * reach_scale
		if forward > -0.3 and forward <= reach.x and absf(offset.y) <= reach.y:
			var angle: Vector2 = atk.angle
			if foe.take_hit(atk, Vector3(angle.x * facing, angle.y, 0).normalized(), power_time > 0.0,
					outgoing_multiplier()):
				add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_DEALT * 0.5)
				on_hit_landed(foe)
				if last:
					SpecialFX.impact(self, foe.global_position + Vector3(0, 1.0, 0), Color(1, 0.8, 0.3))


## Erdbeben: trifft alle, die in Reichweite am Boden (oder knapp darüber) stehen, und schleudert sie hoch.
func _quake_hit(atk: Dictionary) -> void:
	Target.hit_melee(self, atk.range, true)
	for foe in _enemies():
		var offset: Vector3 = foe.global_position - global_position
		var reach: Vector2 = atk.range * reach_scale
		if absf(offset.x) > reach.x or absf(offset.y) > reach.y:
			continue
		var side := 1.0 if offset.x >= 0.0 else -1.0
		var angle: Vector2 = atk.angle
		if foe.take_hit(atk, Vector3(angle.x * side, angle.y, 0).normalized(), power_time > 0.0, outgoing_multiplier()):
			add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_DEALT)
			on_hit_landed(foe)
			SpecialFX.impact(self, foe.global_position + Vector3(0, 0.6, 0), color)


## In der Luft: Abwehren antippen = ausweichen (kurz unverwundbar, einmal pro Sprung),
## Runter halten = schnell fallen, sobald es abwärts geht.
func _update_air_moves() -> void:
	if Input.is_action_just_pressed(_action("down")):
		fast_fall_armed = true
	if Input.is_action_just_pressed(_action("shield")):
		if not air_dodge_used and pending_attack == "":
			air_dodge_used = true
			launched = false
			air_dodge_time = AIR_DODGE_TIME
			var dir := Input.get_axis(_action("left"), _action("right"))
			velocity.x = dir * AIR_DODGE_SPEED
			velocity.y = maxf(velocity.y, 0.0)
			_end_flip()
			Audio.sfx("dash", 1.3, -6.0)
	if not Input.is_action_pressed(_action("down")):
		fast_fall_armed = false
	if fast_fall_armed and not fast_falling and air_dodge_time <= 0.0 and velocity.y <= 0.0 and pending_attack == "":
		fast_falling = true
		Audio.sfx("swing_weak", 0.7, -8.0)


## Smash-Angriff: starken Angriff gedrückt halten, loslassen schlägt zu (je länger, desto stärker).
func _start_charge(kind := "strong") -> void:
	start_attack(kind)
	charging = true
	charge_time = 0.0


## Läuft, solange die Figur oben in der Ausholbewegung wartet. Gibt true zurück, solange weiter geladen wird.
func _update_charge(delta: float) -> bool:
	if Input.is_action_pressed(_action("strong")) and charge_time < CHARGE_MAX and is_on_floor() and controls_enabled:
		charge_time = minf(charge_time + delta, CHARGE_MAX)
		attack_timer = maxf(attack_timer, ATTACKS.strong.cooldown - ATTACKS.strong.startup)
		var ratio := charge_time / CHARGE_MAX
		# Die Figur holt groß aus (eigene Animation) oder bleibt in der Ausholbewegung stehen und zittert immer stärker.
		if _has_anim("smash_charge"):
			if current_anim != "smash_charge":
				_play("smash_charge")
		elif anim_player and frozen <= 0.0:
			anim_player.speed_scale = 0.0
		flip_pivot.position.x = randf_range(-1.0, 1.0) * 0.06 * ratio
		if int(charge_time * 10.0) != int((charge_time - delta) * 10.0):
			SpecialFX._sparks(get_parent(), global_position + Vector3(0.3 * facing, 1.2, 0), color, 3 + int(ratio * 6.0), 2.0, 0.3)
		return true
	_stop_charge()
	if current_anim == "smash_charge":
		# Losgelassen: direkt in den Schlag (die Ausholbewegung ist schon vorbei).
		var kind := pending_attack if pending_attack != "" else "strong"
		_play(kind, ATTACKS[kind].anim_speed)
		anim_player.seek(ATTACKS[kind].startup * ATTACKS[kind].anim_speed, true)
	if charge_time > CHARGE_MAX * 0.5:
		SpecialFX.popup(self, "SMASH!", color)
	return false


func _stop_charge() -> void:
	if not charging:
		return
	charging = false
	if flip_pivot:
		flip_pivot.position.x = 0.0
	if anim_player and frozen <= 0.0:
		anim_player.speed_scale = 1.0


## Kante greifen: sucht beim Fallen eine feste Bühnenkante vor oder hinter der Figur.
func _try_grab_ledge() -> void:
	var space := get_world_3d().direct_space_state
	for side in [facing, -facing]:
		# 1) Waagerecht in Brusthöhe zur Seite: trifft die Wand der Bühne?
		var wall := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.3, 0),
			global_position + Vector3(side * 0.9, 1.3, 0), 1, [get_rid()])
		var wall_hit := space.intersect_ray(wall)
		if wall_hit.is_empty() or not wall_hit.collider is StaticBody3D or wall_hit.normal.x * side > -0.7:
			continue
		# 2) Von oben auf die Wand: die Oberkante muss knapp über dem Kopf liegen.
		var edge_x: float = wall_hit.position.x
		var down := PhysicsRayQueryParameters3D.create(Vector3(edge_x + side * 0.1, global_position.y + 2.4, 0),
			Vector3(edge_x + side * 0.1, global_position.y + 1.3, 0), 1, [get_rid()])
		var top_hit := space.intersect_ray(down)
		if top_hit.is_empty() or top_hit.collider != wall_hit.collider or top_hit.normal.y < 0.7:
			continue
		# Steht direkt darunter Boden (z. B. neben einer Stufe), lohnt sich Festhalten nicht.
		var below := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.1, 0),
			global_position + Vector3(0, -1.5, 0), 3, [get_rid()])
		if not space.intersect_ray(below).is_empty():
			continue
		# Hängt der Gegner schon an dieser Kante, ist kein Platz.
		if rivals.any(func(r): return is_instance_valid(r) and r.ledge_side == side and absf(r.ledge_x - edge_x) < 0.5):
			continue
		_grab_ledge(side, edge_x, top_hit.position.y)
		return


func _grab_ledge(side: int, edge_x: float, top: float) -> void:
	ledge_side = side
	ledge_x = edge_x
	ledge_top = top
	hang_time = 0.0
	facing = side
	velocity = Vector3.ZERO
	global_position = Vector3(edge_x - side * 0.42, top - LEDGE_HANG_DROP, global_position.z)
	# Die Figur hängt sichtbar vorne an der Bühne (sonst verdeckt sie die Vorderseite der Bühne).
	var space := get_world_3d().direct_space_state
	var front := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(edge_x + side * 0.2, top - 0.2, 8.0),
		Vector3(edge_x + side * 0.2, top - 0.2, global_position.z), 1, [get_rid()]))
	model_root.position.z = (front.position.z - global_position.z + 0.3) if not front.is_empty() else 0.0
	jumps_left = max_jumps
	special_air_used = false
	fast_falling = false
	fast_fall_armed = false
	air_dodge_used = false
	pending_attack = ""
	attack_timer = 0.0
	_end_flip()
	if ledge_invuln_ready:
		ledge_invuln = LEDGE_INVULN
		ledge_invuln_ready = false
	Audio.sfx("shield_block", 1.6, -8.0)
	_play("ledge_hang" if _has_anim("ledge_hang") else "fall" if _has_anim("fall") else "jump")


## An der Kante: Springen = hochspringen, zur Bühne = hochklettern, Angriff = hochklettern und treten,
## weg von der Bühne oder Abwehren = loslassen.
func _update_ledge(delta: float) -> void:
	velocity = Vector3.ZERO
	hang_time += delta
	jumps_left = max_jumps
	if climb_time > 0.0:
		climb_time -= delta
		if climb_time <= 0.0:
			_finish_climb()
		return
	if not controls_enabled:
		return
	var toward := "right" if ledge_side > 0 else "left"
	var away := "left" if ledge_side > 0 else "right"
	if hitstun > 0.0 or stunned > 0.0 or hang_time > LEDGE_HANG_MAX or Input.is_action_just_pressed(_action(away)) \
			or Input.is_action_just_pressed(_action("down")):
		_let_go_ledge()
		velocity.y = -2.0
	elif Input.is_action_just_pressed(_action("jump")):
		_let_go_ledge()
		velocity.y = jump_velocity
		jumps_left = max_jumps - 1
		jumped = true
		Audio.sfx("jump")
	elif hang_time > 0.15 and (Input.is_action_just_pressed(_action(toward)) or Input.is_action_just_pressed(_action("up"))):
		_climb_ledge()
	elif hang_time > 0.15 and (Input.is_action_just_pressed(_action("weak")) or Input.is_action_just_pressed(_action("strong")) \
			or Input.is_action_just_pressed(_action("kick"))):
		_climb_ledge(true)


## Hochklettern: mit Kletter-Animation erst nach CLIMB_TIME oben, sonst sofort. attack: oben gleich treten.
func _climb_ledge(attack := false) -> void:
	climb_attack = attack
	ledge_invuln = maxf(ledge_invuln, CLIMB_TIME + 0.25)
	if _has_anim("ledge_climb") and climb_time <= 0.0:
		climb_time = CLIMB_TIME
		var anim := anim_player.get_animation(Roster.anim_name(fighter, "ledge_climb"))
		_play("ledge_climb", anim.length / CLIMB_TIME)
		Audio.sfx("jump", 0.8, -4.0)
		return
	_finish_climb()


func _finish_climb() -> void:
	climb_time = 0.0
	var side := ledge_side
	_let_go_ledge()
	ledge_regrab = 0.0
	global_position = Vector3(ledge_x + side * 0.55, ledge_top + 0.05, global_position.z)
	velocity = Vector3.ZERO
	SpecialFX.dust(get_parent(), global_position, 6, 1.4)
	Audio.sfx("jump", 0.8, -4.0)
	_play("idle")
	if climb_attack:
		climb_attack = false
		start_attack("kick")


func _let_go_ledge() -> void:
	ledge_side = 0
	model_root.position.z = 0.0
	ledge_regrab = LEDGE_REGRAB


## Greifen: kurz zupacken. Trifft der Griff, ist der Gegner gepackt, auch wenn er abwehrt.
func start_grab() -> void:
	if attack_timer > 0.0 or holding or boss:
		return
	shielding = false
	start_attack("griff")
	if _has_anim("grab"):
		_play("grab", 1.6)
		anim_player.seek(0.0, true)
	else:
		_play("weak", ATTACKS.griff.anim_speed)


func _try_grab() -> bool:
	if opponent == null or not opponent.visible or opponent.boss or opponent.held_by or opponent.holding:
		return false
	if opponent.roll_time > 0.0 or opponent.air_dodge_time > 0.0 or opponent.ledge_invuln > 0.0 \
			or opponent.dome_time > 0.0 or opponent.ledge_side != 0:
		return false
	var offset := opponent.global_position - global_position
	var forward := offset.x * facing
	if forward < -0.3 or forward > GRAB_RANGE.x * reach_scale or absf(offset.y) > GRAB_RANGE.y:
		return false
	holding = opponent
	opponent.held_by = self
	opponent._on_grabbed()
	# Je mehr Schaden der Gegner hat, desto länger kann man ihn halten.
	grab_hold = GRAB_HOLD_TIME + minf(opponent.damage, 150.0) * 0.008
	attack_timer = 0.0
	_play("grab_hold" if _has_anim("grab_hold") else "idle")
	Audio.sfx("shield_block", 0.7)
	SpecialFX.popup(self, "GEPACKT!", color)
	return true


## Wird beim Gepackten aufgerufen: alles abbrechen, was er gerade tut.
func _on_grabbed() -> void:
	shielding = false
	_stop_charge()
	charge_time = 0.0
	pending_attack = ""
	attack_timer = 0.0
	dash_time = 0.0
	flurry_left = 0
	fast_falling = false
	velocity = Vector3.ZERO
	_end_flip()


## Im Griff: schwacher Angriff = zuschlagen, links/rechts = nach vorne oder hinten werfen,
## Springen = nach oben werfen, Abwehren = nach unten werfen. Läuft die Zeit ab, kommt der Gegner frei.
func _update_holding(delta: float) -> void:
	velocity = Vector3.ZERO
	if not is_instance_valid(holding) or not holding.visible or holding.held_by != self:
		holding = null
		return
	holding.global_position = Vector3(global_position.x + facing * 0.85, global_position.y, holding.global_position.z)
	holding.velocity = Vector3.ZERO
	grab_hold -= delta
	if not controls_enabled:
		_release_grab(true)
		return
	var back := "left" if facing > 0 else "right"
	var front := "right" if facing > 0 else "left"
	if Input.is_action_just_pressed(_action(front)):
		_throw("vorne")
	elif Input.is_action_just_pressed(_action(back)):
		_throw("hinten")
	elif Input.is_action_just_pressed(_action("up")):
		_throw("oben")
	elif Input.is_action_just_pressed(_action("down")):
		_throw("unten")
	elif Input.is_action_just_pressed(_action("weak")) and pummel_cooldown <= 0.0:
		pummel_cooldown = 0.3
		holding.damage += GRAB_PUMMEL_DAMAGE * outgoing_multiplier()
		add_special_energy(GRAB_PUMMEL_DAMAGE * SPECIAL_PER_DAMAGE_DEALT)
		SpecialFX.hit(self, holding.global_position + Vector3(0, 1.0, 0), color, GRAB_PUMMEL_DAMAGE)
		Audio.sfx("hit_weak", 1.2)
		_play("weak", 2.5)
	elif grab_hold <= 0.0:
		_release_grab(true)


## Gepackt: festgehalten. Schnell Tasten drücken hilft, früher freizukommen.
func _update_held() -> void:
	if not is_instance_valid(held_by) or held_by.holding != self:
		held_by = null
		return
	velocity = Vector3.ZERO
	for a in ["left", "right", "up", "down", "jump", "weak", "strong", "kick", "special"]:
		if Input.is_action_just_pressed(_action(a)):
			held_by.grab_hold -= 0.08


func _throw(kind: String) -> void:
	var target := holding
	var throw: Dictionary = THROWS[kind]
	_release_grab(false)
	var side := facing
	if kind == "hinten":
		# Umdrehen und hinter sich werfen.
		facing = -facing
	var dir := Vector3(throw.angle.x * side, throw.angle.y, 0).normalized()
	if target.take_hit(throw, dir, power_time > 0.0, outgoing_multiplier()):
		# Geworfen: landet immer auf dem Boden und muss aufstehen.
		target.launched = true
		add_special_energy(throw.damage * SPECIAL_PER_DAMAGE_DEALT)
		on_hit_landed(target)
		SpecialFX.hit(self, target.global_position + Vector3(0, 1.0, 0), color, throw.damage)
	if kind == "unten":
		SpecialFX.dust(get_parent(), target.global_position, 10, 2.0)
	attack_timer = 0.35
	Audio.sfx("swing_strong")
	_shout()
	if _has_anim("throw"):
		_play("throw", 1.6)
		anim_player.seek(0.0, true)
	else:
		_play("strong", 1.6)


## Griff lösen. push: beide werden ein Stück auseinandergeschoben (Gegner hat sich befreit).
func _release_grab(push: bool) -> void:
	var target := holding
	holding = null
	if target == null or not is_instance_valid(target):
		return
	target.held_by = null
	if push:
		target.velocity = Vector3(facing * 5.0, 3.0, 0)
		velocity.x = -facing * 4.0
		attack_timer = 0.3
		Audio.sfx("swing_weak", 0.8)


func _action(action_name: String) -> String:
	return "p%d_%s" % [player_id, action_name]
