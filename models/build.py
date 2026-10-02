"""Graybox Protocol model pack builder — run inside Blender 4.2 background mode.

Usage:
    blender -b -P build.py -- <target>
Targets: fp_arm | civ_01..civ_10 | guard_enforcer | guard_warden | guard_reaper
         | rotorcraft | secret_room | all_glb

Conventions:
  - Units in meters. Characters face +Y (Blender) -> -Z forward in Godot.
  - FP viewmodel: built with barrel along +Y, then root rotated -90 deg about X
    so the barrel points along -Z (camera-forward in Godot), up = +Y.
  - Flat-shaded low-poly style to match the game's graybox aesthetic.
"""
import bpy
import math
import mathutils
import os
import sys

# ----------------------------------------------------------------------------
# paths
# ----------------------------------------------------------------------------
HERE = os.path.dirname(os.path.abspath(__file__))
GLB_DIR = os.path.join(HERE, "glb")
BLEND_DIR = os.path.join(HERE, "blend")
PREVIEW_DIR = os.path.join(HERE, "previews")
for d in (GLB_DIR, BLEND_DIR, PREVIEW_DIR):
    os.makedirs(d, exist_ok=True)

# ----------------------------------------------------------------------------
# scene helpers
# ----------------------------------------------------------------------------
def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # purge orphan data so repeated runs stay clean
    for coll in (bpy.data.meshes, bpy.data.materials):
        for x in list(coll):
            if x.users == 0:
                coll.remove(x)


def mat(name, rgb, rough=0.85, metallic=0.0, emission=None, emission_strength=0.0):
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        bsdf = m.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metallic
        if emission is not None:
            bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
            bsdf.inputs["Emission Strength"].default_value = emission_strength
    return m


def _finish(obj, material, shade_flat=True):
    if material is not None:
        if len(obj.data.materials) == 0:
            obj.data.materials.append(material)
        else:
            obj.data.materials[0] = material
    if shade_flat:
        for p in obj.data.polygons:
            p.use_smooth = False
    bpy.ops.object.select_all(action="DESELECT")
    return obj


