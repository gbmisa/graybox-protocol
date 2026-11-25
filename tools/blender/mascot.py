## CONSENTO, the Consent Score's mascot (r7 redo: "the mascot is not very
## good"). A glossy yellow bean of a corporate friend: huge staring eyes with
## pin-prick pupils, a toothy grin, cartoon gloves — thumbs up, and a phone
## held out showing your score — sneakers, and a CCTV camera worn as a hat.
## On a plinth whose plaque thanks you for agreeing. Smooth (subdivided)
## primitives, Principled materials, exported as one GLB:
##
##   blender -b --python tools/blender/mascot.py -- <out.glb> [preview.png]
##
## Faces -Y in Blender (= +Z in Godot, toward whoever approaches); ~4.3m tall.
import bpy, sys, math
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
out = args[0]
preview = args[1] if len(args) > 1 else None
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def mat(name, rgb, rough=0.45, emit=0.0, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    b.inputs['Base Color'].default_value = (*rgb, 1)
    b.inputs['Roughness'].default_value = rough
    b.inputs['Metallic'].default_value = metal
    if emit > 0:
        for key in ('Emission Color', 'Emission'):
            if key in b.inputs:
                b.inputs[key].default_value = (*rgb, 1)
        b.inputs['Emission Strength'].default_value = emit
    return m


YELLOW = mat('consento_yellow', (1.0, 0.78, 0.10), 0.35)
BELLY = mat('consento_belly', (1.0, 0.93, 0.62), 0.4)
WHITE = mat('consento_white', (0.97, 0.97, 0.95), 0.25)
BLACK = mat('consento_black', (0.02, 0.02, 0.03), 0.2)
MOUTH = mat('consento_mouth', (0.16, 0.01, 0.03), 0.6)
TONGUE = mat('consento_tongue', (0.95, 0.35, 0.45), 0.5)
BLUSH = mat('consento_blush', (1.0, 0.45, 0.45), 0.6)
RED = mat('consento_red', (0.85, 0.08, 0.10), 0.4)
PURPLE = mat('consento_purple', (0.38, 0.12, 0.62), 0.55)
GREY = mat('consento_grey', (0.75, 0.76, 0.78), 0.3, metal=0.3)
LED = mat('consento_led', (1.0, 0.05, 0.05), 0.3, emit=6.0)
SCREEN = mat('consento_screen', (0.15, 1.0, 0.55), 0.3, emit=3.0)
CYAN = mat('consento_badge', (0.10, 0.85, 1.0), 0.3, emit=1.5)
STONE = mat('consento_plinth', (0.16, 0.15, 0.18), 0.6)
GOLD = mat('consento_gold', (1.0, 0.75, 0.25), 0.25, metal=1.0)

parts = []


def finish(ob, m, subdiv=2, smooth=True):
    ob.data.materials.append(m)
    if subdiv:
        mod = ob.modifiers.new('sub', 'SUBSURF')
        mod.levels = subdiv
        mod.render_levels = subdiv
    if smooth:
        for p in ob.data.polygons:
            p.use_smooth = True
    parts.append(ob)
    return ob


def sphere(loc, scale, m, subdiv=2, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, location=loc, rotation=rot)
    ob = bpy.context.object
    ob.scale = scale
    return finish(ob, m, subdiv)


def box(loc, scale, m, bevel=0.05, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    ob = bpy.context.object
    ob.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    if bevel:
        b = ob.modifiers.new('bev', 'BEVEL')
        b.width = bevel
        b.segments = 3
    return finish(ob, m, 0, smooth=bool(bevel))


def cyl(loc, r, depth, m, rot=(0, 0, 0), verts=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    ob = bpy.context.object
    b = ob.modifiers.new('bev', 'BEVEL')
    b.width = min(r, depth) * 0.2
    b.segments = 2
    return finish(ob, m, 0)


def tube(points, r, m):
    cu = bpy.data.curves.new('tube', 'CURVE')
    cu.dimensions = '3D'
    cu.bevel_depth = r
    cu.bevel_resolution = 4
    cu.use_fill_caps = True
    sp = cu.splines.new('BEZIER')
    sp.bezier_points.add(len(points) - 1)
    for bp, p in zip(sp.bezier_points, points):
        bp.co = p
        bp.handle_left_type = bp.handle_right_type = 'AUTO'
    ob = bpy.data.objects.new('tube', cu)
    scene.collection.objects.link(ob)
    ob.data.materials.append(m)
    parts.append(ob)
    return ob


def text(body, loc, size, m, depth=0.03, rot=(math.pi / 2, 0, 0)):
    cu = bpy.data.curves.new('txt', 'FONT')
    cu.body = body
    cu.size = size
    cu.extrude = depth
    cu.align_x = 'CENTER'
    cu.align_y = 'CENTER'
    ob = bpy.data.objects.new('txt', cu)
    ob.location = loc
    ob.rotation_euler = rot
    scene.collection.objects.link(ob)
    ob.data.materials.append(m)
    parts.append(ob)
    return ob


# --- plinth --------------------------------------------------------------
box((0, 0, 0.5), (1.0, 1.0, 0.5), STONE, 0.04)
box((0, 0, 1.03), (1.08, 1.08, 0.05), GOLD, 0.02)
text("CONSENTO\nTHANKS YOU\nFOR AGREEING", (0, -1.005, 0.5), 0.15, GOLD, 0.01)

# --- legs and sneakers ---------------------------------------------------
for sx in (-1, 1):
    tube([(0.36 * sx, 0, 1.75), (0.38 * sx, -0.02, 1.35), (0.40 * sx, -0.05, 1.18)], 0.13, YELLOW)
    sphere((0.42 * sx, -0.16, 1.17), (0.24, 0.38, 0.15), RED)
    sphere((0.42 * sx, -0.16, 1.1), (0.25, 0.4, 0.07), WHITE, 1)
    sphere((0.42 * sx, -0.40, 1.2), (0.16, 0.12, 0.1), WHITE, 1)   # toe cap

# --- body ----------------------------------------------------------------
body = sphere((0, 0, 2.55), (1.0, 0.86, 1.18), YELLOW, 3)
sphere((0, -0.48, 2.2), (0.66, 0.42, 0.62), BELLY, 2)
sphere((0, -0.86, 2.15), (0.17, 0.05, 0.17), CYAN, 1)          # badge
text("C", (0, -0.915, 2.15), 0.24, WHITE, 0.01)

# --- face ----------------------------------------------------------------
for sx in (-1, 1):
    sphere((0.34 * sx, -0.66, 3.05), (0.3, 0.24, 0.34), WHITE, 2)      # eyeball
    sphere((0.30 * sx, -0.885, 3.02), (0.055, 0.03, 0.055), BLACK, 1)  # pin-prick pupil
    sphere((0.33 * sx, -0.89, 3.06), (0.02, 0.01, 0.02), WHITE, 0)     # glint
    sphere((0.62 * sx, -0.6, 2.72), (0.13, 0.04, 0.08), BLUSH, 1, (0, 0, -0.5 * sx))
    tube([(0.18 * sx, -0.84, 3.46), (0.34 * sx, -0.86, 3.52), (0.5 * sx, -0.8, 3.46)], 0.03, BLACK)
# The grin: a D on its back — flat top under the teeth, round below — too
# wide, too many teeth, set into the face.
grin = sphere((0, -0.76, 2.74), (0.56, 0.16, 0.34), MOUTH, 2)
bpy.ops.mesh.primitive_cube_add(location=(0, -0.76, 3.1))
cut = bpy.context.object
cut.scale = (0.8, 0.4, 0.36)
bo = grin.modifiers.new('cut', 'BOOLEAN')
bo.operation = 'DIFFERENCE'
bo.object = cut
bpy.context.view_layer.objects.active = grin
for m in list(grin.modifiers):
    bpy.ops.object.modifier_apply(modifier=m.name)
bpy.data.objects.remove(cut)
for i in range(-4, 5):
    box((i * 0.1, -0.89, 2.69), (0.045, 0.03, 0.05), WHITE, 0.012)    # upper teeth
sphere((0, -0.86, 2.52), (0.18, 0.05, 0.06), TONGUE, 1)

# --- arms and gloves -----------------------------------------------------
# Right (his right, -X... the viewer's left): thumbs up, raised.
tube([(-0.9, -0.05, 2.55), (-1.35, -0.2, 2.65), (-1.45, -0.35, 3.15)], 0.12, YELLOW)
sphere((-1.45, -0.38, 3.32), (0.2, 0.17, 0.2), WHITE)               # fist
for i in range(4):
    sphere((-1.33 + 0.0, -0.53, 3.42 - i * 0.075), (0.06, 0.06, 0.04), WHITE, 1)   # knuckles
tube([(-1.5, -0.42, 3.45), (-1.51, -0.44, 3.58)], 0.085, WHITE)  # the thumb
sphere((-1.51, -0.44, 3.62), (0.085, 0.085, 0.08), WHITE, 1)
sphere((-1.45, -0.3, 3.08), (0.16, 0.16, 0.08), WHITE, 1)            # cuff
# Left: holding the phone out at you, screen first.
tube([(0.9, -0.05, 2.45), (1.3, -0.4, 2.2), (1.2, -0.9, 2.35)], 0.12, YELLOW)
sphere((1.18, -1.02, 2.38), (0.18, 0.15, 0.17), WHITE)
sphere((1.12, -1.0, 2.2), (0.15, 0.08, 0.15), WHITE, 1)              # cuff
box((1.05, -1.2, 2.55), (0.22, 0.025, 0.38), BLACK, 0.02, (0.25, 0, 0.1))
box((1.05, -1.23, 2.56), (0.19, 0.005, 0.33), SCREEN, 0, (0.25, 0, 0.1))
text("412", (1.05, -1.245, 2.58), 0.14, BLACK, 0.005, (math.pi / 2 + 0.25, 0, 0.1))

# --- the hat: a CCTV camera on a beanie ----------------------------------
sphere((0, -0.05, 3.62), (0.62, 0.55, 0.3), PURPLE, 2)
sphere((0, -0.05, 3.9), (0.1, 0.1, 0.1), PURPLE, 1)                  # bobble mount
cyl((0, -0.05, 4.0), 0.05, 0.25, GREY)
box((0, -0.25, 4.18), (0.18, 0.42, 0.16), WHITE, 0.04, (-0.25, 0, 0))
cyl((0, -0.7, 4.07), 0.11, 0.12, BLACK, (math.pi / 2 - 0.25, 0, 0))
sphere((0, -0.76, 4.06), (0.07, 0.03, 0.07), mat('lens', (0.1, 0.2, 0.5), 0.05), 1)
sphere((0.12, -0.6, 4.25), (0.035, 0.035, 0.035), LED, 1)

# --- export ---------------------------------------------------------------
for ob in list(parts):
    ob.select_set(False)
if preview:
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
    scene.collection.objects.link(cam)
    cam.location = (3.2, -8.0, 3.2)
    d = Vector((0, 0, 2.4)) - cam.location
    cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    scene.camera = cam
    for loc, e in (((4, -6, 7), 900), ((-6, -4, 3), 300), ((0, 5, 5), 400)):
        l = bpy.data.objects.new('l', bpy.data.lights.new('l', 'AREA'))
        l.data.energy = e
        l.data.size = 4
        l.location = loc
        l.rotation_euler = (Vector((0, 0, 2.2)) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
        scene.collection.objects.link(l)
    w = bpy.data.worlds.new('w')
    w.use_nodes = True
    next(n for n in w.node_tree.nodes if n.type == 'BACKGROUND').inputs[0].default_value = (0.05, 0.04, 0.09, 1)
    scene.world = w
    scene.render.resolution_x = 900
    scene.render.resolution_y = 1100
    scene.render.filepath = preview
    bpy.ops.render.render(write_still=True)

# Curves and text become meshes; modifiers are applied by the exporter.
bpy.ops.object.select_all(action='DESELECT')
for ob in parts:
    if ob.type in ('CURVE', 'FONT'):
        ob.select_set(True)
bpy.context.view_layer.objects.active = next(o for o in parts if o.type in ('CURVE', 'FONT'))
bpy.ops.object.convert(target='MESH')
bpy.ops.object.select_all(action='DESELECT')
for ob in scene.objects:
    ob.select_set(ob.type == 'MESH')
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', use_selection=True, export_apply=True)
print("WROTE", out)
