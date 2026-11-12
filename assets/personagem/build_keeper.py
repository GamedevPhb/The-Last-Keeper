"""Tome Valadares: modelo low-poly texturizado (atlas 256x256 pintado), rig e animacoes idle/andar.
Antes: python3 -I paint_atlas.py (pinta keeper_atlas.png). Depois: flatpak run org.blender.Blender --background --python <abs>/build_keeper.py
Saidas: keeper.blend, keeper.glb, keeper_atlas.png
"""
import bpy, bmesh, os, sys, math
import numpy as np
from math import radians, sin, cos, pi
from mathutils import Vector, Quaternion, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import keeper_geo as G

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene

clip = lambda x, a=0.0, b=1.0: max(a, min(b, x))

# ---------------------------------------------------------------- pecas e pesos
# cada entrada: (Part ja em mundo, lado 'C'|'L', funcao de pesos(vertice_local)->{osso: w})
ENT = []


def add(part, side, wf, M=None, local=None):
    """pesos calculados nas coordenadas locais; depois a peca e levada ao mundo (e espelhada p/ o lado R)"""
    W = [wf(np.array(v)) for v in part.verts]
    world = part.transformed(M if M is not None else np.eye(4))
    ENT.append((world, side, W, False))
    if side == "L":
        ENT.append((world.transformed(np.eye(4), mirror=True), "R", W, True))


def norm_w(d):
    s = sum(d.values())
    return {k: v / s for k, v in d.items() if v > 1e-4}


def w_torso(v):
    z = v[2]
    if z <= .88:
        d = {"hips": 1.0}
    elif z <= 1.02:
        t = (z - .88) / .14
        d = {"hips": 1 - t, "spine": t}
    elif z <= 1.18:
        d = {"spine": 1.0}
    elif z <= 1.34:
        t = (z - 1.18) / .16
        d = {"spine": 1 - t, "chest": t}
    else:
        d = {"chest": 1.0}
    if z > 1.53:
        t = clip((z - 1.53) / .055) * .5
        d = {k: x * (1 - t) for k, x in d.items()}
        d["neck"] = t
    return norm_w(d)


def w_neck(v):
    t = clip((1.52 - v[2]) / .06) * .5
    return norm_w({"neck": 1 - t, "chest": t}) if t > 0 else {"neck": 1.0}


def w_const(b):
    return lambda v: {b: 1.0}


def w_uparm(v):
    y = v[1]
    wc = .5 * clip((-.23 - y) / .07)
    wf = .5 * clip((y + .07) / .07)
    return norm_w({"chest": wc, "upper_arm.{s}": 1 - wc - wf, "forearm.{s}": wf})


def w_fore(v):
    y = v[1]
    wu = .5 * clip((-.20 - y) / .07)
    wh = .5 * clip((y + .04) / .04)
    return norm_w({"upper_arm.{s}": wu, "forearm.{s}": 1 - wu - wh, "hand.{s}": wh})


def w_hand(v):
    y = v[1]
    wf = .5 * clip((0.0 - y) / .03)
    return norm_w({"forearm.{s}": wf, "hand.{s}": 1 - wf})


def w_thigh(v):
    z = v[2]
    wh = .5 * clip((z - .80) / .12)
    ws = .5 * clip((.62 - z) / .12)
    return norm_w({"hips": wh, "thigh.{s}": 1 - wh - ws, "shin.{s}": ws})


def w_shin(v):
    z = v[2]
    wt = .5 * clip((z - .38) / .12)
    wf = .5 * clip((.22 - z) / .075)
    return norm_w({"thigh.{s}": wt, "shin.{s}": 1 - wt - wf, "foot.{s}": wf})


def w_shaft(v):
    ws = .5 * clip((v[2] - .15) / .05)
    return norm_w({"shin.{s}": ws, "foot.{s}": 1 - ws})


add(G.make_torso(), "C", w_torso)
add(G.make_neck(), "C", w_neck)
HS = 1.2   # cabeca maior (proporcao de jogo PS1), ancorada no queixo
MH_ = np.eye(4); MH_[:3, :3] *= HS; MH_[:3, 3] = np.array([0, -.014, 1.60]) * (1 - HS)
add(G.make_head(), "C", w_const("head"), MH_)
add(G.make_hat(), "C", w_const("head"), MH_)
add(G.make_nose(), "C", w_const("head"), MH_)
add(G.make_uparm(), "L", w_uparm, G.M_UP)
add(G.make_forearm(), "L", w_fore, G.M_FORE)
add(G.make_hand(), "L", w_hand, G.M_HAND)

