## Source of assets/viewmodel/viewmodel_pistol.glb. Needs WRAD ARMS (arms.blend,
## CC0, wriks.itch.io/wrad-arms) and Kenney Blaster Kit 2.1; set K and SCR below.
## The finger bones curl toward the palm on NEGATIVE X — positive bends them
## backwards, which was the "mangled hand" in the first two fits.
## Exported with:
##   blender -b arms.blend --python viewmodel_fit.py -- sy=2.05 sz=-3.44 gx=2.38 gy=6.75
##     gz=-2.19 yaw=22 cant=12 slide=-0.12 tc=45 t1z=-35 pz=-3 px=2 tilt=14 idx=0.8
##     export=/path/viewmodel_pistol.glb
## grip.txt then holds GRIP / SIGHT_* / GUN_UP for viewmodel.gd.
## Viewmodel fit, hand-first. Run: blender -b arms.blend --python fit.py -- k=v ...
## 1. Curl the right hand into a fist (rest wrist pose).
## 2. Find the fist's hole: circle fit of the curled finger joints, axis = knuckle line.
## 3. Put the blaster's black grip through the hole, backstrap in the thumb web.
## 4. Move the wrist (IK) so the gun sits where we want it in view, barrel at the
##    converge point, canted by `cant`.
## 5. Render the view through a 55 deg camera at the eye, plus side shots.
import bpy, math, sys
from mathutils import Vector, Matrix
SCR = "/tmp/claude-1000/-home-gregory-milligan-AI-projects-concerned-citizen/a37f5ad1-3d5b-4f5d-a6ae-53de647392b0/scratchpad/"
K = "/tmp/claude-1000/-home-gregory-milligan-AI-projects-concerned-citizen/e3fa8a9f-563c-4c76-abdc-ab2b2747e3d2/scratchpad/kenney/kenney_blaster-kit_2.1/Models/GLB format/"
P = dict(x.split('=') for x in sys.argv[sys.argv.index('--') + 1:]) if '--' in sys.argv else {}
f = lambda k, d: float(P.get(k, d))
TAG = P.get('tag', 'f')
open(SCR + 'fit.txt', 'w').close()
def print(*x):
    open(SCR + 'fit.txt', 'a').write(' '.join(map(str, x)) + '\n')
CAM = Vector((0, 0, 1.5))
GS = f('gs', 3.0)

a = bpy.data.objects['arms']
pb = a.pose.bones
pb['shoulder.l'].scale = (0.001, 0.001, 0.001)
# shoulder offset from the eye: lower and further back makes the forearm rise into view
a.location = (f('sx', 0), f('sy', 0), f('sz', 0))

def upd():
    bpy.context.view_layer.update()

def wm(n):
    return a.matrix_world @ pb[n].matrix

def head(n):
    return wm(n).translation.copy()

def tip(n):
    return wm(n) @ Vector((0, pb[n].bone.length, 0))

# ---- 1. fist ---------------------------------------------------------------
CURL = [f('c1', 62), f('c2', 85), f('c3', 60)]
for fn in ['index', 'middle', 'ring', 'pinky']:
    for i in (1, 2, 3):
        ang = CURL[i - 1]
        if fn == 'index':
            ang *= f('idx', 0.55)
        if fn == 'pinky':
            ang *= f('pk', 1.08)
        b = pb['finger_%s%d.r' % (fn, i)]
        b.rotation_mode = 'XYZ'
        b.rotation_euler = (-math.radians(ang), 0, math.radians(f('splay', 0)) * (i == 1))   # negative X curls toward the palm
b = pb['finger_thumb1.r']; b.rotation_mode = 'XYZ'
b.rotation_euler = (math.radians(f('t1x', 0)), math.radians(f('t1y', 0)), math.radians(f('t1z', 0)))
for i in (2, 3):
    b = pb['finger_thumb%d.r' % i]; b.rotation_mode = 'XYZ'
    b.rotation_euler = (-math.radians(f('tc', 30)), 0, 0)
upd()

# ---- 2. hole, in wrist space (the hand is rigid w.r.t. the wrist from here) --
Wr = wm('wrist.r'); Wi = Wr.inverted()
fingers = ['middle', 'ring', 'pinky'] + (['index'] if P.get('useidx') else [])
pts = []
for fn in fingers:
    pts += [head('finger_%s2.r' % fn), head('finger_%s3.r' % fn), tip('finger_%s3.r' % fn)]
ax = (head('finger_index1.r') - head('finger_pinky1.r')).normalized()   # pinky -> index = grip up
# circle fit (Kasa) in the plane normal to ax
e1 = ax.orthogonal().normalized(); e2 = ax.cross(e1)
o = sum(pts, Vector()) / len(pts)
import itertools
A = []; B = []
for p in pts:
    d = p - o; x, y = d.dot(e1), d.dot(e2)
    A.append((x, y, 1.0)); B.append(x * x + y * y)
