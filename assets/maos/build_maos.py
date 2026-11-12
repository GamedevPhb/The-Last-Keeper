"""Maos em primeira pessoa (The Last Keeper): renderiza quadros 160x120 RGBA a partir das maos/antebracos do keeper
(mesma geometria e mesmo atlas pintado de assets/personagem/: keeper_geo.py + keeper_atlas.png).
Rodar: flatpak run org.blender.Blender --background --python <abs>/build_maos.py [-- anim1 anim2 ...]
Depois: python3 -I postprocess.py (paleta de 28 cores, alfa binario, sheets).  Env BIG=1 -> render 3x p/ conferencia.
"""
import bpy, bmesh, math, os, sys
import numpy as np
from math import sin, cos, pi, radians as rad
from mathutils import Vector

OUT = os.path.dirname(os.path.abspath(__file__))
KDIR = os.path.join(os.path.dirname(OUT), "personagem")
sys.path.insert(0, KDIR)
import keeper_geo as G

RAW = os.path.join(OUT, "_raw")
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


def srgb(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return (*[(x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c], 1.0)


def mat(name, hexc, emit=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    if emit:
        n = nt.nodes.new("ShaderNodeEmission")
        n.inputs["Color"].default_value = srgb(hexc)
        n.inputs["Strength"].default_value = emit
    else:
        n = nt.nodes.new("ShaderNodeBsdfDiffuse")
        n.inputs["Color"].default_value = srgb(hexc)
    nt.links.new(n.outputs[0], out.inputs[0])
    return m


M = {
    "latao": mat("latao", "#A88A48"), "ferro": mat("ferro", "#3A3F3F"), "ferro2": mat("ferro2", "#262B2B"),
    "ferrug": mat("ferrug", "#7A4521"), "sangue": mat("sangue", "#8E2A1E"), "sangue2": mat("sangue2", "#5E1A14"),
    "lenteoff": mat("lenteoff", "#6E7A72"), "corpo": mat("corpo", "#6B7873"), "lenteon": mat("lenteon", "#FFF1B8", emit=3.0),
}
# material pintado (atlas do keeper), nearest
img = bpy.data.images.load(os.path.join(KDIR, "keeper_atlas.png"))
tm = bpy.data.materials.new("keeper")
tm.use_nodes = True
nt = tm.node_tree
nt.nodes.clear()
o_ = nt.nodes.new("ShaderNodeOutputMaterial")
b_ = nt.nodes.new("ShaderNodeBsdfPrincipled")
b_.inputs["Roughness"].default_value = 1.0
for nm in ("Specular IOR Level", "Specular"):
    if nm in b_.inputs:
        b_.inputs[nm].default_value = 0.0
t_ = nt.nodes.new("ShaderNodeTexImage")
t_.image, t_.interpolation = img, "Closest"
nt.links.new(t_.outputs["Color"], b_.inputs["Base Color"])
nt.links.new(b_.outputs[0], o_.inputs[0])
M["keeper"] = tm


def empty(name, loc=(0, 0, 0), parent=None):
    e = bpy.data.objects.new(name, None)
    sc.collection.objects.link(e)
    e.location = loc
    if parent:
        e.parent = parent
    return e


def mesh_obj(part, name, parent, mirror=False, materials=None):
    p = part.transformed(np.eye(4), mirror=mirror)
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    vs = [bm.verts.new(v) for v in p.verts]
    for f, uv in zip(p.faces, p.uvs):
        face = bm.faces.new([vs[i] for i in f])
        face.smooth = True
        for loop, (ux, uy) in zip(face.loops, uv):
            loop[uvl].uv = (ux / G.ATLAS, 1.0 - uy / G.ATLAS)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    sc.collection.objects.link(o)
    me.materials.append(M["keeper"])
    o.parent = parent
    return o


def box(name, size, loc, m, parent=None, rot=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if bevel:
        md = o.modifiers.new("b", "BEVEL")
        md.width, md.segments = bevel, 1
        bpy.ops.object.modifier_apply(modifier="b")
    o.location = loc
    o.rotation_euler = rot
    o.data.materials.append(M[m])
    for p in o.data.polygons:
        p.use_smooth = False
    if parent:
        o.parent = parent
    return o


def cyl(name, r, depth, loc, m, parent=None, rot=(0, 0, 0), verts=8, r2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=(r if r2 is None else r2), depth=depth)
    o = bpy.context.active_object
    o.name = name
    o.location = loc
    o.rotation_euler = rot
    o.data.materials.append(M[m])
    for p in o.data.polygons:
        p.use_smooth = False
    if parent:
        o.parent = parent
    return o


# ---------------- mao (geometria do keeper) ----------------
# eixos locais do pulso: +Y = dedos, +Z = dorso, polegar em +X (esq) / -X (dir)
class Hand:
    def __init__(self, side):
        s = 1 if side == "L" else -1
        self.s = s
        mir = s < 0
        self.root = empty("fore" + side)
        self.sleeve = mesh_obj(G.make_forearm(), "forearm" + side, self.root, mir)
        self.sleeve.scale = (0.84, 1.0, 0.84)
        self.hand = empty("hand" + side, (0, 0, 0), self.root)
        mesh_obj(G.make_hand(), "palm" + side, self.hand, mir)
        self.f = []
        for i, (x, lp, ld, r) in enumerate(G.FINGERS):
            pe = empty("fp%d%s" % (i, side), (s * x, G.PALM_END, 0), self.hand)
            mesh_obj(G.make_finger_seg("prox", lp, r, "fpb"), "fpb%d%s" % (i, side), pe, mir)
            de = empty("fd%d%s" % (i, side), (0, lp, 0), pe)
            mesh_obj(G.make_finger_seg("dist", ld, r, "fdb"), "fdb%d%s" % (i, side), de, mir)
            self.f.append((pe, de))
        T = G.THUMB
        px, py, pz = T["pivot"]
        self.t0 = empty("th0" + side, (s * px, py, pz), self.hand)
        mesh_obj(G.make_thumb_seg("prox", "tp"), "tpb" + side, self.t0, mir)
        self.t1 = empty("th1" + side, (0, T["prox"], 0), self.t0)
        mesh_obj(G.make_thumb_seg("dist", "td"), "tdb" + side, self.t1, mir)

    def set(self, pos, rot=(0, 0, 0), wrist=(0, 0, 0), curl=0.25, thumb=0.2, fingers=None, spread=0.0, tyaw=0.0, c2=1.0):
        """pos: pulso (m); rot: euler do antebraco (graus); wrist: euler da mao; curl 0..1 (prox 70, dist 85 graus*c2)"""
        s = self.s
        self.root.location = pos
        self.root.rotation_euler = [rad(a) for a in rot]
        self.hand.rotation_euler = [rad(a) for a in wrist]
        cs = fingers if fingers else [curl * 0.95, curl, curl * 1.03, curl * 1.10]
        for i, (p, d) in enumerate(self.f):
            c = min(1.15, cs[i])
            p.rotation_euler = (-rad(72) * c, 0, rad(spread * (1.5 - i)) * s * -1)
            d.rotation_euler = (-rad(88) * c * c2, 0, 0)
        T = G.THUMB
        self.t0.rotation_euler = (rad(T["pitch"]) - rad(42) * thumb, 0, s * rad(T["yaw"] + 22 * thumb + tyaw))
        self.t1.rotation_euler = (-rad(24) - rad(40) * thumb, 0, 0)


# ---------------- props ----------------
def flashlight(parent):
    """eixo +Y = lente. origem = centro do cabo (onde a palma segura)"""
    f = empty("flash", (0, 0, 0), parent)
    cyl("body", 0.022, 0.15, (0, 0.005, 0), "corpo", f, (rad(90), 0, 0), 10)
    cyl("band", 0.0245, 0.022, (0, -0.040, 0), "ferrug", f, (rad(90), 0, 0), 10)
    cyl("band2", 0.0245, 0.012, (0, 0.045, 0), "ferrug", f, (rad(90), 0, 0), 10)
    cyl("head", 0.037, 0.060, (0, 0.108, 0), "latao", f, (rad(90), 0, 0), 12, 0.026)
    lens = cyl("lens", 0.033, 0.010, (0, 0.142, 0), "lenteoff", f, (rad(90), 0, 0), 12)
    cyl("cap", 0.0235, 0.012, (0, -0.084, 0), "ferro2", f, (rad(90), 0, 0), 10)
    box("switch", (0.012, 0.022, 0.008), (0, 0.018, 0.0235), "latao", f, bevel=0.002)
    return f, lens


def can(parent):
    """galao com alca (barra) no topo; origem = centro da alca"""
    c = empty("can", (0, 0, 0), parent)
    c.scale = (0.78, 0.78, 0.78)
    box("canbody", (0.150, 0.085, 0.185), (0, 0, -0.118), "sangue", c, bevel=0.012)
    box("canrib", (0.156, 0.090, 0.010), (0, 0, -0.085), "sangue2", c, bevel=0.003)
    box("canrib2", (0.156, 0.090, 0.010), (0, 0, -0.165), "sangue2", c, bevel=0.003)
    box("canx", (0.140, 0.004, 0.100), (0, -0.0435, -0.118), "sangue2", c)
    box("cap", (0.036, 0.036, 0.026), (0.045, 0, -0.018), "latao", c, bevel=0.005)
    cyl("handlebar", 0.008, 0.095, (0, 0, 0), "ferro", c, (0, rad(90), 0), 8)
    box("h2", (0.010, 0.016, 0.050), (-0.047, 0, -0.025), "ferro", c)
    box("h3", (0.010, 0.016, 0.050), (0.047, 0, -0.025), "ferro", c)
    return c


L, R = Hand("L"), Hand("R")
flash_obj, lens_obj = flashlight(R.hand)
can_obj = can(R.hand)
GRIP = (0.0, 0.062, -0.046)     # eixo da barra/cabo em coordenadas locais da mao (barra ao longo de X)

wheel = empty("wheel", (0.0, 0.50, -0.20))
bpy.ops.mesh.primitive_torus_add(major_radius=0.12, minor_radius=0.013, major_segments=12, minor_segments=6)
tor = bpy.context.active_object
tor.rotation_euler = (rad(90), 0, 0)
tor.parent = wheel
tor.data.materials.append(M["latao"])
for a in range(0, 180, 60):
    box("spoke", (0.24, 0.014, 0.014), (0, 0, 0), "latao", wheel, rot=(0, rad(a), 0))
cyl("hub", 0.022, 0.05, (0, 0, 0), "ferro", wheel, (rad(90), 0, 0), 10)
cyl("pipe", 0.025, 0.40, (0, 0.2, 0), "ferrug", wheel, (rad(90), 0, 0), 8)

pump = empty("pump", (0.30, 0.52, -0.26))
box("pumpbase", (0.09, 0.09, 0.20), (0.0, 0, -0.10), "corpo", pump, bevel=0.01)
box("pumpgauge", (0.06, 0.02, 0.06), (-0.05, -0.04, 0.0), "latao", pump, bevel=0.004)
lever = empty("lever", (0, 0, 0), pump)
cyl("levbar", 0.011, 0.20, (-0.10, 0, 0), "ferrug", lever, (0, rad(90), 0), 8)
cyl("levgrip", 0.017, 0.08, (-0.20, 0, 0), "ferro2", lever, (0, rad(90), 0), 8)


def show(o, on=True):
    o.hide_render = not on
    for ch in o.children_recursive:
        ch.hide_render = not on


# ---------------- camera, luz ----------------
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
cam.location = (0, 0, 0)
cam.rotation_euler = (rad(78), 0, 0)
cam.data.sensor_fit = "VERTICAL"
cam.data.angle = rad(70)
cam.data.clip_start = 0.02
sc.camera = cam

spot = bpy.data.objects.new("lanterna", bpy.data.lights.new("lanterna", "SPOT"))
sc.collection.objects.link(spot)
spot.location = (0.06, -0.04, 0.02)
spot.rotation_euler = (rad(90 - 8), 0, 0)    # olha para +Y, levemente para baixo
spot.data.energy = float(os.environ.get("SPOTE", 26))
spot.data.color = (1.0, 0.78, 0.5)
spot.data.spot_size = rad(95)
spot.data.spot_blend = 0.9
spot.data.shadow_soft_size = 0.05
fill = bpy.data.objects.new("fill", bpy.data.lights.new("fill", "SUN"))
fill.data.energy = 0.55
fill.data.color = (0.45, 0.62, 0.78)
fill.rotation_euler = (rad(-125), 0, rad(30))
sc.collection.objects.link(fill)
sc.world = bpy.data.worlds.new("w")
sc.world.use_nodes = True
bgn = next(n for n in sc.world.node_tree.nodes if n.type == "BACKGROUND")
bgn.inputs[0].default_value = (0.07, 0.10, 0.12, 1)
bgn.inputs[1].default_value = 1.0
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 48
sc.cycles.use_denoising = False
sc.cycles.filter_width = 0.01
sc.cycles.max_bounces = 3
sc.render.film_transparent = True
sc.render.resolution_x, sc.render.resolution_y, sc.render.resolution_percentage = 160, 120, 100
if os.environ.get("BIG"):
    sc.render.resolution_percentage = 300
    RAW = os.path.join(OUT, "_big")
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
sc.view_settings.view_transform = "Standard"

exec(open(os.path.join(OUT, "maos_anims.py")).read())

# ---------------- render ----------------
os.makedirs(RAW, exist_ok=True)
todo = argv or list(anims)
for name in todo:
    n, fn = anims[name]
    d = os.path.join(RAW, name)
    os.makedirs(d, exist_ok=True)
    for i in range(n):
        for o in (flash_obj, can_obj, wheel, pump):
            show(o, False)
        fn(i, n)
        sc.render.filepath = os.path.join(d, "%02d.png" % i)
        bpy.ops.render.render(write_still=True)
    print("RENDERED", name, n)
