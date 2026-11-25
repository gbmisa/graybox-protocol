class_name Spread
extends RefCounted
## A random direction within `angle` radians of `dir`, uniform over the cone's
## disc (r8 combat review: both guards' and the player's spread used to rotate
## about one fixed axis, so every miss went UP — shotgun pellets made a
## vertical line and a crouched player was never hit).

static func cone(dir: Vector3, angle: float) -> Vector3:
	if angle <= 0.0:
		return dir
	var side := dir.cross(Vector3.UP)
	if side.length() < 0.01:
		side = dir.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(dir).normalized()
	var r := angle * sqrt(randf())
	var a := randf() * TAU
	return (dir + (side * cos(a) + up * sin(a)) * tan(r)).normalized()
