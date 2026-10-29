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
	"justice": "Justice: ein riesiges goldenes Lichtschwert fällt auf den Gegner",
	"lichtschild": "Lichtschild: kurz unverwundbar, dann explodiert die Kuppel",
	"erdbeben": "Erdbeben: Stampfer, Schockwelle über den Boden",
	"frost": "Frostzauber: Eiskugel, friert den Gegner ein",
	"schwein": "Schweinezauber: verwandelt den Gegner 3 Sekunden in ein Schwein",
	"pfeilregen": "Pfeilregen: Pfeile regnen auf den Gegner",
	"hundert_faeuste": "Hundert Fäuste: sechs blitzschnelle Schläge",
	"breitseite": "Breitseite: Kanonenkugel, die explodiert",
	"laser": "Laserkanone: Laserstrahl aus dem Bauch, quer über die Arena",
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
	"innere_ruhe": "Innere Ruhe: still stehen lädt das Spezial doppelt so schnell",
	"pluendern": "Plündern: Treffer stehlen Spezial-Energie",
	"overcharge": "Overcharge: entlädt sich alle 7 Sekunden in einem Stromschlag, der Gegner in der Nähe trifft",
}

const KAYKIT_ANIMS := {
	"idle": "Idle", "run": "Running_A", "jump": "Jump_Idle", "hit": "Hit_A", "cheer": "Cheer",
	"kick": "Unarmed_Melee_Attack_Kick", "shield": "Blocking", "stunned": "Hit_B",
	"feuerball": "Spellcast_Shoot", "sturm": "Dodge_Forward", "wirbel": "2H_Melee_Attack_Spin",
	"aufwaerts": "1H_Melee_Attack_Chop", "dodge": "Dodge_Forward",
	"lichtschild": "Blocking", "erdbeben": "2H_Melee_Attack_Chop", "frost": "Spellcast_Shoot",
	"pfeilregen": "1H_Ranged_Shoot", "hundert_faeuste": "Unarmed_Melee_Attack_Punch_A",
	"breitseite": "1H_Ranged_Shoot",
}
## Name der Animations-Bibliothek für Animationen aus einzelnen Dateien ("anim_dir").
const ANIM_LIB := "datei"
const KAYKIT_CHARS := "res://assets/kaykit/characters/"
const KAYKIT_WEAPONS := "res://assets/kaykit/weapons/"

