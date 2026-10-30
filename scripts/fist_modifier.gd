class_name FistModifier
extends SkeletonModifier3D
## Schließt die Finger einer Hand zur Faust, damit sie den Griff einer Waffe wirklich festhält.
## Läuft nach der Animation, überschreibt also nur die Finger der angegebenen Hände.

## Beugung je Fingerglied in Grad (Grundglied, Mittelglied, Endglied).
const CURL := [70.0, 90.0, 60.0]
const THUMB_CURL := [10.0, 35.0, 35.0]
const FINGERS := ["Index", "Middle", "Ring", "Pinky"]

## Knochen und die Drehung, die sie bekommen.
var _bones: Array[int] = []
var _poses: Array[Quaternion] = []


## hands: Knochennamen der Hände, z. B. ["mixamorig_RightHand"].
func setup(skeleton: Skeleton3D, hands: Array) -> void:
	for hand_name in hands:
		var hand := skeleton.find_bone(hand_name)
		if hand == -1:
			continue
		var hand_rest := skeleton.get_bone_global_rest(hand)
		# Mixamo-Hände: Finger entlang +y. Eine Drehung um -x biegt die Finger zur Handfläche (ausprobiert).
		var axis_hand := Vector3.RIGHT
		for finger in FINGERS + ["Thumb"]:
			var angles: Array = THUMB_CURL if finger == "Thumb" else CURL
			for joint in 3:
				var bone := skeleton.find_bone("%s%s%d" % [hand_name, finger, joint + 1])
				if bone == -1:
					continue
				# Die Achse aus Sicht des Fingerknochens (seine Ruhelage relativ zur Hand).
				var rel := (hand_rest.affine_inverse() * skeleton.get_bone_global_rest(bone)).basis.orthonormalized()
				var axis := (rel.inverse() * axis_hand).normalized()
				var rest := skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
				_bones.append(bone)
				_poses.append(rest * Quaternion(axis, -deg_to_rad(angles[joint])))


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	for i in _bones.size():
		skeleton.set_bone_pose_rotation(_bones[i], _poses[i])