# normal equations 3x3
M = Matrix(((0,) * 3,) * 3); r = Vector((0, 0, 0))
for (x, y, w), bb in zip(A, B):
    v = Vector((x, y, w))
    for i in range(3):
        for j in range(3):
            M[i][j] += v[i] * v[j]
        r[i] += v[i] * bb
sol = M.inverted() @ r
cx, cy = sol[0] / 2, sol[1] / 2
rad = math.sqrt(max(1e-6, sol[2] + cx * cx + cy * cy))
hole = o + e1 * cx + e2 * cy
web = (head('finger_thumb1.r') + head('finger_index1.r')) * 0.5
rear = web - hole; rear = (rear - ax * ax.dot(rear)).normalized()
print("HOLE r=%.3f" % rad)

# ---- 3. gun into the hole ------------------------------------------------------
before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=K + "blaster-a.glb")
bpy.ops.import_scene.gltf(filepath=K + "silencer-small.glb")
new = [ob for ob in bpy.data.objects if ob not in before]
gun = bpy.data.objects.new('gun', None); bpy.context.scene.collection.objects.link(gun)
for ob in new:
    if ob.parent is None:
        ob.parent = gun
if not P.get('mag'):
    bpy.data.objects.remove(bpy.data.objects['magazine'])   # the forearm runs where it sits
sil = bpy.data.objects['silencer-small']
sil.location = (0, -0.43, 0.06); sil.rotation_euler = (0, 0, math.radians(180))
body = bpy.data.objects['blaster-a']; me = body.data
img = [n.image for m in me.materials for n in m.node_tree.nodes if n.type == 'TEX_IMAGE'][0]
px = img.pixels[:]; IW, IH = img.size; uv = me.uv_layers.active.data
gp = []
for poly in me.polygons:
    u = sum(uv[i].uv[0] for i in poly.loop_indices) / poly.loop_total
    v = sum(uv[i].uv[1] for i in poly.loop_indices) / poly.loop_total
    k = (min(IH - 1, int(v * IH)) * IW + min(IW - 1, int(u * IW))) * 4
    if px[k] < 0.3:
        for vi in poly.vertices:
            co = me.vertices[vi].co
            if co.z < -0.07:
                gp.append(co.copy())
gc = sum(gp, Vector()) / len(gp)
gax = Vector((0, 0, 1))
for _ in range(30):
    n = Vector()
    for p in gp:
        d = p - gc; n += d * d.dot(gax)
    gax = n.normalized()
if gax.z < 0:
    gax = -gax
zs = [(p - gc).dot(gax) for p in gp]
glen = max(zs) - min(zs)
print("GRIP axis", tuple(round(x, 3) for x in gax), "len", round(glen, 3))
gfwd = Vector((0, -1, 0)); gfwd = (gfwd - gax * gax.dot(gfwd)).normalized()
G = Matrix((gax.cross(gfwd), gfwd, gax)).transposed()          # gun-local: x, fwd, up
spin = math.radians(f('spin', 0))
hf = (-rear)
hf = (Matrix.Rotation(spin, 3, ax) @ hf).normalized()
H = Matrix((ax.cross(hf), hf, ax)).transposed()
R = Matrix.Rotation(math.radians(f('tilt', 0)), 3, ax.cross(hf).normalized()) @ H @ G.inverted()   # tilt: muzzle up in the fist
# grip top under the index knuckle: slide the grip along ax
slide = f('slide', 0.0)
gcen = gc + gax * (f('gtop', 0.0))
T = Matrix.Translation(hole + ax * slide + hf * f('push', 0.0))
gun_hand = T @ R.to_4x4() @ Matrix.Scale(GS, 4) @ Matrix.Translation(-gcen)   # world, at rest wrist
gun_in_wrist = Wi @ gun_hand

# ---- 4. place in view ---------------------------------------------------------
# Desired: grip centre at GRIP (eye-relative), barrel toward the converge point,
# rolled by `cant` (positive = top of gun leans inward/left).
GRIP = CAM + Vector((f('gx', 2.2), f('gy', 5.0), f('gz', -1.9)))
CONV = CAM + Vector((0, f('conv', 400.0), 0))
muz_local = Vector((0, -0.45, 0.06))        # silencer tip, gun-local
def gun_frame(mw):
    fwd = (mw.to_3x3() @ Vector((0, -1, 0))).normalized()
    up = (mw.to_3x3() @ Vector((0, 0, 1))).normalized()
    return fwd, up
