class_name DefencePlan
extends RefCounted
## What the guards do when the alarm goes up. Playtest r6: "the guards are
## still bunching up ... they rush to the alarm. They should go to more
## defensible positions to make infiltration harder instead of a rush."
##
## So the alarm no longer sends everyone at the player. The guard nearest his
## last known position searches for him (SEARCHERS); every other free guard
## takes the nearest unmanned defensive post (MissionCompoundData.POSTS —
## chokepoints and high ground) and holds it, facing the way in. A held post
## is fought from, not left: see GuardBrain._hold.
##
## Sentries (one waypoint and a facing) are already on a post and keep it;
## G9 has the escort. Guards already holding keep theirs on a second alarm.

const SEARCHERS := 1
const POST_REACH := 70.0     # a guard further than this from every free post stays put
const TAKEN := 1.6           # a post this close to a guard standing on it is manned

static func man(game: GrayboxGame, posts: Array, keep: Array) -> int:
	var p := game.get_player()
	var at := p.global_position if p != null else Vector3.ZERO
	var pool: Array = []
	for g in game.guards:
		var gd := g as Guard
		if not gd.alive or gd.post_id in keep or gd.hold_pos != Vector3.INF:
			continue
		if _is_sentry(gd):
			gd.hold(gd.waypoints[0], gd.facing)   # his own post is his post
			continue
		pool.append(gd)
	# Nearest to the player searches; the rest dig in.
	pool.sort_custom(func(a: Guard, b: Guard) -> bool:
		return a.global_position.distance_to(at) < b.global_position.distance_to(at))
	var searching := 0
	var manned := 0
	for gd in pool:
		var g := gd as Guard
		if searching < SEARCHERS and g.state != Guard.State.ALERT:
			searching += 1
			g.enter_suspicious(at, 0.6)
			continue
		post_one(game, posts, g)
		manned += 1
	return manned

## The nearest unmanned post within reach; with none free he holds where he
## stands, facing the player — anything but a rush.
static func post_one(game: GrayboxGame, posts: Array, g: Guard) -> void:
	var free := posts.duplicate()
	for o in game.guards:
		var og := o as Guard
		if og != g and og.alive and og.hold_pos != Vector3.INF:
			_strike(free, og.hold_pos)
	# Nearest by straight line first, but only a post he can walk to: the
	# annex's posts are 20m from the north yard and a wall away.
	free.sort_custom(func(a: Array, b: Array) -> bool:
		return (a[0] as Vector3).distance_to(g.global_position) \
			< (b[0] as Vector3).distance_to(g.global_position))
	var best: Array = []
	for post in free:
		if (post[0] as Vector3).distance_to(g.global_position) > POST_REACH:
			break
		if _walkable(g, post[0]):
			best = post
			break
	if not best.is_empty():
		g.hold(best[0], float(best[1]))
		return
	var p := game.get_player()
	var to := (p.global_position - g.global_position) if p != null else Vector3.FORWARD
	g.hold(g.global_position, atan2(-to.x, -to.z))

static func _walkable(g: Guard, to: Vector3) -> bool:
	var path := GuardNav.path(g.get_world_3d(), g.global_position, to)
	return path.size() > 1 and path[path.size() - 1].distance_to(to) < 1.5

static func _is_sentry(g: Guard) -> bool:
	return g.waypoints.size() == 1 and g.has_facing

static func _strike(free: Array, at: Vector3) -> void:
	for post in free.duplicate():
		if (post[0] as Vector3).distance_to(at) < TAKEN:
			free.erase(post)
