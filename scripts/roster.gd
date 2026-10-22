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
## anim_files: andere Datei für eine Aktion als <aktion>.fbx: {Aktion: Dateiname}
## anim_speeds: Abspielgeschwindigkeit je Aktion statt der Standardwerte aus Player.ATTACKS
## anim_trim: Animationen aus "anim_dir" zuschneiden: {Aktion: [von, bis]} in Sekunden
## scale:    Größe des Modells (Standard 0.8)
## rotation_y: Drehung des Modells in Grad, falls es nicht nach vorne schaut
## voice:    Stimmlage der Kampfrufe (1 = normal, kleiner = tiefer)
## flip:     Kunststück am höchsten Punkt eines Sprungs (siehe Player.FLIPS)
## passive:  passive Fähigkeit, wirkt immer (siehe PASSIVES)

const SPECIALS := {
	"feuerball": "Feuerball: fliegt geradeaus",
	"sturm": "Sturmangriff: schneller Stoß nach vorne",
	"wirbel": "Wirbel: trifft auf beiden Seiten",
	"aufwaerts": "Himmelshieb: springt hoch und schlägt nach oben",
	"lichtschild": "Lichtschild: kurz unverwundbar, dann explodiert die Kuppel",
	"erdbeben": "Erdbeben: Stampfer, Schockwelle über den Boden",
	"frost": "Frostzauber: Eiskugel, friert den Gegner ein",
	"pfeilregen": "Pfeilregen: Pfeile regnen auf den Gegner",
}

const PASSIVES := {
	"schildmeister": "Schildmeister: Schild hält doppelt so lange, nach dem Abwehren kontert er stärker",
	"berserker": "Berserker: je mehr Schaden, desto härter",
	"arkan": "Arkane Quelle: Spezial lädt viel schneller",
	"kritisch": "Kritisch: manchmal doppelter Schaden",
	"gift": "Giftklingen: Treffer vergiften",
	"panzerung": "Panzerung: nimmt weniger Schaden, etwas langsamer",
	"heldenmut": "Heldenmut: ab 80 % Schaden viel stärker",
	"heilung": "Heilung: heilt sich langsam, wenn er nicht getroffen wird",
	"schwergewicht": "Schwergewicht: kaum wegzuschleudern, trotzt dem Wind",
	"gleiten": "Gleiten: Sprungtaste in der Luft halten",
	"dreifachsprung": "Dreifachsprung: springt dreimal",
	"flink": "Flink: schneller und springt dreimal",
}

const KAYKIT_ANIMS := {
	"idle": "Idle", "run": "Running_A", "jump": "Jump_Idle", "hit": "Hit_A", "cheer": "Cheer",
	"kick": "Unarmed_Melee_Attack_Kick", "shield": "Blocking", "stunned": "Hit_B",
	"feuerball": "Spellcast_Shoot", "sturm": "Dodge_Forward", "wirbel": "2H_Melee_Attack_Spin",
	"aufwaerts": "1H_Melee_Attack_Chop", "dodge": "Dodge_Forward",
	"lichtschild": "Blocking", "erdbeben": "2H_Melee_Attack_Chop", "frost": "Spellcast_Shoot",
	"pfeilregen": "1H_Ranged_Shoot",
}
## Name der Animations-Bibliothek für Animationen aus einzelnen Dateien ("anim_dir").
const ANIM_LIB := "datei"
const KAYKIT_CHARS := "res://assets/kaykit/characters/"
const KAYKIT_WEAPONS := "res://assets/kaykit/weapons/"

