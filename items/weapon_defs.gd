extends RefCounted
## Stats of the three weapons (GDD 4.11). Keyed by the inventory item id. Ranged weapons use a
## magazine (`GameState.mags`) that is refilled from the ammo item in the inventory; the axe
## needs nothing. Damage is per hit (the shotgun: per pellet, so `pellets * damage` up close).

const DEFS := {
	"axe": {
		"name": "Machado", "slot": 1, "ranged": false,
		"range": 2.0, "damage": 25.0, "cooldown": 0.75, "knock": 1.2,
		"noise": 7.0, "stun": 0.45,
		"model": "machado.glb", "length": 0.7,
		# viewmodel: `hold` = position in camera space, `tilt` = the model's own rotation in degrees
		"hold": Vector3(0.36, -0.4, -0.65), "tilt": Vector3(5.0, -75.0, 15.0),
	},
	"pistol": {
		"name": "Pistola", "slot": 2, "ranged": true,
		"ammo": "ammo_pistol", "mag": 6, "reload": 2.4,
		"range": 60.0, "damage": 35.0, "cooldown": 0.5, "pellets": 1, "spread": 0.0, "falloff": 0.0,
		"knock": 0.8, "noise": 45.0, "stun": 0.6, "kick": 2.0,
		"model": "pistola/pistola.fbx", "length": 0.2,
		"hold": Vector3(0.2, -0.17, -0.4), "tilt": Vector3(0.0, 0.0, 0.0),
	},
	"shotgun": {
		"name": "Espingarda", "slot": 3, "ranged": true,
		"ammo": "shells", "mag": 2, "reload": 3.4,
		"range": 25.0, "damage": 16.0, "cooldown": 0.9, "pellets": 5, "spread": 3.5, "falloff": 0.6,
		"knock": 2.5, "noise": 70.0, "stun": 0.9, "kick": 5.0,
		"model": "espingarda.glb", "length": 0.0,
		"hold": Vector3(0.22, -0.22, -0.5), "tilt": Vector3(0.0, 0.0, 0.0),
	},
}
## Order used by the cycle action and the number keys.
const ORDER := ["axe", "pistol", "shotgun"]


static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, {})


static func is_weapon(id: String) -> bool:
	return DEFS.has(id)


## Slot id for the key 1-3.
static func by_slot(slot: int) -> String:
	for id: String in ORDER:
		if DEFS[id].slot == slot:
			return id
	return ""
