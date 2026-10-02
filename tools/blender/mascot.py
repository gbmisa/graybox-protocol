## CONSENTO, the Consent Score's mascot: a grinning blob on a plinth giving a
## thumbs-up. Built from metaballs, meshed, coloured by material, exported:
##   blender -b --python tools/blender/mascot.py -- <out.glb>
## Faces -Y in Blender (= +Z in Godot, toward whoever approaches); 4.2m tall.
import bpy, sys, math
from mathutils import Vector

out = sys.argv[sys.argv.index('--') + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, rgb, emit=0.0, rough=0.5):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    b.inputs['Base Color'].default_value = (*rgb, 1)
    b.inputs['Roughness'].default_value = rough
    if emit > 0:
        for key in ('Emission Color', 'Emission'):
            if key in b.inputs:
                b.inputs[key].default_value = (*rgb, 1)
        b.inputs['Emission Strength'].default_value = emit
    return m

def blob(name, elems, color, resolution=0.08):
    mb = bpy.data.metaballs.new(name)
    mb.resolution = resolution
    mb.render_resolution = resolution
    ob = bpy.data.objects.new(name, mb)
    bpy.context.scene.collection.objects.link(ob)
    for (co, r, kind, size) in elems:
        e = mb.elements.new(type=kind)
        e.co = co
        e.radius = r
        if kind == 'ELLIPSOID':
            e.size_x, e.size_y, e.size_z = size
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target='MESH')
    me = bpy.context.active_object
    me.name = name
    me.data.materials.append(color)
    bpy.ops.object.select_all(action='DESELECT')
    return me

skin = mat('skin', (0.55, 0.95, 0.20), rough=0.35)
pink = mat('pink', (1.0, 0.25, 0.6), rough=0.4)
white = mat('white', (0.95, 0.93, 0.86), rough=0.3)
ink = mat('ink', (0.03, 0.02, 0.05), rough=0.6)
stone = mat('stone', (0.45, 0.43, 0.48), rough=0.9)
glow = mat('glow', (1.0, 0.85, 0.2), emit=4.0)

# Body, head and arms as one metaball family so they fuse (one arm up, thumb
# raised; balls overlap by ~half a radius or they bead apart).
def arm(pts, r):
    out = []
    for i in range(len(pts) - 1):
        for t in (0.0, 0.33, 0.66):
            p = Vector(pts[i]).lerp(Vector(pts[i + 1]), t)
            out.append((tuple(p), r, 'BALL', None))
    out.append((pts[-1], r, 'BALL', None))
    return out

blob('body', [
    ((0, 0, 1.6), 1.15, 'ELLIPSOID', (1.0, 0.85, 1.1)),
    ((0, 0, 2.85), 0.95, 'BALL', None),
    ((0, 0, 0.75), 0.6, 'BALL', None),
] + arm([(0.8, 0, 2.0), (1.4, 0, 2.5), (1.6, 0, 3.2)], 0.42)
  + [((1.62, -0.05, 3.62), 0.26, 'BALL', None)]
  + arm([(-0.8, 0, 1.9), (-1.3, -0.1, 1.3), (-1.4, -0.15, 0.9)], 0.42), skin)

def sphere(name, loc, r, m, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=24, ring_count=12)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    o.data.materials.append(m)
    bpy.ops.object.shade_smooth()
    return o

# Eyes (one too big), cheeks, a grin with teeth.
sphere('eye_l', (-0.36, -0.82, 3.05), 0.26, white)
sphere('eye_r', (0.34, -0.80, 3.1), 0.34, white)
sphere('pupil_l', (-0.36, -1.06, 3.05), 0.11, ink, (1, 0.4, 1))
sphere('pupil_r', (0.38, -1.12, 3.14), 0.15, ink, (1, 0.4, 1))
sphere('cheek_l', (-0.62, -0.72, 2.7), 0.16, pink, (1, 0.4, 0.7))
sphere('cheek_r', (0.62, -0.72, 2.7), 0.16, pink, (1, 0.4, 0.7))
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.86, 2.5))
mouth = bpy.context.active_object
mouth.scale = (0.9, 0.12, 0.22)
mouth.data.materials.append(ink)
for k in range(7):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.39 + k * 0.13, -0.93, 2.57))
    t = bpy.context.active_object
    t.scale = (0.1, 0.05, 0.09)
    t.data.materials.append(white)
# A halo of score: a glowing ring over the head.
bpy.ops.mesh.primitive_torus_add(major_radius=0.6, minor_radius=0.05, location=(0, 0, 4.05))
bpy.context.active_object.data.materials.append(glow)
# Plinth.
bpy.ops.mesh.primitive_cylinder_add(radius=1.5, depth=0.6, location=(0, 0, 0.3), vertices=8)
bpy.context.active_object.data.materials.append(stone)

# Decimate the blobs a little; join everything; origin at the base.
for o in bpy.data.objects:
    if o.type == 'MESH' and o.name.startswith('body'):
        mod = o.modifiers.new('dec', 'DECIMATE')
        mod.ratio = 0.35
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier='dec')
        bpy.ops.object.shade_smooth()
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active = bpy.data.objects['body']
bpy.ops.object.join()
ob = bpy.context.active_object
ob.name = 'consento'
bpy.context.scene.cursor.location = (0, 0, 0)
bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
print('TRIS', sum(len(p.vertices) - 2 for p in ob.data.polygons))
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_apply=True)
print('EXPORTED', out)
