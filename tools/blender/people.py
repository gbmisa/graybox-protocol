# Bakes the game's people (r7: "do medium graphics for the models") from two
# CC0 Quaternius packs into assets/models/people/person_{male,female}.glb:
#
#   Universal Base Characters [Standard]  bodies (~12.5k tris), eyes,
#                                         eyebrows, the head-bone hairstyles
#   Universal Animation Library [Standard] the animations (same 65-bone rig)
#
# Each glb holds one armature, the body, eyes, brows, every hairstyle (the
# game shows one), and the animations named below. The bodies come in
# underwear, so the body mesh gets a CLOTHING MASK in its vertex colours,
# from each vertex's heaviest bone: R = top (spine, clavicles, arms to the
# wrist), G = bottom (pelvis, legs), B = shoes (feet). Head, neck and hands
# stay skin. `scripts/world/person.gdshader` paints the clothes from it.
#
# Download both packs from quaternius.com (itch "name your price", $0), unzip
# next to each other, then:
#
#   blender -b --python tools/blender/people.py -- <dir with both unzipped> <out dir>

import bpy, sys, os

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, OUT = argv[0], argv[1]
def find(pred):
    # The packs' folder names have [brackets] in them, which glob reads as
    # character classes, so walk instead.
    for d, dirs, files in os.walk(SRC):
        for n in dirs + files:
            if pred(d, n):
                return os.path.join(d, n)
    raise SystemExit("not found under %s" % SRC)

UAL = find(lambda d, n: n == "UAL1_Standard.glb")
BODIES = os.path.dirname(find(lambda d, n: n == "Superhero_Male_FullBody.gltf"))
HAIR = os.path.dirname(find(lambda d, n: n == "Hair_Buzzed.gltf" and "Rigged" in d))

ANIMS = {   # library name -> name in the game
    "Idle_Loop": "idle", "Walk_Loop": "walk", "Jog_Fwd_Loop": "jog", "Sprint_Loop": "sprint",
    "Pistol_Idle_Loop": "pistol_idle", "Pistol_Aim_Neutral": "aim", "Pistol_Shoot": "shoot",
    "Death01": "death", "Hit_Chest": "hit", "Crouch_Idle_Loop": "cower",
    "Idle_Talking_Loop": "talk",
}
TOP = ("spine", "clavicle", "upperarm", "lowerarm")
BOTTOM = ("pelvis", "thigh", "calf")
SHOES = ("foot", "ball")


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def imported(fn):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=fn)
    return [o for o in bpy.data.objects if o not in before]


def mask(body):
    me = body.data
    names = [g.name for g in body.vertex_groups]
    # The pack's own colour attributes are plain white; the exporter takes
    # the first, so they go.
    while len(me.color_attributes):
        me.color_attributes.remove(me.color_attributes[0])
    attr = me.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
    for v in me.vertices:
        best, w = None, 0.0
        for g in v.groups:
            if g.weight > w:
                best, w = names[g.group], g.weight
        n = (best or "").lower()
        c = (0.0, 0.0, 0.0, 1.0)
        if n.startswith(TOP):
            c = (1.0, 0.0, 0.0, 1.0)
        elif n.startswith(BOTTOM):
            c = (0.0, 1.0, 0.0, 1.0)
        elif n.startswith(SHOES):
            c = (0.0, 0.0, 1.0, 1.0)
        attr.data[v.index].color = c
    me.color_attributes.active_color = attr
    me.color_attributes.render_color_index = 0


def bake(sex):
    clear()
    objs = imported(os.path.join(BODIES, "Superhero_%s_FullBody.gltf" % sex))
    arm = next(o for o in objs if o.type == 'ARMATURE')
    for o in objs:
        if o.type == 'MESH' and o.name.startswith("Icosphere"):
            bpy.data.objects.remove(o)
    body = max((o for o in bpy.data.objects if o.type == 'MESH'), key=lambda o: len(o.data.polygons))
    body.name = "Body"
    mask(body)
    # Hairstyles: re-parent each onto our armature, drop their own.
    for fn in sorted(os.path.join(HAIR, n) for n in os.listdir(HAIR) if n.startswith("Hair_") and n.endswith(".gltf")):
        new = imported(fn)
        for o in new:
            if o.type == 'MESH':
                o.name = os.path.basename(fn)[:-5]
                mw = o.matrix_world.copy()
                o.parent = arm
                o.matrix_world = mw
                for m in o.modifiers:
                    if m.type == 'ARMATURE':
                        m.object = arm
        for o in new:
            if o.type in ('ARMATURE', 'EMPTY'):
                bpy.data.objects.remove(o)
    # Animations: import the library, keep the actions we use, as NLA tracks.
    lib = imported(UAL)
    for o in lib:
        bpy.data.objects.remove(o)
    arm.animation_data_create()
    for src, dst in ANIMS.items():
        act = bpy.data.actions.get(src)
        if act is None:
            print("MISSING", src)
            continue
        act.name = dst
        tr = arm.animation_data.nla_tracks.new()
        tr.name = dst
        st = tr.strips.new(dst, int(act.frame_range[0]), act)
        if hasattr(st, "action_slot") and act.slots:
            st.action_slot = act.slots[0]
    arm.animation_data.action = None
    zs = [(body.matrix_world @ v.co).z for v in body.data.vertices]
    print("HEIGHT", sex, round(min(zs), 3), round(max(zs), 3))
    for img in bpy.data.images:   # 4K maps are wasted on a figure 20m away
        if img.size[0] > 1024:
            img.scale(1024, 1024)
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "person_%s.glb" % sex.lower()),
        export_format='GLB', export_animation_mode='NLA_TRACKS', export_vertex_color='ACTIVE', export_image_format='JPEG', export_jpeg_quality=88,
        export_all_vertex_colors=False)


for sex in ("Male", "Female"):
    bake(sex)