def box(name, sx, sy, sz, loc=(0, 0, 0), material=None, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _finish(o, material)


def cyl(name, r, h, loc=(0, 0, 0), material=None, verts=12, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts, radius=r, depth=h, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    return _finish(o, material)


def sphere(name, r, loc=(0, 0, 0), material=None, seg=12, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=seg, ring_count=rings, radius=r, location=loc)
    o = bpy.context.active_object
    o.name = name
    return _finish(o, material)


def cone(name, r, h, loc=(0, 0, 0), material=None, verts=10):
    bpy.ops.mesh.primitive_cone_add(
        vertices=verts, radius1=r, depth=h, location=loc)
    o = bpy.context.active_object
    o.name = name
    return _finish(o, material)


def parent(child, new_parent):
    child.parent = new_parent
    child.matrix_parent_inverse = new_parent.matrix_world.inverted()


# ----------------------------------------------------------------------------
# palette
# ----------------------------------------------------------------------------
SKIN_TONES = [
    (0.98, 0.80, 0.64),  # pale
    (0.93, 0.70, 0.53),  # tan
    (0.72, 0.50, 0.35),  # brown
    (0.48, 0.33, 0.24),  # deep brown
    (0.85, 0.62, 0.47),  # olive-tan
]
SHIRT_COLORS = [
    (0.75, 0.78, 0.82), (0.20, 0.35, 0.65), (0.70, 0.25, 0.22),
    (0.25, 0.55, 0.30), (0.85, 0.65, 0.20), (0.45, 0.25, 0.55),
    (0.90, 0.90, 0.88), (0.30, 0.30, 0.34), (0.15, 0.55, 0.60),
    (0.75, 0.45, 0.70),
]
PANTS_COLORS = [
    (0.25, 0.28, 0.35), (0.45, 0.38, 0.30), (0.20, 0.20, 0.22),
    (0.55, 0.55, 0.58), (0.35, 0.30, 0.25),
]
HAIR_COLORS = [
    (0.12, 0.10, 0.09), (0.35, 0.22, 0.12), (0.70, 0.55, 0.35),
    (0.75, 0.75, 0.78), (0.55, 0.20, 0.12),
]

# ----------------------------------------------------------------------------
# humanoid builder — relaxed standing pose, faces +Y, feet at z=0
# ----------------------------------------------------------------------------
def build_humanoid(name, cfg):
    """cfg keys: skin, shirt, pants, hair_style, hair_color, shoes,
    height (scale), torso_w, shoulder_pads, helmet, visor, coat,
    hood, backpack, hat, emissive_accent. Returns root Empty."""
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)

    H = cfg.get("height", 1.0)
    tw = cfg.get("torso_w", 0.42)          # torso width
    skin = mat(name + "_skin", cfg["skin"], rough=0.7)
    shirt = mat(name + "_shirt", cfg["shirt"])
    pants = mat(name + "_pants", cfg["pants"])
    hairm = mat(name + "_hair", cfg.get("hair_color", (0.12, 0.10, 0.09)), rough=0.95)
    shoem = mat(name + "_shoes", cfg.get("shoes", (0.15, 0.14, 0.13)))

    leg_h = 0.80 * H
    torso_h = 0.58 * H
    hip_z = leg_h
    sho_z = hip_z + torso_h
    head_s = 0.23 * H

    # legs + shoes
    for sx in (-1, 1):
        x = sx * 0.11 * H
        leg = box(f"{name}_leg_{'L' if sx < 0 else 'R'}", 0.15 * H, 0.17 * H,
                  leg_h - 0.09, (x, 0, (leg_h - 0.09) / 2 + 0.09), pants)
        parent(leg, root)
        shoe = box(f"{name}_shoe_{'L' if sx < 0 else 'R'}", 0.16 * H, 0.30 * H,
                   0.09, (x, 0.05 * H, 0.045), shoem)
        parent(shoe, root)
    # pelvis
    pelvis = box(f"{name}_pelvis", tw * 0.92, 0.24 * H, 0.20 * H,
                 (0, 0, hip_z + 0.02), pants)
    parent(pelvis, root)
    # torso
    torso = box(f"{name}_torso", tw, 0.26 * H, torso_h, (0, 0, sho_z - torso_h / 2), shirt)
    parent(torso, root)
    # arms (slightly out, hands at sides)
    for sx in (-1, 1):
        x = sx * (tw / 2 + 0.075 * H)
        arm = box(f"{name}_arm_{'L' if sx < 0 else 'R'}", 0.13 * H, 0.14 * H,
                  0.62 * H, (x, 0, sho_z - 0.36 * H), shirt)
        arm.rotation_euler = (0, sx * -0.09, 0)
        parent(arm, root)
        hand = box(f"{name}_hand_{'L' if sx < 0 else 'R'}", 0.11 * H, 0.12 * H,
                   0.14 * H, (x + sx * 0.03 * H, 0, sho_z - 0.72 * H), skin)
        parent(hand, root)
    # neck + head
    neck = cyl(f"{name}_neck", 0.06 * H, 0.08 * H, (0, 0, sho_z + 0.02), skin)
    parent(neck, root)
    head = box(f"{name}_head", head_s, head_s * 0.95, head_s,
               (0, 0.01 * H, sho_z + 0.06 * H + head_s / 2), skin)
    parent(head, root)
    head_z = sho_z + 0.06 * H + head_s / 2

    # simple eyes (skipped when a visor covers the face)
    if not cfg.get("visor"):
        eyem = mat(name + "_eyes", (0.10, 0.09, 0.09), rough=0.6)
        for sx in (-1, 1):
            e = box(f"{name}_eye_{'L' if sx < 0 else 'R'}", 0.035 * H, 0.012,
                    0.045 * H, (sx * 0.058 * H, 0.01 * H + head_s * 0.475 + 0.004,
                                head_z + 0.015 * H), eyem)
            parent(e, root)

    hs = cfg.get("hair_style", "flat")
    hz = head_z + head_s / 2
    if hs == "flat":
        h = box(f"{name}_hair", head_s * 1.02, head_s * 0.97, 0.07 * H,
                (0, 0.0, hz + 0.015 * H), hairm)
        parent(h, root)
    elif hs == "long":
        h = box(f"{name}_hair", head_s * 1.04, head_s * 0.99, 0.16 * H,
                (0, -0.03 * H, hz - 0.03 * H), hairm)
        parent(h, root)
    elif hs == "bald":
        pass
    elif hs == "bun":
        box(f"{name}_hair", head_s * 1.02, head_s * 0.97, 0.06 * H,
            (0, 0, hz + 0.01 * H), hairm)
        b = sphere(f"{name}_bun", 0.06 * H, (0, -0.10 * H, hz + 0.03 * H), hairm)
        parent(b, root)
    elif hs == "cap":
        c = cyl(f"{name}_cap", head_s * 0.56, 0.07 * H, (0, 0, hz + 0.02 * H), hairm)
        parent(c, root)
        brim = box(f"{name}_brim", head_s * 0.9, 0.16 * H, 0.02,
                   (0, 0.14 * H, hz - 0.01 * H), hairm)
        parent(brim, root)
    elif hs == "hood":
        hd = cone(f"{name}_hood", head_s * 0.75, 0.22 * H,
                  (0, -0.02 * H, hz + 0.02 * H), cfg.get("hood_mat") or shirt)
        parent(hd, root)

    # ---- optional gear ----
    if cfg.get("shoulder_pads"):
        pm = mat(name + "_armor", cfg.get("armor_color", (0.22, 0.23, 0.26)),
                 rough=0.5, metallic=0.35)
        for sx in (-1, 1):
            p = box(f"{name}_pad_{'L' if sx < 0 else 'R'}", 0.20 * H, 0.22 * H,
                    0.12 * H, (sx * (tw / 2 + 0.10 * H), 0, sho_z - 0.05 * H), pm)
            parent(p, root)
        vest = box(f"{name}_vest", tw * 1.06, 0.30 * H, torso_h * 0.62,
                   (0, 0, sho_z - torso_h * 0.32), pm)
        parent(vest, root)
    if cfg.get("helmet"):
        hm = mat(name + "_helmet", cfg.get("helmet_color", (0.18, 0.19, 0.21)),
                 rough=0.45, metallic=0.3)
        helm = sphere(f"{name}_helmet", head_s * 0.62, (0, 0, head_z + 0.03 * H),
                      hm, seg=10, rings=6)
        helm.scale = (1.0, 1.0, 0.85)
        bpy.ops.object.select_all(action="DESELECT")
        helm.select_set(True)
        bpy.context.view_layer.objects.active = helm
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bpy.ops.object.select_all(action="DESELECT")
        parent(helm, root)
    if cfg.get("visor"):
        vm = mat(name + "_visor", (0.05, 0.05, 0.06), rough=0.2, metallic=0.6,
                 emission=cfg.get("visor_color", (1.0, 0.15, 0.1)),
                 emission_strength=2.5)
        v = box(f"{name}_visor", head_s * 0.8, 0.03, 0.09 * H,
                (0, head_s * 0.48, head_z + 0.01 * H), vm)
        parent(v, root)
    if cfg.get("coat"):
        cm = mat(name + "_coat", cfg.get("coat_color", (0.16, 0.16, 0.18)), rough=0.9)
        coat = box(f"{name}_coat", tw * 1.12, 0.32 * H, 0.85 * H,
                   (0, -0.01 * H, hip_z - 0.18 * H), cm)
        parent(coat, root)
    if cfg.get("backpack"):
        bm = mat(name + "_pack", cfg.get("pack_color", (0.4, 0.3, 0.2)))
        pk = box(f"{name}_pack", 0.30 * H, 0.16 * H, 0.38 * H,
                 (0, -0.22 * H, sho_z - 0.30 * H), bm)
        parent(pk, root)
    if cfg.get("hat"):
        tm = mat(name + "_hat", cfg.get("hat_color", (0.5, 0.4, 0.25)))
        br = cyl(f"{name}_hatbrim", head_s * 0.85, 0.025, (0, 0, hz + 0.05 * H), tm)
        parent(br, root)
        tp = cyl(f"{name}_hattop", head_s * 0.5, 0.12 * H, (0, 0, hz + 0.11 * H), tm)
        parent(tp, root)
    if cfg.get("emissive_accent"):
        em = mat(name + "_accent", (0.1, 0.1, 0.1),
                 emission=cfg["emissive_accent"], emission_strength=3.0)
        strip = box(f"{name}_accent", tw * 0.7, 0.02, 0.04 * H,
                    (0, 0.145 * H, sho_z - 0.18 * H), em)
        parent(strip, root)
    return root


# ----------------------------------------------------------------------------
# weapons — built pointing +Y (forward), grip down -Z
# ----------------------------------------------------------------------------
def make_pistol_suppressed(name, body_color=(0.35, 0.32, 0.55)):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    gunm = mat(name + "_gun", body_color, rough=0.4, metallic=0.65)
    darkm = mat(name + "_dark", (0.12, 0.12, 0.13), rough=0.5, metallic=0.4)
    slide = box(f"{name}_slide", 0.045, 0.24, 0.055, (0, 0.10, 0.02), gunm)
    parent(slide, root)
    frame = box(f"{name}_frame", 0.04, 0.16, 0.045, (0, 0.02, -0.005), darkm)
    parent(frame, root)
    grip = box(f"{name}_grip", 0.042, 0.06, 0.13, (0, -0.045, -0.075),
               darkm, rot=(0.25, 0, 0))
    parent(grip, root)
    supp = cyl(f"{name}_suppressor", 0.028, 0.16, (0, 0.30, 0.02), darkm,
               rot=(math.pi / 2, 0, 0))
    parent(supp, root)
    sight_f = box(f"{name}_sightF", 0.012, 0.012, 0.02, (0, 0.20, 0.055), darkm)
    parent(sight_f, root)
    sight_r = box(f"{name}_sightR", 0.03, 0.012, 0.02, (0, 0.005, 0.055), darkm)
    parent(sight_r, root)
    guard = box(f"{name}_triggerguard", 0.05, 0.07, 0.012, (0, 0.03, -0.045), darkm)
    parent(guard, root)
    return root


def make_shotgun(name):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    wm = mat(name + "_wood", (0.42, 0.26, 0.15), rough=0.7)
    sm = mat(name + "_steel", (0.16, 0.16, 0.17), rough=0.35, metallic=0.7)
    barrel = cyl(f"{name}_barrel", 0.028, 0.55, (0, 0.30, 0.02), sm,
                 rot=(math.pi / 2, 0, 0))
    parent(barrel, root)
    mag = cyl(f"{name}_magtube", 0.022, 0.45, (0, 0.26, -0.035), sm,
              rot=(math.pi / 2, 0, 0))
    parent(mag, root)
    pump = box(f"{name}_pump", 0.06, 0.12, 0.06, (0, 0.22, -0.03), wm)
    parent(pump, root)
    recv = box(f"{name}_receiver", 0.06, 0.28, 0.09, (0, -0.05, 0.0), sm)
    parent(recv, root)
    stock = box(f"{name}_stock", 0.055, 0.22, 0.12, (0, -0.28, -0.05), wm,
                rot=(0.35, 0, 0))
    parent(stock, root)
    grip = box(f"{name}_grip", 0.045, 0.06, 0.11, (0, -0.12, -0.08), wm,
               rot=(0.3, 0, 0))
    parent(grip, root)
    return root


def make_smg(name):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    sm = mat(name + "_steel", (0.14, 0.14, 0.15), rough=0.4, metallic=0.6)
    pm = mat(name + "_poly", (0.20, 0.20, 0.21), rough=0.8)
    body = box(f"{name}_body", 0.055, 0.34, 0.08, (0, 0.05, 0.01), sm)
    parent(body, root)
    barrel = cyl(f"{name}_barrel", 0.018, 0.16, (0, 0.30, 0.02), sm,
                 rot=(math.pi / 2, 0, 0))
    parent(barrel, root)
    mag = box(f"{name}_mag", 0.04, 0.05, 0.22, (0, 0.06, -0.12), pm,
              rot=(0.15, 0, 0))
    parent(mag, root)
    stock = box(f"{name}_stock", 0.04, 0.16, 0.05, (0, -0.20, 0.01), sm)
    parent(stock, root)
    grip = box(f"{name}_grip", 0.045, 0.05, 0.11, (0, -0.03, -0.08), pm,
               rot=(0.25, 0, 0))
    parent(grip, root)
    sight = box(f"{name}_sight", 0.02, 0.06, 0.035, (0, 0.10, 0.065), pm)
    parent(sight, root)
    return root


def make_rifle(name):
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    sm = mat(name + "_steel", (0.13, 0.13, 0.14), rough=0.35, metallic=0.7)
    pm = mat(name + "_poly", (0.25, 0.22, 0.18), rough=0.8)
    barrel = cyl(f"{name}_barrel", 0.016, 0.62, (0, 0.42, 0.02), sm,
                 rot=(math.pi / 2, 0, 0))
    parent(barrel, root)
    scope = cyl(f"{name}_scope", 0.028, 0.20, (0, 0.10, 0.085), sm,
                rot=(math.pi / 2, 0, 0))
    parent(scope, root)
    mount = box(f"{name}_mount", 0.02, 0.04, 0.045, (0, 0.10, 0.045), sm)
    parent(mount, root)
    body = box(f"{name}_body", 0.055, 0.40, 0.09, (0, -0.02, 0.0), sm)
    parent(body, root)
    stock = box(f"{name}_stock", 0.05, 0.24, 0.11, (0, -0.32, -0.03), pm,
                rot=(0.25, 0, 0))
    parent(stock, root)
    grip = box(f"{name}_grip", 0.045, 0.05, 0.11, (0, -0.10, -0.075), pm,
               rot=(0.3, 0, 0))
    parent(grip, root)
    bipod = box(f"{name}_bipod", 0.10, 0.03, 0.14, (0, 0.55, -0.06), sm)
    parent(bipod, root)
    return root

# ----------------------------------------------------------------------------
# FP arm + suppressed pistol (viewmodel). Built DIRECTLY in camera space:
# the camera sits at the origin looking along -Z (Godot convention), the
# barrel points -Z (away from the viewer). No rotation tricks — what you
# see in the preview is what the player sees. Parent the .glb root to the
# Godot camera as-is.
# ----------------------------------------------------------------------------
def build_fp_arm():
    clear_scene()
    root = bpy.data.objects.new("FP_ArmPistol", None)
    bpy.context.collection.objects.link(root)

    sleeve = mat("fp_sleeve", (0.30, 0.32, 0.36), rough=0.9)      # street clothes
    skin = mat("fp_skin", SKIN_TONES[1], rough=0.7)
    darkm = mat("fp_dark", (0.12, 0.12, 0.13), rough=0.5, metallic=0.4)

    fist_c = (0.15, -0.14, -0.44)
    # fist gripping the pistol grip
    fist = box("fist", 0.080, 0.095, 0.105, fist_c, skin, rot=(0.15, 0, -0.10))
    parent(fist, root)
    # trigger finger resting along the frame
    finger = box("trigger_finger", 0.024, 0.028, 0.085,
                 (0.175, -0.095, -0.435), skin, rot=(0.1, 0, 0))
    parent(finger, root)
    # thumb over the top of the grip
    thumb = box("thumb", 0.028, 0.030, 0.070,
                (0.115, -0.105, -0.410), skin, rot=(0.0, 0.5, 0.35))
    parent(thumb, root)

    # pistol: built with barrel along +Y, pitched to -Z (away), slight down-tilt
    pistol = make_pistol_suppressed("fp_pistol", body_color=(0.45, 0.38, 0.72))
    pistol.location = (0.15, -0.11, -0.43)
    pistol.rotation_euler = (-math.pi / 2 + 0.10, 0, 0)
    parent(pistol, root)

    # forearm: short stub from the fist toward the elbow (down-right-back),
    # kept behind the fist plane so it never looms into the lens
    elbow = mathutils.Vector((0.30, -0.30, -0.40))
    fist_v = mathutils.Vector(fist_c)
    axis = elbow - fist_v
    length = axis.length
    mid = (fist_v + elbow) / 2
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.045, depth=length,
                                        location=mid)
    fore = bpy.context.active_object
    fore.name = "forearm"
    fore.rotation_euler = axis.normalized().to_track_quat("Z", "Y").to_euler()
    _finish(fore, sleeve)
    parent(fore, root)
    # cuff at the wrist
    wrist = fist_v + axis.normalized() * 0.10
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.064, depth=0.055,
                                        location=wrist)
    cuff = bpy.context.active_object
    cuff.name = "cuff"
    cuff.rotation_euler = fore.rotation_euler
    _finish(cuff, mat("fp_cuff", (0.20, 0.21, 0.24), rough=0.9))
    parent(cuff, root)

    bpy.ops.object.select_all(action="DESELECT")
    return root


