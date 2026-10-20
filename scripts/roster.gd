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
## scale:    Größe des Modells (Standard 0.8)

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
	"aufwaerts": "1H_Melee_Attack_Chop",
}
const KAYKIT_CHARS := "res://assets/kaykit/characters/"
const KAYKIT_WEAPONS := "res://assets/kaykit/weapons/"

const FIGHTERS := [
	{
		"name": "Ritter", "scene": KAYKIT_CHARS + "Knight.glb",
		"keep": ["1H_Sword", "Badge_Shield"], "special": "aufwaerts",
		"weak": "1H_Melee_Attack_Slice_Horizontal", "strong": "1H_Melee_Attack_Chop",
	},
	{
		"name": "Barbar", "scene": KAYKIT_CHARS + "Barbarian.glb",
		"keep": ["2H_Axe"], "special": "wirbel",
		"weak": "2H_Melee_Attack_Slice", "strong": "2H_Melee_Attack_Chop",
	},
	{
		"name": "Magier", "scene": KAYKIT_CHARS + "Mage.glb",
		"keep": ["2H_Staff"], "special": "feuerball",
		"weak": "2H_Melee_Attack_Slice", "strong": "2H_Melee_Attack_Stab",
	},
	{
		"name": "Schurke", "scene": KAYKIT_CHARS + "Rogue.glb",
		"keep": ["Knife", "Knife_Offhand"], "special": "sturm",
		"weak": "Dualwield_Melee_Attack_Stab", "strong": "Dualwield_Melee_Attack_Chop",
	},
	{
		"name": "Kapuzen-Schurke", "scene": KAYKIT_CHARS + "Rogue_Hooded.glb",
		"keep": ["Knife", "Knife_Offhand"], "special": "sturm",
		"weak": "Dualwield_Melee_Attack_Slice", "strong": "Dualwield_Melee_Attack_Chop",
	},
	{
		"name": "Skelett-Krieger", "scene": KAYKIT_CHARS + "Skeleton_Warrior.glb",
		"attach": {"handslot.r": KAYKIT_WEAPONS + "Skeleton_Blade.gltf", "handslot.l": KAYKIT_WEAPONS + "Skeleton_Shield_Small_A.gltf"},
		"special": "wirbel", "weak": "1H_Melee_Attack_Slice_Diagonal", "strong": "1H_Melee_Attack_Chop",
	},
	{
		"name": "Skelett-Magier", "scene": KAYKIT_CHARS + "Skeleton_Mage.glb",
		"attach": {"handslot.r": KAYKIT_WEAPONS + "Skeleton_Staff.gltf"},
		"special": "feuerball", "weak": "1H_Melee_Attack_Stab", "strong": "2H_Melee_Attack_Chop",
	},
	{
		"name": "Skelett-Schurke", "scene": KAYKIT_CHARS + "Skeleton_Rogue.glb",
		"attach": {"handslot.r": KAYKIT_WEAPONS + "Skeleton_Axe.gltf"},
		"special": "sturm", "weak": "1H_Melee_Attack_Slice_Horizontal", "strong": "1H_Melee_Attack_Chop",
	},
	{
		"name": "Skelett-Diener", "scene": KAYKIT_CHARS + "Skeleton_Minion.glb",
		"attach": {"handslot.r": KAYKIT_WEAPONS + "Skeleton_Blade.gltf"},
		"special": "aufwaerts", "weak": "1H_Melee_Attack_Stab", "strong": "1H_Melee_Attack_Slice_Diagonal",
		"anim_overrides": {"aufwaerts": "1H_Melee_Attack_Jump_Chop"},
	},
	{
		"name": "Robo", "scene": "res://assets/kenney/character.glb", "special": "feuerball",
		"anims": {"idle": "idle", "run": "walk", "jump": "jump"}, "scale": 1.4,
	},
]


static func count() -> int:
	return FIGHTERS.size()


static func get_fighter(index: int) -> Dictionary:
	return FIGHTERS[wrapi(index, 0, FIGHTERS.size())]


## Name der Modell-Animation für eine Aktion, oder "" wenn das Modell keine passende hat.
static func anim_name(fighter: Dictionary, action: String) -> String:
	if action in ["weak", "strong"]:
		return fighter.get(action, "")
	if action == "special":
		action = fighter.get("special", "")
	if action in fighter.get("anim_overrides", {}):
		return fighter.anim_overrides[action]
	return fighter.get("anims", KAYKIT_ANIMS).get(action, "")
