class_name Levels
extends RefCounted
## Registry of playable levels: level id -> builder. Each builder's static
## `build(game)` returns the same shape (level_root, player_spawn,
## guard_posts), so the registry only has to say which builder answers for
## which id — GrayboxGame never names a builder script directly.

const DEFAULT_ID := "meridian"
const NAMES := {"meridian": "MERIDIAN CAPITAL", "compound": "HOLLOWAY ROAD"}

static func builder_for(id: String) -> Object:
	match id:
		"compound":
			return LevelCompound
		_:
			return LevelMeridian