const FIGHTERS := [
	{
		"name": "Barbar", "passive": "berserker", "flip": "rad", "voice": 0.85, "scene": KAYKIT_CHARS + "Barbarian.glb",
		"keep": ["2H_Axe"], "special": "wirbel",
		"weak": "2H_Melee_Attack_Slice", "strong": "2H_Melee_Attack_Chop",
	},
	{
		"name": "Magier", "passive": "arkan", "flip": "pirouette", "voice": 1.1, "scene": KAYKIT_CHARS + "Mage.glb",
		"keep": ["2H_Staff"], "special": "feuerball",
		"weak": "2H_Melee_Attack_Slice", "strong": "2H_Melee_Attack_Stab",
	},
	{
		"name": "Schurke", "passive": "kritisch", "flip": "doppelsalto", "voice": 1.2, "scene": KAYKIT_CHARS + "Rogue.glb",
		"keep": ["Knife", "Knife_Offhand"], "special": "sturm",
		"weak": "Dualwield_Melee_Attack_Stab", "strong": "Dualwield_Melee_Attack_Chop",
	},
	{
		"name": "Kapuzen-Schurke", "passive": "gift", "flip": "rueckwaerts", "voice": 1.15, "scene": KAYKIT_CHARS + "Rogue_Hooded.glb",
		"keep": ["Knife", "Knife_Offhand"], "special": "sturm",
		"weak": "Dualwield_Melee_Attack_Slice", "strong": "Dualwield_Melee_Attack_Chop",
	},
	{
		"name": "Robo", "passive": "panzerung", "flip": "propeller", "voice": 1.5, "scene": "res://assets/kenney/character.glb", "special": "feuerball",
		"anims": {"idle": "idle", "run": "walk", "jump": "jump"},
	},
	{
		# Eigene Figur: mit Flux + Trellis erzeugt, Skelett und Animationen von Mixamo.
		"name": "Held", "passive": "heldenmut", "flip": "salto", "voice": 1.0, "scene": "res://assets/ritter_neu/idle.fbx",
		"anim_dir": "res://assets/ritter_neu/", "scale": 195.0, "special": "aufwaerts",
		# Nur der eigentliche Angriff, ohne langes Ausholen und Zurückgehen.
		"anim_speeds": {"weak": 1.4, "strong": 1.0, "kick": 1.2},
		"anim_trim": {"weak": [0.25, 1.00], "strong": [0.15, 1.25], "kick": [0.30, 1.00], "special": [0.40, 1.30]},
		"attach_from": {
			"mixamorig_RightHand": [KAYKIT_CHARS + "Knight.glb", "1H_Sword", Vector3(0, -90, -90)],
			"mixamorig_LeftHand": [KAYKIT_CHARS + "Knight.glb", "Badge_Shield", Vector3(-90, 0, 135)],
		},
	},
	{
		"name": "Paladin", "passive": "heilung", "flip": "schraube", "voice": 0.95,
		"scene": KAYKIT_CHARS + "Paladin.glb", "keep": ["2H_Sword"], "special": "lichtschild",
		"weak": "2H_Melee_Attack_Slice", "strong": "2H_Melee_Attack_Chop",
	},
	{
		"name": "Brummbart", "passive": "schwergewicht", "flip": "purzeln", "voice": 0.75,
		"scene": KAYKIT_CHARS + "Brummbart.glb", "keep": ["1H_Axe", "Barbarian_Round_Shield"], "special": "erdbeben",
		"weak": "1H_Melee_Attack_Slice_Horizontal", "strong": "1H_Melee_Attack_Chop",
	},
	{
		"name": "Hexe", "passive": "gleiten", "flip": "schweben", "voice": 1.25,
		"scene": KAYKIT_CHARS + "Hexe.glb", "keep": ["1H_Wand", "Spellbook_open"], "special": "frost",
		"weak": "1H_Melee_Attack_Slice_Diagonal", "strong": "1H_Melee_Attack_Stab",
	},
	{
		"name": "Jägerin", "passive": "flink", "flip": "doppel_rueckwaerts", "voice": 1.3,
		"scene": KAYKIT_CHARS + "Jaegerin.glb", "keep": ["1H_Crossbow", "Knife_Offhand"], "special": "pfeilregen",
		"weak": "Dualwield_Melee_Attack_Stab", "strong": "1H_Melee_Attack_Chop",
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
