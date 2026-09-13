class_name PtSteps
## Waypoint/gate/dash/kill/extract step lists for the PORT VESPER
## bot playthroughs. Teleports hop between validated standable points;
## gates, dashes, kills, and extractions use the real mechanics.
static func regular() -> Array:
	return [
		{"t": "t_spawn", "char": "regular"},
		{"t": "t_tp", "p": Vector3(70, 0, -64)},
		{"t": "t_tp", "p": Vector3(70, 0, -58)},
		{"t": "t_tp", "p": Vector3(70, 0, -40)},
		{"t": "t_tp", "p": Vector3(50, 0, -30)},
		{"t": "t_tp", "p": Vector3(30, 0, -25)},
		{"t": "t_gate", "door": Vector3(16, 1.5, -24),
			"at": Vector3(18.0, 0, -24), "hold": 4.0},
		{"t": "t_tp", "p": Vector3(12, 0, -24)},
		{"t": "t_tp", "p": Vector3(8, 0, -22)},
		{"t": "t_kill"},
		{"t": "t_tp", "p": Vector3(20, 0, -24)},
		{"t": "t_tp", "p": Vector3(35, 0, -15)},
		{"t": "t_tp", "p": Vector3(52, 0, 0)},
		{"t": "t_gate", "door": Vector3(52, 1.5, 5),
			"at": Vector3(52, 0, 2.8), "hold": 4.0},
		{"t": "t_tp", "p": Vector3(52.5, 0, 15)},
		{"t": "t_tp", "p": Vector3(52.5, 0, 30)},
		{"t": "t_extract", "p": Vector3(52.5, 0, 42)},
	]

static func wizard() -> Array:
	return [
		{"t": "t_spawn", "char": "wizard"},
		{"t": "t_tp", "p": Vector3(-58, 0, -40)},
		{"t": "t_tp", "p": Vector3(-58, 0, -26)},
		{"t": "t_tp", "p": Vector3(-52, 1.8, -26)},
		{"t": "t_tp", "p": Vector3(-44, 3.6, -26)},
		{"t": "t_dash", "from": Vector3(-41, 3.6, -26), "yaw": -PI / 2,
			"x0": -34.5, "x1": -21.5, "y": 3.6},
		{"t": "t_dash", "from": Vector3(-23, 3.6, -26), "yaw": -PI / 2,
			"x0": -16.0, "x1": 16.0, "y": 3.6},
		{"t": "t_tp", "p": Vector3(13, 3.6, -17)},
		{"t": "t_gate", "door": Vector3(13, 3.6, -20),
			"at": Vector3(13, 3.6, -18.2), "hold": 1.5},
		{"t": "t_tp", "p": Vector3(13, 0, -20)},
		{"t": "t_tp", "p": Vector3(8, 0, -22)},
		{"t": "t_kill"},
		{"t": "t_gate", "door": Vector3(16, 1.5, -24),
			"at": Vector3(14.2, 0, -24), "hold": 0.8},
		{"t": "t_tp", "p": Vector3(20, 0, -24)},
		{"t": "t_tp", "p": Vector3(10, 0, -40)},
		{"t": "t_extract", "p": Vector3(0, 0, -64)},
	]

static func chad() -> Array:
	return [
		{"t": "t_spawn", "char": "chad"},
		{"t": "t_tp", "p": Vector3(-96, 0, -40)},
		{"t": "t_tp", "p": Vector3(-96, 0, -30)},
		{"t": "t_gate", "door": Vector3(-96, 1.5, -27),
			"at": Vector3(-97.8, 0, -27), "hold": 1.0},
		{"t": "t_tp", "p": Vector3(-93, 0, -27)},
		{"t": "t_tp", "p": Vector3(-80, 0, -27)},
		{"t": "t_tp", "p": Vector3(-70, 0, -27)},
		{"t": "t_tp", "p": Vector3(-60, 0, -27)},
		{"t": "t_tp", "p": Vector3(-40, 0, -26)},
		{"t": "t_tp", "p": Vector3(-20, 0, -24)},
		{"t": "t_gate", "door": Vector3(-16, 1.5, -24),
			"at": Vector3(-18.0, 0, -24), "hold": 1.0},
		{"t": "t_tp", "p": Vector3(-12, 0, -24)},
		{"t": "t_tp", "p": Vector3(-8, 0, -22)},
		{"t": "t_kill"},
		{"t": "t_gate", "door": Vector3(-16, 1.5, -24),
			"at": Vector3(-14.2, 0, -24), "hold": 0.8},
		{"t": "t_tp", "p": Vector3(-20, 0, -24)},
		{"t": "t_tp", "p": Vector3(-10, 0, -40)},
		{"t": "t_extract", "p": Vector3(0, 0, -64)},
	]