# ----------------------------------------------------------------------------
# civilian variants
# ----------------------------------------------------------------------------
CIV_VARIANTS = [
    dict(skin=0, shirt=0, pants=0, hair="flat",  hcol=0, extra={}),
    dict(skin=1, shirt=1, pants=2, hair="long",  hcol=1, extra={"backpack": True}),
    dict(skin=2, shirt=2, pants=0, hair="bald",  hcol=0, extra={}),
    dict(skin=3, shirt=3, pants=3, hair="cap",   hcol=0, extra={}),
    dict(skin=4, shirt=4, pants=1, hair="bun",   hcol=2, extra={"hat": False}),
    dict(skin=0, shirt=5, pants=2, hair="flat",  hcol=3, extra={"backpack": True,
          "pack_color": (0.55, 0.15, 0.15)}),
    dict(skin=1, shirt=6, pants=4, hair="long",  hcol=4, extra={"hat": True}),
    dict(skin=2, shirt=7, pants=0, hair="cap",   hcol=1, extra={}),
    dict(skin=3, shirt=8, pants=3, hair="flat",  hcol=0, extra={}),
    dict(skin=4, shirt=9, pants=1, hair="bun",   hcol=1, extra={"backpack": True,
          "pack_color": (0.2, 0.3, 0.5)}),
]


