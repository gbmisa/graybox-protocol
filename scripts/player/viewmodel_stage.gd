class_name ViewmodelStage
extends RefCounted
## Where `PlayerViewmodel` is drawn: a SubViewport with its own narrow-FOV
## camera, on a CanvasLayer under the HUD, staged far from the level with its
## own lights (see the viewmodel's header for why). Also the glove.

## Builds the stage under `player`, parents `rig` to its camera, and returns
## the camera.
static func build(player: Player, rig: Node3D, stage_pos: Vector3, fov: float,
		layer: int) -> Camera3D:
	var canvas := CanvasLayer.new()
	canvas.name = "ViewmodelLayer"
	canvas.layer = -1   # under PostFx (0), so the screen shader covers the gun too
	player.add_child(canvas)
	var box := SubViewportContainer.new()
	box.stretch = true
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(box)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.handle_input_locally = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	box.add_child(vp)
	var stage := Node3D.new()
	stage.position = stage_pos
	vp.add_child(stage)
	var cam := Camera3D.new()
	cam.fov = fov
	cam.near = 0.03
	cam.far = 4.0
	cam.cull_mask = layer
	cam.current = true
	cam.environment = _environment()
	stage.add_child(cam)
	cam.add_child(rig)
	# A key light from upper left and a cool fill from the right, both on the
	# weapon layer only: the world's lamps are 4km away and its ambient is a
	# night one, so without these the gun is a flat black cut-out.
	var key := DirectionalLight3D.new()
	key.light_cull_mask = layer
	key.light_energy = 1.3
	key.light_color = Color(1.0, 0.95, 0.88)
	key.rotation_degrees = Vector3(-40, 25, 0)
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_cull_mask = layer
	fill.light_energy = 0.45
	fill.light_color = Color(0.6, 0.7, 1.0)
	fill.rotation_degrees = Vector3(-10, -120, 0)
	stage.add_child(fill)
	# And a dim one riding on the rig itself.
	var l := OmniLight3D.new()
	l.position = Vector3(0.05, 0.08, 0.05)
	l.light_color = Color(0.85, 0.88, 1.0)
	l.light_energy = 1.7
	l.omni_range = 2.0
	l.light_cull_mask = layer
	rig.add_child(l)
	return cam

## The stage's own ambient, so the hand and gun read in any room. (Darkness is
## still carried by the world: a PITCH room is simply dark around the hand.)
static func _environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.72)
	env.ambient_light_energy = 0.6
	return env

## Matte near-black, a little blue so it still reads against a dark wall. Bare
## WRAD skin curled into a fist read as a pink lump.
static func glove() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.09, 0.09, 0.11)
	m.roughness = 0.85
	return m