# iterate: wrist matrix -> gun matrix -> correction
Wnew = Wr.copy()
for it in range(8):
    gm = Wnew @ gun_in_wrist
    grip_w = gm @ gcen
    muz_w = gm @ muz_local
    want_f = (CONV - muz_w).normalized()
    want_f = (Matrix.Rotation(math.radians(f('yaw', 0)), 3, 'Z') @ want_f)
    want_f = (Matrix.Rotation(math.radians(f('pitch', 0)), 3, want_f.cross(Vector((0, 0, 1))).normalized()) @ want_f)
    upw = Vector((0, 0, 1)); upw = (upw - want_f * upw.dot(want_f)).normalized()
    upw = Matrix.Rotation(math.radians(-f('cant', 8)), 3, want_f) @ upw
    fwd, up = gun_frame(gm)
    cur = Matrix((fwd.cross(up), fwd, up)).transposed()
    want = Matrix((want_f.cross(upw), want_f, upw)).transposed()
    rot = (want @ cur.inverted()).to_4x4()
    Wnew = Matrix.Translation(GRIP) @ rot @ Matrix.Translation(-grip_w) @ Wnew
ik = pb['wrist_ik.r']
ik.matrix = a.matrix_world.inverted() @ Wnew @ (a.data.bones['wrist.r'].matrix_local.inverted() @ a.data.bones['wrist_ik.r'].matrix_local)
# elbow out and down
pt = pb['arm_target.r']
pt.location = Vector((f('px', 0), f('py', 0), f('pz', 0)))
upd()
Wgot = wm('wrist.r')
gun.matrix_world = Wgot @ gun_in_wrist
upd()
err = (Wgot.translation - Wnew.translation).length
print("IK err %.3f" % err)
grip_final = gun.matrix_world @ gcen
print("GRIPW", tuple(round(x, 3) for x in grip_final - CAM))

# ---- 5. renders ---------------------------------------------------------------
s = bpy.context.scene
s.render.engine = 'BLENDER_WORKBENCH'; s.display.shading.light = 'STUDIO'; s.display.shading.color_type = 'TEXTURE'
s.render.resolution_x = 960; s.render.resolution_y = 540
cam = bpy.data.objects['Camera']; s.camera = cam
cam.data.type = 'PERSP'
cam.data.sensor_fit = 'VERTICAL'; cam.data.sensor_height = 24.0
cam.data.lens = 12.0 / math.tan(math.radians(27.5)); cam.data.clip_start = 0.05   # = Godot VM_FOV 55, vertical
def shot(name, loc, rot, ortho=0.0):
    cam.location = loc; cam.rotation_euler = [math.radians(x) for x in rot]
    if ortho:
        cam.data.type = 'ORTHO'; cam.data.ortho_scale = ortho
    else:
        cam.data.type = 'PERSP'
    s.render.filepath = SCR + TAG + '_' + name; bpy.ops.render.render(write_still=True)
shot('view.png', CAM, (90, 0, 0))
g = grip_final
Z = f('zoom', 1.6)
shot('side.png', g + Vector((4, 0, 0)), (90, 0, 90), Z)
shot('in.png', g + Vector((-4, 0, 0)), (90, 0, -90), Z)
shot('top.png', g + Vector((0, 0, 4)), (0, 0, 0), Z)
shot('under.png', g + Vector((0, 0, -4)), (180, 0, 0), Z)

if P.get('export'):
    m = bpy.data.objects['arms_mesh']
    dg = bpy.context.evaluated_depsgraph_get()
    me2 = bpy.data.meshes.new_from_object(m.evaluated_get(dg))
    hand = bpy.data.objects.new('hand', me2); s.collection.objects.link(hand)
    hand.matrix_world = m.matrix_world.copy()
    import bmesh
    bm = bmesh.new(); bm.from_mesh(me2)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.x < -0.2], context='VERTS')
    bm.to_mesh(me2); bm.free()
    for ob in list(bpy.data.objects):
        if ob.name in ('arms', 'arms_mesh') or ob.type == 'CAMERA':
            bpy.data.objects.remove(ob)
    root = bpy.data.objects.new('viewmodel', None); s.collection.objects.link(root)
    for ob in list(bpy.data.objects):
        if ob is not root and ob.parent is None:
            mw = ob.matrix_world.copy(); ob.parent = root; ob.matrix_world = mw
    sc = f('scale', 0.035)
    gmw = gun.matrix_world.copy()
    def gd(v):      # Blender world point -> Godot model space
        q = sc * (v - CAM); return "Vector3(%.4f, %.4f, %.4f)" % (q.x, q.z, -q.y)
    def gdir(v):
        v = v.normalized(); return "Vector3(%.4f, %.4f, %.4f)" % (v.x, v.z, -v.y)
    up = gmw.to_3x3() @ Vector((0, 0, 1))
    open(SCR + 'grip.txt', 'w').write("GRIP %s\nSIGHT_REAR %s\nSIGHT_FRONT %s\nGUN_UP %s\n" % (
        gd(grip_final), gd(gmw @ Vector((0, 0.19, 0.16))), gd(gmw @ Vector((0, -0.43, 0.16))), gdir(up)))
    root.matrix_world = Matrix.Scale(sc, 4) @ Matrix.Translation(-CAM)
    bpy.ops.export_scene.gltf(filepath=P['export'], export_format='GLB', export_apply=True)
    print("EXPORTED", P['export'])