def build_civilian(idx):
    clear_scene()
    v = CIV_VARIANTS[idx - 1]
    cfg = dict(
        skin=SKIN_TONES[v["skin"]],
        shirt=SHIRT_COLORS[v["shirt"]],
        pants=PANTS_COLORS[v["pants"]],
        hair_style=v["hair"],
        hair_color=HAIR_COLORS[v["hcol"]],
        height=0.94 + (idx % 3) * 0.05,
        torso_w=0.40 + (idx % 2) * 0.04,
    )
    cfg.update(v["extra"])
    root = build_humanoid(f"civ_{idx:02d}", cfg)
    return root


# ----------------------------------------------------------------------------
# guards — intimidating, distinct silhouette + weapon each
# ----------------------------------------------------------------------------
def build_guard_enforcer():
    """Bulky riot armor, heavy shotgun."""
    clear_scene()
    cfg = dict(
        skin=SKIN_TONES[2], shirt=(0.25, 0.26, 0.28), pants=(0.20, 0.20, 0.22),
        hair_style="bald", height=1.06, torso_w=0.56,
        shoulder_pads=True, armor_color=(0.28, 0.29, 0.32),
        helmet=True, helmet_color=(0.22, 0.23, 0.25),
        visor=True, visor_color=(1.0, 0.55, 0.10),
        emissive_accent=(1.0, 0.45, 0.08),
    )
    root = build_humanoid("guard_enforcer", cfg)
    gun = make_shotgun("enforcer_shotgun")
    # held across the chest, barrel along +X
    gun.location = (0.02, 0.22, 1.30)
    gun.rotation_euler = (0, 0, -math.pi / 2 + 0.12)
    parent(gun, root)
    return root


