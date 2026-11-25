"""Knock the baked people down to Kenney-level detail (r8).

Gregory: "the people models don't fit the scene". The Quaternius bodies are
~12.5k-tri superhero sculpts; the level is Kenney low-poly. This collapses
each mesh to a few hundred faces so muscles become facets, keeping the rig,
weights, the clothing-mask vertex colours and every animation. Runs on the
GLBs people.py wrote (it needs no source zips) and overwrites them:

    blender -b -P tools/blender/people_lowpoly.py -- [ratio]

Run it once per people.py bake; running it twice decimates twice.
"""
import bpy, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "models", "people")
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RATIO = float(argv[0]) if argv else 0.12
HAIR_RATIO = 0.2


def lowpoly(fn):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=fn)
    for o in bpy.data.objects:
        if o.type != 'MESH':
            continue
        before = len(o.data.polygons)
        d = o.modifiers.new("Decimate", 'DECIMATE')
        d.decimate_type = 'COLLAPSE'
        d.ratio = RATIO if o.name == "Body" else HAIR_RATIO
        d.use_symmetry = True
        d.symmetry_axis = 'X'
        bpy.context.view_layer.objects.active = o
        while o.modifiers[0] != d:
            bpy.ops.object.modifier_move_up(modifier=d.name)
        bpy.ops.object.modifier_apply(modifier=d.name)
        for p in o.data.polygons:
            p.use_smooth = False
        print("LOWPOLY", os.path.basename(fn), o.name, before, "->", len(o.data.polygons))
    bpy.ops.export_scene.gltf(filepath=fn, export_format='GLB',
        export_animation_mode='ACTIONS', export_vertex_color='ACTIVE',
        export_image_format='JPEG', export_jpeg_quality=88,
        export_all_vertex_colors=False)


for sex in ("male", "female"):
    lowpoly(os.path.join(OUT, "person_%s.glb" % sex))
