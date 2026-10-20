class_name Roster
## Alle wählbaren Kämpfer.
##
## scene:   das 3D-Modell
## keep:    Waffen, die im Modell sichtbar bleiben (alle anderen werden versteckt)
## attach:  Waffen, die zusätzlich an die Hände gehängt werden ("handslot.r" / "handslot.l")
## anims:   welche Animation des Modells für welche Aktion benutzt wird
## scale:   Größe des Modells (Standard 0.8)

const KAYKIT_ANIMS := {
	"idle": "Idle", "run": "Running_A", "jump": "Jump_Idle", "hit": "Hit_A", "cheer": "Cheer",
}
const KAYKIT_CHARS := "res://assets/kaykit/characters/"
const KAYKIT_WEAPONS := "res://assets/kaykit/weapons/"

const FIGHTERS := [
	{
		"name": "Ritter", "scene": KAYKIT_CHARS + "Knight.glb",
		"keep": ["1H_Sword", "Badge_Shield"], "attack": "1H_Melee_Attack_Slice_Horizontal",
	},
	{
		"name": "Barbar", "scene": KAYKIT_CHARS + "Barbarian.glb",
		"keep": ["2H_Axe"], "attack": "2H_Melee_Attack_Chop",
	},
	{
		"name": "Magier", "scene": KAYKIT_CHARS + "Mage.glb",
		"keep": ["2H_Staff"], "attack": "2H_Melee_Attack_Slice",
	},
	{
		"name": "Schurke", "scene": KAYKIT_CHARS + "Rogue.glb",
		"keep": ["Knife", "Knife_Offhand"], "attack": "Dualwield_Melee_Attack_Stab",
	},
	{
		"name": "Kapuzen-Schurke", "scene": KAYKIT_CHARS + "Rogue_Hooded.glb",
		"keep": ["Knife", "Knife_Offhand"], "attack": "Dualwield_Melee_Attack_Slice",
	},
	{
		"name": "Skelett-Krieger", "scene": KAYKIT_CHARS + "Skeleton_Warrior.glb",
		"attach": {"handslot.r": KAYKIT_WEAPONS + "Skeleton_Blade.gltf", "handslot.l": KAYKIT_WEAPONS + "Skeleton_Shield_Small_A.gltf"},
		"attack": "1H_Melee_Attack_Slice_Diagonal",
	},
	{
		"name": "Skelett-Magier", "scene": KAYKIT_CHARS + "Skeleton_Mage.glb",
		"attach": {"handslot.r": KAYKIT_WEAPONS + "Skeleton_Staff.gltf"},
		"attack": "2H_Melee_Attack_Slice",
	},
	{
		"name": "Skelett-Schurke", "scene": KAYKIT_CHARS + "Skeleton_Rogue.glb",
		"attach": {"handslot.r": KAYKIT_WEAPONS + "Skeleton_Axe.gltf"},
		"attack": "1H_Melee_Attack_Chop",
	},
	{
		"name": "Skelett-Diener", "scene": KAYKIT_CHARS + "Skeleton_Minion.glb",
		"attach": {"handslot.r": KAYKIT_WEAPONS + "Skeleton_Blade.gltf"},
		"attack": "1H_Melee_Attack_Stab",
	},
	{
		"name": "Robo", "scene": "res://assets/kenney/character.glb",
		"anims": {"idle": "idle", "run": "walk", "jump": "jump"}, "scale": 1.4,
	},
]


static func count() -> int:
	return FIGHTERS.size()


static func get_fighter(index: int) -> Dictionary:
	return FIGHTERS[wrapi(index, 0, FIGHTERS.size())]


static func anim_name(fighter: Dictionary, action: String) -> String:
	if action == "attack":
		return fighter.get("attack", "")
	return fighter.get("anims", KAYKIT_ANIMS).get(action, "")