def build_guard_warden():
    """Tall, long coat, peaked helmet, SMG."""
    clear_scene()
    cfg = dict(
        skin=SKIN_TONES[0], shirt=(0.18, 0.20, 0.24), pants=(0.16, 0.16, 0.18),
        hair_style="flat", hair_color=HAIR_COLORS[3], height=1.12, torso_w=0.44,
        coat=True, coat_color=(0.14, 0.15, 0.18),
        helmet=True, helmet_color=(0.30, 0.31, 0.34),
        visor=True, visor_color=(0.30, 0.85, 1.0),
        emissive_accent=(0.25, 0.75, 1.0),
    )
    root = build_humanoid("guard_warden", cfg)
    gun = make_smg("warden_smg")
    gun.location = (-0.02, 0.22, 1.34)
    gun.rotation_euler = (0, 0, math.pi / 2 - 0.15)
    parent(gun, root)
    return root


def build_guard_reaper():
    """Lean, hooded, red visor, long rifle."""
    clear_scene()
    cfg = dict(
        skin=SKIN_TONES[3], shirt=(0.16, 0.14, 0.14), pants=(0.14, 0.13, 0.13),
        hair_style="hood", height=1.02, torso_w=0.38,
        visor=True, visor_color=(1.0, 0.10, 0.10),
        emissive_accent=(1.0, 0.12, 0.12),
        shoes=(0.10, 0.10, 0.10),
    )
    # hood uses the shirt material slot via hood_mat override
    root = build_humanoid("guard_reaper", cfg)
    gun = make_rifle("reaper_rifle")
    gun.location = (0.02, 0.22, 1.42)
    gun.rotation_euler = (0, 0, -math.pi / 2 + 0.08)
    parent(gun, root)
    return root


# ----------------------------------------------------------------------------
# rotorcraft — single-person coaxial-rotor gunship. Not a helicopter:
# twin counter-rotating rotors on one mast, no tail rotor.
# ----------------------------------------------------------------------------
def build_rotorcraft():
    clear_scene()
    root = bpy.data.objects.new("rotorcraft", None)
    bpy.context.collection.objects.link(root)

    hullm = mat("rc_hull", (0.30, 0.32, 0.30), rough=0.5, metallic=0.45)
    darkm = mat("rc_dark", (0.14, 0.14, 0.15), rough=0.5, metallic=0.4)
    glassm = mat("rc_glass", (0.10, 0.16, 0.22), rough=0.1, metallic=0.9)
    accentm = mat("rc_accent", (0.08, 0.08, 0.08),
                  emission=(1.0, 0.25, 0.10), emission_strength=3.0)

    # fuselage: stretched, faceted hull
    hull = sphere("hull", 0.55, (0, 0, 1.05), hullm, seg=10, rings=7)
    hull.scale = (0.85, 1.7, 0.85)
    bpy.ops.object.select_all(action="DESELECT")
    hull.select_set(True)
    bpy.context.view_layer.objects.active = hull
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.select_all(action="DESELECT")
    parent(hull, root)
    # nose — apex points forward (+Y)
    nose = cone("nose", 0.38, 0.55, (0, 1.02, 1.0), hullm, verts=8)
    nose.rotation_euler = (-math.pi / 2, 0, 0)
    parent(nose, root)
    # bubble canopy
    canopy = sphere("canopy", 0.34, (0, 0.45, 1.30), glassm, seg=12, rings=8)
    canopy.scale = (0.9, 1.1, 0.75)
    bpy.ops.object.select_all(action="DESELECT")
    canopy.select_set(True)
    bpy.context.view_layer.objects.active = canopy
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.select_all(action="DESELECT")
    parent(canopy, root)
    # pilot seat hint
    seat = box("seat", 0.34, 0.10, 0.40, (0, 0.30, 1.12), darkm)
    parent(seat, root)
    # rotor mast
    mast = cyl("mast", 0.07, 0.55, (0, -0.10, 1.75), darkm)
    parent(mast, root)

    # coaxial rotors: two 2-blade rotors, counter-rotating
    rotors = []
    for i, z in enumerate((2.02, 2.14)):
        rg = bpy.data.objects.new(f"rotor_{i}", None)
        bpy.context.collection.objects.link(rg)
        rg.location = (0, -0.10, z)
        parent(rg, root)
        for b in range(2):
            blade = box(f"rotor{i}_blade{b}", 3.4, 0.16, 0.03,
                        (0, -0.10, z), darkm, rot=(0, 0, b * math.pi / 2))
            # re-parent blade under rotor group keeping world transform
            parent(blade, rg)
            tipm = accentm if b == 0 else darkm
            tip = box(f"rotor{i}_tip{b}", 0.18, 0.17, 0.032,
                      (1.62 if b % 2 == 0 else -1.62, -0.10, z), tipm)
            parent(tip, rg)
        rotors.append(rg)
    # tail boom + fins (styling, no tail rotor — it's coaxial)
    boom = cyl("boom", 0.09, 1.5, (0, -1.55, 1.15), hullm,
               rot=(math.pi / 2 - 0.12, 0, 0))
    parent(boom, root)
    fin_v = box("fin_v", 0.05, 0.35, 0.55, (0, -2.25, 1.45), darkm,
                rot=(0.15, 0, 0))
    parent(fin_v, root)
    fin_h = box("fin_h", 0.55, 0.35, 0.05, (0, -2.20, 1.25), darkm)
    parent(fin_h, root)
    # gun pods under fuselage
    for sx in (-1, 1):
        pod = cyl(f"gunpod_{'L' if sx < 0 else 'R'}", 0.11, 0.55,
                  (sx * 0.42, 0.55, 0.62), darkm, rot=(math.pi / 2, 0, 0))
        parent(pod, root)
        barrel = cyl(f"gunbarrel_{'L' if sx < 0 else 'R'}", 0.035, 0.45,
                     (sx * 0.42, 1.05, 0.62), darkm, rot=(math.pi / 2, 0, 0))
        parent(barrel, root)
        muzzle = mat("rc_muzzle", (0.1, 0.1, 0.1),
                     emission=(1.0, 0.5, 0.1), emission_strength=2.0)
        mg = cyl(f"muzzle_{'L' if sx < 0 else 'R'}", 0.045, 0.06,
                 (sx * 0.42, 1.28, 0.62), muzzle, rot=(math.pi / 2, 0, 0))
        parent(mg, root)
    # landing skids
    for sx in (-1, 1):
        skid = cyl(f"skid_{'L' if sx < 0 else 'R'}", 0.035, 1.9,
                   (sx * 0.55, 0.1, 0.10), darkm, rot=(math.pi / 2, 0, 0))
        parent(skid, root)
        for sy in (-0.6, 0.7):
            strut = cyl(f"strut_{sx}_{sy}", 0.03, 0.55,
                        (sx * 0.45, sy, 0.38), darkm, rot=(0, 0, sx * 0.35))
            parent(strut, root)
    # running lights
    for sx, col in ((-1, (1.0, 0.1, 0.1)), (1, (0.1, 1.0, 0.2))):
        lm = mat(f"rc_light_{sx}", (0.1, 0.1, 0.1),
                 emission=col, emission_strength=4.0)
        l = sphere(f"navlight_{sx}", 0.05, (sx * 0.50, 0.9, 1.05), lm)
        parent(l, root)
    # glowing side stripes
    for sx in (-1, 1):
        strip = box(f"stripe_{sx}", 0.03, 1.10, 0.06, (sx * 0.44, 0.0, 0.98),
                    accentm)
        parent(strip, root)

    # spin animation: 24-frame loop, counter-rotating
    scn = bpy.context.scene
    scn.render.fps = 24
    scn.frame_start = 1
    scn.frame_end = 24
    for i, rg in enumerate(rotors):
        direction = 1 if i == 0 else -1
        for f, ang in ((1, 0), (24, direction * 2 * math.pi)):
            scn.frame_set(f)
            rg.rotation_euler = (0, 0, ang)
            rg.keyframe_insert(data_path="rotation_euler", frame=f)
        for fc in rg.animation_data.action.fcurves:
            for kp in fc.keyframe_points:
                kp.interpolation = "LINEAR"
            mod = fc.modifiers.new(type="CYCLES")
            mod.mode_before = "REPEAT"
            mod.mode_after = "REPEAT"
    scn.frame_set(1)
    return root