CURL1, CURL2 = radians(22), radians(26)
FP = []   # (pivo_prox, pivo_dist, R2) por dedo, em espaco local da mao
for i, (x, lp, ld, r) in enumerate(G.FINGERS):
    R1 = G.rx(-CURL1)
    piv = np.array([x, G.PALM_END, 0.0])
    R2 = R1 @ G.rx(-CURL2)
    piv2 = piv + R1 @ np.array([0, lp, 0])
    FP.append((piv, piv2, R2))
    add(G.make_finger_seg("prox", lp, r, "fp%d" % i), "L", w_const("fingers.{s}"), G.M_HAND @ G.mat4(R1, piv))
    add(G.make_finger_seg("dist", ld, r, "fd%d" % i), "L", w_const("fingers_tip.{s}"), G.M_HAND @ G.mat4(R2, piv2))
TH = G.THUMB
RT = G.rz(radians(TH["yaw"])) @ G.rx(radians(TH["pitch"]))
tp = np.array(TH["pivot"])
tp2 = tp + RT @ np.array([0, TH["prox"], 0])
RT2 = RT @ G.rx(radians(-20))
add(G.make_thumb_seg("prox", "tp"), "L", w_const("thumb.{s}"), G.M_HAND @ G.mat4(RT, tp))
add(G.make_thumb_seg("dist", "td"), "L", w_const("thumb_tip.{s}"), G.M_HAND @ G.mat4(RT2, tp2))
add(G.make_thigh(), "L", w_thigh)
add(G.make_shin(), "L", w_shin)
add(G.make_shaft(), "L", w_shaft)
add(G.make_foot(), "L", w_const("foot.{s}"))

# ---------------------------------------------------------------- textura
atlas_path = os.path.join(HERE, "keeper_atlas.png")   # gerado por paint_atlas.py (python do sistema, com PIL)

# ---------------------------------------------------------------- malha unica
me = bpy.data.meshes.new("keeper")
bm = bmesh.new()
uvl = bm.loops.layers.uv.new("UVMap")
vw = []       # pesos por vertice (nomes de osso resolvidos)
tri_count = 0
for p, side, W, mir in ENT:
    vs = []
    for v, wd in zip(p.verts, W):
        vs.append(bm.verts.new(v))
        s = "L" if side == "L" else "R"
        vw.append({k.format(s=s): x for k, x in wd.items()})
    for f, uv in zip(p.faces, p.uvs):
        face = bm.faces.new([vs[i] for i in f])
        face.smooth = True
        for loop, (ux, uy) in zip(face.loops, uv):
            loop[uvl].uv = (ux / G.ATLAS, 1.0 - uy / G.ATLAS)
    tri_count += p.tris()
bm.verts.ensure_lookup_table()
bm.to_mesh(me)
bm.free()
keeper = bpy.data.objects.new("keeper", me)
sc.collection.objects.link(keeper)
print("TRIANGULOS", tri_count, "VERTICES", len(me.vertices))

# material com textura
img = bpy.data.images.load(atlas_path)
img.pack()
mat = bpy.data.materials.new("keeper_mat")
mat.use_nodes = True
nt = mat.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
out = nt.nodes.new("ShaderNodeOutputMaterial")
bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
bsdf.inputs["Roughness"].default_value = 1.0
for nm in ("Specular IOR Level", "Specular"):
    if nm in bsdf.inputs:
        bsdf.inputs[nm].default_value = 0.0
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = img
tex.interpolation = "Closest"
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(bsdf.outputs[0], out.inputs[0])
me.materials.append(mat)

# ---------------------------------------------------------------- armature
arm_data = bpy.data.armatures.new("KeeperRig")
rig = bpy.data.objects.new("KeeperRig", arm_data)
sc.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
eb = arm_data.edit_bones
V3 = lambda a: Vector([float(x) for x in a])