const FIGHTERS := [
	{
		# Eigene Figur aus ComfyUI (Flux + Trellis), Zweihand-Animationen von Mixamo; Fallen/Landen/Rolle/Taumeln
		# vom Kampfroboter. Große Axt vom KayKit-Barbaren (einhändig).
		"name": "Barbar", "passive": "berserker", "flip": "rad", "voice": 0.85,
		"scene": "res://assets/barbar/modell.fbx", "anim_dir": "res://assets/barbar/", "scale": 200.0, "special": "wirbel",
		"anim_speeds": {"weak": 2.0, "strong": 1.0, "kick": 1.6, "special": 1.0},
		"anim_trim": {"weak": [0.35, 0.85], "strong": [0.30, 1.05], "kick": [0.25, 0.95], "special": [0.50, 1.60]},
		"attach_from": {
			"mixamorig_RightHand": [KAYKIT_CHARS + "Barbarian.glb", "2H_Axe", Vector3(-85, 110, 158), Vector3(0.02, 0.19, -0.01)],
		},
	},
	{
		# Eigene Figur aus ComfyUI (Flux + Trellis), Animationen von Mixamo; Dolche vom KayKit-Schurken
		# (rechts normaler Griff, links Rückhandgriff).
		"name": "Schurke", "passive": "kritisch", "flip": "doppelsalto", "voice": 1.2,
		"scene": "res://assets/schurkin/idle.fbx", "anim_dir": "res://assets/schurkin/", "scale": 185.0, "special": "sturm",
		"anim_speeds": {"weak": 1.5, "strong": 1.1, "kick": 1.6, "special": 1.4},
		"anim_trim": {"weak": [0.05, 0.50], "strong": [0.20, 1.00], "kick": [0.25, 0.95], "special": [0.00, 1.40]},
		"attach_from": {
			"mixamorig_RightHand": [KAYKIT_CHARS + "Rogue.glb", "Knife", Vector3(0, -69, -50), Vector3.ZERO, 0.5],
			"mixamorig_LeftHand": [KAYKIT_CHARS + "Rogue.glb", "Knife_Offhand", Vector3(49, -19, 179), Vector3.ZERO, 0.5],
		},
	},
	{
		# Eigene Figur: mit Flux + Trellis erzeugt, Skelett und Animationen von Mixamo.
		"name": "Held", "passive": "heldenmut", "flip": "salto", "voice": 1.0, "scene": "res://assets/ritter_neu/idle.fbx",
		"anim_dir": "res://assets/ritter_neu/", "scale": 195.0, "special": "justice",
		# Nur der eigentliche Angriff, ohne langes Ausholen und Zurückgehen.
		"anim_speeds": {"weak": 1.4, "strong": 1.0, "kick": 1.2},
		"anim_trim": {"weak": [0.25, 1.00], "strong": [0.15, 1.25], "kick": [0.30, 1.00], "special": [0.40, 1.30]},
		"attach_from": {
			"mixamorig_RightHand": [KAYKIT_CHARS + "Knight.glb", "1H_Sword", Vector3(0, -90, -90)],
			"mixamorig_LeftHand": [KAYKIT_CHARS + "Knight.glb", "Badge_Shield", Vector3(-90, 0, 135)],
		},
	},
	{
		# Eigene Figur aus ComfyUI (Flux + Trellis, Kopf hinter dem Visier ergänzt), Schwert-und-Schild-Animationen
		# von Mixamo; Fallen/Landen/Rolle/Taumeln/Jubel vom Kampfroboter. Großer Hammer (assets/paladin/hammer.glb)
		# und Langschild vom KayKit-Paladin.
		"name": "Paladin", "passive": "heilung", "flip": "schraube", "voice": 0.95,
		"scene": "res://assets/paladin/modell.fbx", "anim_dir": "res://assets/paladin/", "scale": 190.0, "special": "lichtschild",
		"anim_speeds": {"weak": 2.0, "strong": 1.0, "kick": 1.6, "special": 1.3},
		"anim_trim": {"weak": [0.05, 0.55], "strong": [0.20, 0.95], "kick": [0.00, 0.70]},
		"attach_from": {
			"mixamorig_RightHand": ["res://assets/paladin/hammer.glb", "Hammer", Vector3(-43, -116, 106), Vector3(0.26, -0.15, 0.11)],
			"mixamorig_LeftHand": [KAYKIT_CHARS + "Paladin.glb", "Rectangle_Shield", Vector3(-90, 45, 0), Vector3(-0.35, 0, 0)],
		},
	},
	{
		"name": "Brummbart", "passive": "schwergewicht", "flip": "purzeln", "voice": 0.75,
		"scene": KAYKIT_CHARS + "Brummbart.glb", "keep": ["1H_Axe", "Barbarian_Round_Shield"], "special": "erdbeben",
		"weak": "1H_Melee_Attack_Slice_Horizontal", "strong": "1H_Melee_Attack_Chop",
	},
	{
		# Eigene Figur aus ComfyUI (Flux + Trellis), Zauber-Animationen von Mixamo (Magier-Paket),
		# Fallen/Landen/Tritt/Block/Rolle/Taumeln/Jubel vom Kampfroboter. Zauberstab und Buch von der KayKit-Hexe.
		"name": "Hexe", "passive": "gleiten", "flip": "schweben", "voice": 1.25,
		"scene": "res://assets/hexe/modell.fbx", "anim_dir": "res://assets/hexe/", "scale": 190.0, "special": "schwein",
		"anim_speeds": {"weak": 2.0, "strong": 1.35, "kick": 1.6, "special": 1.0},
		"anim_trim": {"weak": [0.35, 0.85], "strong": [1.00, 2.00], "kick": [0.25, 0.95], "special": [0.20, 1.20]},
		"attach_from": {
			"mixamorig_RightHand": [KAYKIT_CHARS + "Hexe.glb", "1H_Wand", Vector3(-41, 59, -91), Vector3(0, 0.07, 0)],
			"mixamorig_LeftHand": [KAYKIT_CHARS + "Hexe.glb", "Spellbook_open", Vector3(0, -90, -90)],
		},
	},
	{
		"name": "Jägerin", "passive": "flink", "flip": "doppel_rueckwaerts", "voice": 1.3,
		"scene": KAYKIT_CHARS + "Jaegerin.glb", "keep": ["1H_Crossbow", "Knife_Offhand"], "special": "pfeilregen",
		"bow": true,
		"weak": "Dualwield_Melee_Attack_Stab", "strong": "1H_Melee_Attack_Chop",
	},
	{
		# Platzhalter: rote Variante der KayKit-Schurkin, bis das eigene Modell aus ComfyUI fertig ist.
		"name": "Piratin", "passive": "pluendern", "flip": "rad", "voice": 1.2,
		"scene": KAYKIT_CHARS + "Piratin.glb", "keep": ["Knife"], "special": "breitseite",
		"weak": "1H_Melee_Attack_Slice_Diagonal", "strong": "1H_Melee_Attack_Chop",
	},
	{
		# Eigene Figur aus ComfyUI (Flux + Trellis), Skelett und Animationen von Mixamo.
		"name": "Mönch", "passive": "innere_ruhe", "flip": "doppelsalto", "voice": 1.05,
		"scene": "res://assets/moench/run.fbx", "anim_dir": "res://assets/moench/", "scale": 185.0,
		"special": "hundert_faeuste",
		# Mixamo-Schläge sind lang: nur der eigentliche Schlag, schneller abgespielt, damit er in der Angriffszeit ganz abläuft.
		"anim_speeds": {"weak": 1.5, "strong": 1.7, "kick": 1.6},
		"anim_trim": {"weak": [0.10, 0.45], "strong": [0.20, 1.40], "kick": [0.25, 0.95]},
	},
	{
		# Eigene Figur aus ComfyUI (Flux + Trellis), Skelett und Animationen von Mixamo.
		"name": "Kampfroboter", "passive": "overcharge", "flip": "propeller", "voice": 0.8,
		"scene": "res://assets/kampfroboter/idle.fbx", "anim_dir": "res://assets/kampfroboter/", "scale": 215.0,
		"special": "laser",
		"anim_speeds": {"weak": 1.7, "strong": 1.5, "kick": 1.6},
		"anim_trim": {"weak": [0.00, 0.40], "strong": [0.00, 1.10], "kick": [0.25, 0.95]},
	},
	{
		# Eigene Figur aus ComfyUI (Flux + Trellis), ersetzt den Magier. Skelett und Animationen von Mixamo.
		"name": "Magierin", "passive": "arkan", "flip": "pirouette", "voice": 1.2,
		"scene": "res://assets/magierin/idle.fbx", "anim_dir": "res://assets/magierin/", "scale": 195.0,
		"special": "feuerball",
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
	if action == "luft":
		return fighter.get("strong", "")
	if action == "special":
		action = fighter.get("special", "")
	if action in fighter.get("anim_overrides", {}):
		return fighter.anim_overrides[action]
	return fighter.get("anims", KAYKIT_ANIMS).get(action, "")