# ----------------------------------------------------------------------------
# secret room — hidden safehouse interior, graybox-compatible dressing.
# 7m x 6m x 3.2m. Saved as secret_room.blend (editable), preview rendered.
# ----------------------------------------------------------------------------
def build_secret_room():
    clear_scene()
    scn = bpy.context.scene
    scn.render.fps = 24

    conc = mat("rm_concrete", (0.42, 0.42, 0.44), rough=0.95)
    conc_dark = mat("rm_concrete_dark", (0.30, 0.30, 0.32), rough=0.95)
    floorm = mat("rm_floor", (0.35, 0.35, 0.37), rough=0.9)
    woodm = mat("rm_wood", (0.45, 0.30, 0.18), rough=0.8)
    metalm = mat("rm_metal", (0.25, 0.26, 0.28), rough=0.45, metallic=0.6)
    rugm = mat("rm_rug", (0.55, 0.18, 0.15), rough=1.0)
    paperm = mat("rm_paper", (0.88, 0.86, 0.78), rough=0.9)
    screenm = mat("rm_screen", (0.05, 0.08, 0.10),
                  emission=(0.35, 0.75, 0.90), emission_strength=1.6)
    screenm2 = mat("rm_screen2", (0.05, 0.08, 0.10),
                   emission=(0.90, 0.45, 0.20), emission_strength=1.4)
    redm = mat("rm_redlight", (0.2, 0.05, 0.05),
               emission=(1.0, 0.10, 0.08), emission_strength=5.0)
    boxm = mat("rm_crate", (0.55, 0.42, 0.28), rough=0.9)
    bookm = mat("rm_books", (0.30, 0.22, 0.16), rough=0.9)

    W, D, H = 7.0, 6.0, 3.2
    # floor / ceiling / walls
    box("floor", W, D, 0.1, (0, 0, -0.05), floorm)
    box("ceiling", W, D, 0.1, (0, 0, H + 0.05), conc_dark)
    box("wall_N", W, 0.15, H, (0, D / 2, H / 2), conc)
    box("wall_S", W, 0.15, H, (0, -D / 2, H / 2), conc)
    box("wall_E", 0.15, D, H, (W / 2, 0, H / 2), conc)
    box("wall_W", 0.15, D, H, (-W / 2, 0, H / 2), conc)
    # support pillars
    for px, py in ((-W / 2 + 0.4, -D / 2 + 0.4), (W / 2 - 0.4, -D / 2 + 0.4)):
        box(f"pillar_{px}", 0.35, 0.35, H, (px, py, H / 2), conc_dark)
    # rug
    box("rug", 3.0, 2.2, 0.02, (0.3, 0.2, 0.01), rugm)

    # --- desk station (north wall) ---
    desk = box("desk", 2.6, 0.9, 0.08, (0, D / 2 - 0.75, 0.78), woodm)
    for sx in (-1, 1):
        box(f"desk_leg_{sx}", 0.08, 0.8, 0.74,
            (sx * 1.2, D / 2 - 0.75, 0.37), metalm)
    for i, (mx, smat) in enumerate(((-0.85, screenm), (0, screenm2), (0.85, screenm))):
        mon = box(f"monitor_{i}", 0.85, 0.06, 0.55, (mx, D / 2 - 0.72, 1.25), metalm)
        scr = box(f"screen_{i}", 0.78, 0.02, 0.48, (mx, D / 2 - 0.76, 1.25), smat)
        box(f"monstand_{i}", 0.08, 0.08, 0.35, (mx, D / 2 - 0.70, 0.99), metalm)
    kb = box("keyboard", 0.5, 0.18, 0.03, (0, D / 2 - 1.05, 0.83), metalm)
    # papers + mug on desk
    box("papers", 0.35, 0.28, 0.02, (1.05, D / 2 - 0.85, 0.83), paperm,
        rot=(0, 0, 0.3))
    cyl("mug", 0.045, 0.10, (1.15, D / 2 - 1.10, 0.87),
        mat("rm_mug", (0.70, 0.20, 0.15)))
    # office chair
    chairm = mat("rm_chair", (0.18, 0.18, 0.20), rough=0.85)
    box("chair_seat", 0.55, 0.55, 0.09, (0, D / 2 - 1.75, 0.52), chairm)
    box("chair_back", 0.55, 0.09, 0.65, (0, D / 2 - 2.0, 0.95), chairm,
        rot=(0.12, 0, 0))
    cyl("chair_post", 0.04, 0.48, (0, D / 2 - 1.75, 0.26), metalm)
    # desk lamp (cool light)
    cyl("lamp_arm", 0.025, 0.55, (-1.05, D / 2 - 0.70, 1.10), metalm,
        rot=(0.5, 0, 0.3))
    lampm = mat("rm_lamp", (0.2, 0.2, 0.2), emission=(0.75, 0.85, 1.0),
                emission_strength=4.0)
    sphere("lamp_head", 0.07, (-1.18, D / 2 - 0.85, 1.32), lampm)

    # --- weapon rack (east wall) ---
    rack = box("gunrack", 0.12, 2.2, 1.1, (W / 2 - 0.25, -0.5, 1.55), woodm)
    rack_gunm = mat("rm_rackgun", (0.15, 0.15, 0.16), rough=0.5, metallic=0.5)
    for i, gy in enumerate((-1.15, -0.5, 0.15)):
        box(f"rackgun_{i}_body", 0.08, 0.85, 0.10,
            (W / 2 - 0.38, gy, 1.62), rack_gunm)
        box(f"rackgun_{i}_barrel", 0.05, 0.45, 0.05,
            (W / 2 - 0.38, gy + 0.60, 1.62), rack_gunm)
        box(f"rackgun_{i}_stock", 0.07, 0.28, 0.12,
            (W / 2 - 0.38, gy - 0.52, 1.58), rack_gunm, rot=(0.3, 0, 0))
    # ammo crates below
    box("ammo_crate1", 0.5, 0.5, 0.35, (W / 2 - 0.55, -1.6, 0.175), boxm)
    box("ammo_crate2", 0.45, 0.45, 0.30, (W / 2 - 0.50, -1.05, 0.15), boxm,
        rot=(0, 0, 0.2))

    # --- safe (west wall) ---
    safem = mat("rm_safe", (0.22, 0.24, 0.26), rough=0.4, metallic=0.7)
    box("safe", 0.7, 0.9, 1.1, (-W / 2 + 0.55, 1.2, 0.55), safem)
    cyl("safe_dial", 0.09, 0.06, (-W / 2 + 0.95, 1.2, 0.70), metalm,
        rot=(0, math.pi / 2, 0))
    box("safe_handle", 0.06, 0.20, 0.05, (-W / 2 + 0.95, 1.2, 0.45), metalm)

    # --- shelf with crates/boxes (south-west) ---
    for si in range(3):
        box(f"shelf_{si}", 1.8, 0.45, 0.06, (-2.2, -D / 2 + 0.45, 0.5 + si * 0.55),
            woodm)
    box("crate_a", 0.5, 0.35, 0.35, (-2.6, -D / 2 + 0.45, 0.70), boxm)
    box("crate_b", 0.4, 0.35, 0.30, (-1.9, -D / 2 + 0.45, 0.68), boxm,
        rot=(0, 0, 0.15))
    box("crate_c", 0.55, 0.38, 0.40, (-2.3, -D / 2 + 0.45, 1.28), boxm)
    cyl("barrel_a", 0.22, 0.65, (-1.4, -D / 2 + 0.70, 0.325),
        mat("rm_barrel", (0.30, 0.32, 0.35), rough=0.6, metallic=0.4))

    # --- hidden bookcase door (south wall, slightly ajar) ---
    bc = box("bookcase", 1.6, 0.35, 2.2, (1.8, -D / 2 + 0.35, 1.1), woodm,
             rot=(0, 0, 0.18))
    for bi in range(3):
        box(f"books_{bi}", 1.3, 0.22, 0.28,
            (1.8 - 0.16 * bi * 0.18, -D / 2 + 0.38 + bi * 0.05, 0.65 + bi * 0.5),
            bookm, rot=(0, 0, 0.18))
    # dark gap behind the ajar bookcase = the hidden passage
    gapm = mat("rm_gap", (0.02, 0.02, 0.03), rough=1.0)
    box("hidden_gap", 1.1, 0.5, 2.1, (2.35, -D / 2 - 0.05, 1.05), gapm,
        rot=(0, 0, 0.18))

    # --- evidence board (west wall) ---
    boardm = mat("rm_cork", (0.60, 0.45, 0.30), rough=0.95)
    box("evidence_board", 0.06, 1.8, 1.2, (-W / 2 + 0.20, -0.8, 1.70), boardm)
    for pi, (py, pz) in enumerate(((-1.3, 1.9), (-0.8, 1.65), (-0.3, 1.9))):
        box(f"photo_{pi}", 0.02, 0.22, 0.28,
            (-W / 2 + 0.25, py, pz), paperm, rot=(0, 0, 0.1 * pi))

    # --- lights ---
    # cool ceiling panels
    for lx in (-1.5, 1.5):
        pm = mat(f"rm_panel_{lx}", (0.9, 0.9, 0.9),
                 emission=(0.85, 0.90, 1.0), emission_strength=2.2)
        box(f"ceiling_panel_{lx}", 1.2, 0.6, 0.05, (lx, 0, H - 0.03), pm)
    # red emergency lamp in corner
    sphere("emergency_lamp", 0.09, (W / 2 - 0.5, D / 2 - 0.5, H - 0.25), redm)
    bpy.ops.object.light_add(type="POINT", location=(W / 2 - 0.5, D / 2 - 0.5, H - 0.5))
    rl = bpy.context.active_object
    rl.name = "emergency_light"
    rl.data.energy = 60
    rl.data.color = (1.0, 0.12, 0.08)
    # soft fill
    bpy.ops.object.light_add(type="POINT", location=(0, 0, H - 0.4))
    fl = bpy.context.active_object
    fl.name = "fill_light"
    fl.data.energy = 120
    fl.data.color = (0.75, 0.82, 1.0)

    # --- camera (inside the room, SW corner looking NE at the desk) ---
    bpy.ops.object.camera_add(location=(-2.9, -2.4, 2.3))
    cam = bpy.context.active_object
    cam.name = "room_camera"
    cam.data.lens = 24  # wide enough to take in the whole room
    # aim at room center
    d = mathutils.Vector((0.4, 0.7, 0.9)) - cam.location
    quat = d.to_track_quat("-Z", "Y")
    cam.rotation_euler = quat.to_euler()
    scn.camera = cam
    return None