def bone(name, h, t, parent=None):
    b = eb.new(name)
    b.head, b.tail = V3(h), V3(t)
    if parent:
        b.parent = eb[parent]
    return b


bone("hips", (0, 0, .92), (0, 0, 1.0))
bone("spine", (0, 0, 1.0), (0, 0, 1.25), "hips")
bone("chest", (0, 0, 1.25), (0, 0, 1.47), "spine")
bone("neck", (0, 0, 1.47), (0, 0, 1.60), "chest")
bone("head", (0, 0, 1.60), (0, 0, 1.85), "neck")
MH = G.M_HAND
loc = lambda p: (MH @ np.append(np.array(p, float), 1.0))[:3]
for s, sg in (("L", 1), ("R", -1)):
    X = lambda a: (np.array(a, float) * np.array([sg, 1, 1]))
    bone("upper_arm." + s, X(G.SHOULDER), X(G.ELBOW), "chest")
    bone("forearm." + s, X(G.ELBOW), X(G.WRIST), "upper_arm." + s)
    bone("hand." + s, X(G.WRIST), X(loc((0, G.PALM_END, 0))), "forearm." + s)
    piv, piv2, R2 = FP[1]
    tipend = piv2 + R2 @ np.array([0, G.FINGERS[1][2], 0])
    bone("fingers." + s, X(loc(piv)), X(loc(piv2)), "hand." + s)
    bone("fingers_tip." + s, X(loc(piv2)), X(loc(tipend)), "fingers." + s)
    tend = tp2
    bone("thumb." + s, X(loc(tp)), X(loc(tp2)), "hand." + s)
    bone("thumb_tip." + s, X(loc(tp2)), X(loc(tp2 + RT2 @ np.array([0, TH["dist"], 0]))), "thumb." + s)
    bone("thigh." + s, X((G.HIP_X, 0, .92)), X((G.HIP_X, 0, .50)), "hips")
    bone("shin." + s, X((G.HIP_X, 0, .50)), X((G.HIP_X, 0, .13)), "thigh." + s)
    bone("foot." + s, X((G.HIP_X, 0, .13)), X((G.HIP_X, -.17, .045)), "shin." + s)
bpy.ops.object.mode_set(mode="OBJECT")
print("OSSOS", len(arm_data.bones))

for i, w in enumerate(vw):
    for name, x in w.items():
        pass
groups = {}
for b in arm_data.bones:
    groups[b.name] = keeper.vertex_groups.new(name=b.name)
for i, w in enumerate(vw):
    for name, x in w.items():
        groups[name].add([i], x, "REPLACE")
keeper.parent = rig
mod = keeper.modifiers.new("Armature", "ARMATURE")
mod.object = rig

# ---------------------------------------------------------------- animacoes
sc.render.fps = 24
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="POSE")
PB = rig.pose.bones
for pb in PB:
    pb.rotation_mode = "QUATERNION"
RB = {b.name: b.matrix_local.to_3x3() for b in arm_data.bones}
AX, AY, AZ = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))


def pose_frame(frame, spec, loc_spec=None):
    """spec: {osso: [(eixo_mundo, graus), ...]} rotacoes em eixos de repouso do armature; loc_spec: {osso: Vector mundo}"""
    for pb in PB:
        q = Quaternion((1, 0, 0, 0))
        for axis, deg in spec.get(pb.name, []):
            q = Quaternion(axis, radians(deg)) @ q
        R = RB[pb.name]
        pb.rotation_quaternion = (R.inverted() @ q.to_matrix() @ R).to_quaternion()
        pb.keyframe_insert("rotation_quaternion", frame=frame)
    for name, vec in (loc_spec or {}).items():
        pb = PB[name]
        pb.location = RB[name].inverted() @ Vector(vec)
        pb.keyframe_insert("location", frame=frame)


def new_action(name):
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    rig.animation_data_create()
    rig.animation_data.action = act
    return act


