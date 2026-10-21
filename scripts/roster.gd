class_name Roster
## Alle wählbaren Kämpfer.
##
## scene:    das 3D-Modell
## keep:     Waffen, die im Modell sichtbar bleiben (alle anderen werden versteckt)
## attach:   Waffen, die zusätzlich an die Hände gehängt werden ("handslot.r" / "handslot.l")
## weak / strong: Animation für den schwachen und den starken Angriff
## special:  Art der Spezialattacke (siehe SPECIALS)
## anims:    welche Animation des Modells für welche Aktion benutzt wird
## anim_overrides: einzelne Animationen, die von den Standard-Animationen abweichen
## attach_from: Waffen aus einem anderen Modell an Knochen hängen: {Knochen: [Modell, Knotenname]}
## anim_dir: Ordner mit einer Animationsdatei pro Aktion (idle.fbx, run.fbx, weak.fbx, special.fbx …)
## scale:    Größe des Modells (Standard 0.8)
## rotation_y: Drehung des Modells in Grad, falls es nicht nach vorne schaut
## voice:    Stimmlage der Kampfrufe (1 = normal, kleiner = tiefer)
## flip:     Kunststück am höchsten Punkt eines Sprungs (siehe Player.FLIPS)

const SPECIALS := {
	"feuerball": "Feuerball: fliegt geradeaus",
	"sturm": "Sturmangriff: schneller Stoß nach vorne",
	"wirbel": "Wirbel: trifft auf beiden Seiten",
	"aufwaerts": "Aufwärtshieb: springt hoch und schlägt nach oben",
}

const KAYKIT_ANIMS := {
	"idle": "Idle", "run": "Running_A", "jump": "Jump_Idle", "hit": "Hit_A", "cheer": "Cheer",
	"kick": "Unarmed_Melee_Attack_Kick", "shield": "Blocking", "stunned": "Hit_B",
	"feuerball": "Spellcast_Shoot", "sturm": "Dodge_Forward", "wirbel": "2H_Melee_Attack_Spin",
	"aufwaerts": "1H_Melee_Attack_Chop", "dodge": "Dodge_Forward",
}
## Name der Animations-Bibliothek für Animationen aus einzelnen Dateien ("anim_dir").
const ANIM_LIB := "datei"
const KAYKIT_CHARS := "res://assets/kaykit/characters/"
const KAYKIT_WEAPONS := "res://assets/kaykit/weapons/"

const FIGHTERS := [
	{
		"name": "Ritter", "flip": "salto", "voice": 1.0, "scene": KAYKIT_CHARS + "Knight.glb",
		"keep": ["1H_Sword", "Badge_Shield"], "special": "aufwaerts",
		"weak": "1H_Melee_Attack_Slice_Horizontal", "strong": "1H_Melee_Attack_Chop",
	},
	{
		"name": "Barbar", "flip": "rad", "voice": 0.85, "scene": KAYKIT_CHARS + "Barbarian.glb",
		"keep": ["2H_Axe"], "special": "wirbel",
		"weak": "2H_Melee_Attack_Slice", "strong": "2H_Melee_Attack_Chop",
	},
	{
		"name": "Magier", "flip": "pirouette", "voice": 1.1, "scene": KAYKIT_CHARS + "Mage.glb",
		"keep": ["2H_Staff"], "special": "feuerball",
		"weak": "2H_Melee_Attack_Slice", "strong": "2H_Melee_Attack_Stab",
	},
	{
		"name": "Schurke", "flip": "doppelsalto", "voice": 1.2, "scene": KAYKIT_CHARS + "Rogue.glb",
		"keep": ["Knife", "Knife_Offhand"], "special": "sturm",
		"weak": "Dualwield_Melee_Attack_Stab", "strong": "Dualwield_Melee_Attack_Chop",
	},
	{
		"name": "Kapuzen-Schurke", "flip": "rueckwaerts", "voice": 1.15, "scene": KAYKIT_CHARS + "Rogue_Hooded.glb",
		"keep": ["Knife", "Knife_Offhand"], "special": "sturm",
		"weak": "Dualwield_Melee_Attack_Slice", "strong": "Dualwield_Melee_Attack_Chop",
	},
	{
		"name": "Skelett-Krieger", "flip": "schraube", "voice": 0.7, "scene": KAYKIT_CHARS + "Skeleton_Warrior.glb",
		"keep": ["Skeleton_Blade", "Skeleton_Shield_Small_A"],
		"special": "wirbel", "weak": "1H_Melee_Attack_Slice_Diagonal", "strong": "1H_Melee_Attack_Chop",
	},
	{
		"name": "Skelett-Magier", "flip": "schweben", "voice": 0.8, "scene": KAYKIT_CHARS + "Skeleton_Mage.glb",
		"keep": ["Skeleton_Staff"],
		"special": "feuerball", "weak": "1H_Melee_Attack_Stab", "strong": "2H_Melee_Attack_Chop",
	},
	{
		"name": "Skelett-Schurke", "flip": "doppel_rueckwaerts", "voice": 0.75, "scene": KAYKIT_CHARS + "Skeleton_Rogue.glb",
		"keep": ["Skeleton_Axe"],
		"special": "sturm", "weak": "1H_Melee_Attack_Slice_Horizontal", "strong": "1H_Melee_Attack_Chop",
	},
	{
		"name": "Skelett-Diener", "flip": "purzeln", "voice": 0.9, "scene": KAYKIT_CHARS + "Skeleton_Minion.glb",
		"keep": ["Skeleton_Blade"],
		"special": "aufwaerts", "weak": "1H_Melee_Attack_Stab", "strong": "1H_Melee_Attack_Slice_Diagonal",
		"anim_overrides": {"aufwaerts": "1H_Melee_Attack_Jump_Chop"},
	},
	{
		"name": "Robo", "flip": "propeller", "voice": 1.5, "scene": "res://assets/kenney/character.glb", "special": "feuerball",
		"anims": {"idle": "idle", "run": "walk", "jump": "jump"},
	},
	{
		# Eigene Figur: mit Flux + Trellis erzeugt, Skelett und Animationen von Mixamo.
		"name": "Held", "flip": "salto", "voice": 1.0, "scene": "res://assets/ritter_neu/idle.fbx",
		"anim_dir": "res://assets/ritter_neu/", "scale": 195.0, "special": "aufwaerts",
		"attach_from": {
			"mixamorig_RightHand": [KAYKIT_CHARS + "Knight.glb", "1H_Sword", Vector3(0, 0, -90)],
			"mixamorig_LeftHand": [KAYKIT_CHARS + "Knight.glb", "Badge_Shield", Vector3(-90, 0, 135)],
		},
	},
]


static func count() -> int:
	return FIGHTERS.size()


static func get_fighter(index: int) -> Dictionary:
	return FIGHTERS[wrapi(index, 0, FIGHTERS.size())]


## Name der Modell-Animation für eine Aktion, oder "" wenn das Modell keine passende hat.
static func anim_name(fighter: Dictionary, action: String) -> String:
	# Figuren mit "anim_dir": jede Aktion ist eine eigene Datei <aktion>.fbx (siehe Player._load_anim_files).
	if fighter.has("anim_dir"):
		return ANIM_LIB + "/" + action
	if action in ["weak", "strong"]:
		return fighter.get(action, "")
	if action == "special":
		action = fighter.get("special", "")
	if action in fighter.get("anim_overrides", {}):
		return fighter.anim_overrides[action]
	return fighter.get("anims", KAYKIT_ANIMS).get(action, "")