# ----------------------------------------------------------------------------
# export + preview
# ----------------------------------------------------------------------------
def export_glb(name):
    bpy.context.view_layer.update()
    path = os.path.join(GLB_DIR, name + ".glb")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True,
        export_yup=True, export_animations=True,
        export_materials="EXPORT")
    bpy.ops.object.select_all(action="DESELECT")
    print("exported", path)


def save_blend(name):
    path = os.path.join(BLEND_DIR, name + ".blend")
    bpy.ops.wm.save_as_mainfile(filepath=path)
    print("saved", path)


def aim_camera_no_roll(cam, pos, target):
    """Point cam at target with a guaranteed upright horizon (no 180 flips)."""
    z = (mathutils.Vector(pos) - mathutils.Vector(target)).normalized()
    x = mathutils.Vector((0, 1, 0)).cross(z).normalized()
    if x.length < 1e-6:  # looking straight along Y; fall back to X-up
        x = mathutils.Vector((1, 0, 0)).cross(z).normalized()
    y = z.cross(x).normalized()
    m = mathutils.Matrix((x, y, z)).transposed().to_4x4()
    m.translation = mathutils.Vector(pos)
    cam.matrix_world = m


def render_preview(name, dist=4.2, height=2.2, angle=0.7):
    bpy.context.view_layer.update()
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 24
    scn.cycles.use_denoising = True
    scn.render.resolution_x = 512
    scn.render.resolution_y = 512
    scn.render.resolution_percentage = 100
    scn.render.film_transparent = True
    scn.render.image_settings.file_format = "PNG"
    if name == "fp_arm":
        # Product-shot preview: 3/4 view showing the full assembly clearly.
        # (The .glb itself is camera-ready: origin at the lens, barrel -Z.
        # Parent it to the Godot camera as-is.)
        bpy.ops.object.camera_add(location=(0.72, 0.52, 0.12))
        cam = bpy.context.active_object
        bpy.context.view_layer.update()
        aim_camera_no_roll(cam, (0.72, 0.52, 0.12), (0.18, -0.13, -0.52))
        cam.data.lens = 40
        scn.camera = cam
        bpy.ops.object.light_add(type="SUN", location=(2, 3, 4))
        bkey = bpy.context.active_object
        bkey.data.energy = 2.5
        scn.render.filepath = os.path.join(PREVIEW_DIR, name + ".png")
        bpy.ops.render.render(write_still=True)
        print("preview", scn.render.filepath)
        return
    # 3/4 front view camera (characters face +Y)
    bpy.ops.object.camera_add(
        location=(dist * math.sin(angle), dist * math.cos(angle), height))
    cam = bpy.context.active_object
    d = mathutils.Vector((0, 0, 1.0)) - cam.location
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    scn.camera = cam
    # key + fill sun
    bpy.ops.object.light_add(type="SUN", location=(4, 3, 6))
    sun = bpy.context.active_object
    sun.data.energy = 3.0
    bpy.ops.object.light_add(type="SUN", location=(-4, 2, 3))
    fill = bpy.context.active_object
    fill.data.energy = 1.0
    scn.render.filepath = os.path.join(PREVIEW_DIR, name + ".png")
    bpy.ops.render.render(write_still=True)
    print("preview", scn.render.filepath)