def build_idle():
    N = 48
    new_action("idle")
    for f in range(N + 1):
        t = 2 * pi * f / N
        b = sin(t)
        spec = {
            "spine": [(AX, -0.8 * b)],
            "chest": [(AX, -1.4 * b), (AZ, 0.8 * sin(t * 0.5))],
            "neck": [(AX, 0.6 * b), (AZ, -0.6 * sin(t * 0.5))],
            "head": [(AX, 0.5 * sin(t - .6)), (AZ, 1.8 * sin(t * 0.5 + 1))],
            "upper_arm.L": [(AX, 1.2 * sin(t - 0.4)), (AY, 0.8 * b)], "upper_arm.R": [(AX, 1.2 * sin(t - 0.4)), (AY, -0.8 * b)],
            "forearm.L": [(AX, -4 - 1.0 * sin(t - .8))], "forearm.R": [(AX, -5 - 1.0 * sin(t - .8))],
            "hand.L": [(AX, 1.5 * sin(t - 1.2))], "hand.R": [(AX, 1.5 * sin(t - 1.2))],
            "thigh.L": [(AX, -1.0), (AY, 0)], "thigh.R": [(AX, 1.0)],
            "shin.L": [(AX, 2.0)], "shin.R": [(AX, 1.0)],
            "foot.L": [(AX, -1.0)], "foot.R": [(AX, 0.0)],
            "fingers.L": [(AX, 3 * b)], "fingers.R": [(AX, 3 * b)],
        }
        pose_frame(f + 1, spec, {"hips": (0.004 * sin(t * 0.5), 0, -0.004 * (1 - cos(t)) * 0.5)})


def build_walk():
    N = 24
    new_action("walk")
    A, K = 24.0, 30.0
    for f in range(N + 1):
        p = 2 * pi * f / N
        spec = {}
        for s, ph in (("L", p), ("R", p + pi)):
            th = -A * sin(ph)                     # frente = negativo
            kn = K * max(0.0, cos(ph - 0.25)) ** 1.2 + 6 * max(0.0, -cos(ph))
            spec["thigh." + s] = [(AX, th)]
            spec["shin." + s] = [(AX, kn)]
            toe = 14 * max(0.0, sin(ph - 1.4)) * (1 if cos(ph) > 0 else 0)
            spec["foot." + s] = [(AX, -(th + kn) + toe * 0 + (10 if cos(ph) > 0.2 else 0) * -0.0)]
        for s, ph in (("L", p + pi), ("R", p)):    # braco contra a perna do mesmo lado
            sw = -16.0 * sin(ph)
            spec["upper_arm." + s] = [(AX, sw)]
            spec["forearm." + s] = [(AX, -(10 + 9 * max(0.0, -sin(ph + pi))))]
            spec["hand." + s] = [(AX, -4)]
            spec["fingers." + s] = [(AX, 4)]
        spec["spine"] = [(AZ, 3.5 * sin(p)), (AY, 1.2 * cos(p))]
        spec["chest"] = [(AZ, 3.0 * sin(p)), (AX, -2.0)]
        spec["neck"] = [(AZ, -2.0 * sin(p)), (AX, 1.5)]
        spec["head"] = [(AZ, -2.0 * sin(p)), (AX, 0.8 * cos(2 * p))]
        bob = -0.030 * (0.5 - 0.5 * cos(2 * p)) * 0 - 0.028 * (0.5 + 0.5 * cos(2 * p + pi)) * 0 + 0.014 * cos(2 * p + pi) - 0.014
        sway = 0.012 * sin(p)
        spec["hips"] = [(AZ, -3.0 * sin(p)), (AY, 2.0 * sin(p))]
        pose_frame(f + 1, spec, {"hips": (sway, 0, bob)})


build_idle()
build_walk()
ad = rig.animation_data
ad.action = None
for act in bpy.data.actions:
    tr = ad.nla_tracks.new()
    tr.name = act.name
    st = tr.strips.new(act.name, 1, act)
    st.name = act.name
bpy.ops.object.mode_set(mode="OBJECT")
for pb in PB:
    pb.rotation_quaternion = (1, 0, 0, 0)
    pb.location = (0, 0, 0)

blend = os.path.join(HERE, "keeper.blend")
bpy.ops.wm.save_as_mainfile(filepath=blend)
glb = os.path.join(HERE, "keeper.glb")
bpy.ops.object.select_all(action="DESELECT")
keeper.select_set(True)
rig.select_set(True)
bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="NLA_TRACKS", export_apply=False, export_yup=True,
                          export_materials="EXPORT", export_image_format="AUTO", export_skins=True)
print("EXPORTADO", glb)