def render_room_preview():
    import mathutils  # noqa: F401  (already imported in build fn scope guard)
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 32
    scn.cycles.use_denoising = True
    scn.render.resolution_x = 960
    scn.render.resolution_y = 600
    scn.render.film_transparent = False
    scn.render.image_settings.file_format = "PNG"
    scn.render.filepath = os.path.join(PREVIEW_DIR, "secret_room.png")
    bpy.ops.render.render(write_still=True)
    print("preview", scn.render.filepath)


BUILDERS = {
    "fp_arm": build_fp_arm,
    "guard_enforcer": build_guard_enforcer,
    "guard_warden": build_guard_warden,
    "guard_reaper": build_guard_reaper,
    "rotorcraft": build_rotorcraft,
    "secret_room": build_secret_room,
}
for i in range(1, 11):
    BUILDERS[f"civ_{i:02d}"] = (lambda i=i: build_civilian(i))


def main():
    import mathutils  # ensure available for camera aiming helpers
    argv = sys.argv
    target = argv[argv.index("--") + 1] if "--" in argv else "all_glb"
    blender = os.path.join(
        os.path.expanduser("~"), ".tools", "blender",
        "blender-4.2.0-linux-x64", "blender")
    _ = blender  # not needed; we are already inside blender

    if target == "all_glb":
        targets = [t for t in BUILDERS if t != "secret_room"]
    else:
        targets = [target]
    for t in targets:
        BUILDERS[t]()
        if t == "secret_room":
            save_path = os.path.join(HERE, "secret_room.blend")
            bpy.ops.wm.save_as_mainfile(filepath=save_path)
            render_room_preview()
            print("saved", save_path)
        else:
            save_blend(t)
            export_glb(t)
            render_preview(t)
    print("done:", targets)


if __name__ == "__main__":
    main()
