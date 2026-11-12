"""Geometria e atlas do Tome Valadares (puro numpy, sem bpy). Usado por build_keeper.py e assets/maos/build_maos.py.
Convencao: Z para cima, frente = -Y, lado esquerdo do personagem = +X. Aneis de cima para baixo (imagem: topo = primeiro anel).
Cada Part guarda verts, faces (quads/n-gons), uv por canto (em pixels do atlas, y para baixo) e o mapa chave->v para a pintura.
"""
import numpy as np
from math import pi, sin, cos, radians

ATLAS = 256

# nome: (w, h)
SIZES = {
    "head": (128, 60), "torso": (128, 76), "hat": (80, 24), "neck": (32, 12),
    "uparm": (64, 44), "forearm": (64, 44), "hand": (64, 36),
    "fprox": (24, 10), "fdist": (24, 8), "tprox": (24, 10), "tdist": (24, 8),
    "thigh": (64, 40), "shin": (64, 40), "shaft": (64, 20), "foot": (64, 32), "nose": (8, 8),
}


def pack():
    """empacotamento em prateleiras -> {nome: (x, y, w, h)}"""
    order = sorted(SIZES, key=lambda k: (-SIZES[k][1], -SIZES[k][0]))
    rects, x, y, rowh = {}, 0, 0, 0
    for k in order:
        w, h = SIZES[k]
        if x + w > ATLAS:
            x, y, rowh = 0, y + rowh, 0
        rects[k] = (x, y, w, h)
        x += w
        rowh = max(rowh, h)
    assert y + rowh <= ATLAS, "atlas estourou"
    return rects


RECTS = pack()


class Part:
    def __init__(self, name, rect_name):
        self.name = name
        self.rect_name = rect_name
        self.verts = []
        self.faces = []
        self.uvs = []        # por face: lista de (x, y) px
        self.keys = []       # (chave, v)
        self.ringa = []      # (chave, a) largura por anel (para pintura)

    def tris(self):
        return sum(max(1, len(f) - 2) for f in self.faces)

    def transformed(self, M, mirror=False):
        """M: 4x4. devolve novo Part (mirror nega X depois e inverte o enrolamento)"""
        p = Part(self.name, self.rect_name)
        V = np.array(self.verts, float)
        V = (M[:3, :3] @ V.T).T + M[:3, 3]
        if mirror:
            V[:, 0] *= -1
        p.verts = [tuple(v) for v in V]
        if mirror:
            p.faces = [tuple(reversed(f)) for f in self.faces]
            p.uvs = [list(reversed(u)) for u in self.uvs]
        else:
            p.faces = [tuple(f) for f in self.faces]
            p.uvs = [list(u) for u in self.uvs]
        p.keys, p.ringa = self.keys, self.ringa
        return p


def _norm(v):
    v = np.array(v, float)
    return v / np.linalg.norm(v)


def loft(name, rect_name, rings, n, side=(1, 0, 0), front=(0, -1, 0), axis_key=2, cap_start=False, cap_end=False):
    """rings: [(cx, cy, cz, a, b)] a ao longo de side, b ao longo de front. u=0 atras, u=.5 frente."""
    side, front = np.array(side, float), np.array(front, float)
    P = Part(name, rect_name)
    x0, y0, w, h = RECTS[rect_name]
    C = np.array([r[:3] for r in rings], float)
    ab = np.array([[r[3], r[4]] for r in rings], float)
    seg = np.sqrt((np.diff(C, axis=0) ** 2).sum(1) + (np.diff(ab, axis=0) ** 2).sum(1))
    cum = np.concatenate([[0], np.cumsum(seg)])
    v = cum / cum[-1]
    for j, r in enumerate(rings):
        for k in range(n):
            th = pi + 2 * pi * k / n
            P.verts.append(tuple(C[j] + r[3] * sin(th) * side + r[4] * cos(th) * front))
        P.keys.append((C[j][axis_key], v[j]))
        P.ringa.append((C[j][axis_key], r[3]))
    # orientacao: normal do primeiro quad deve apontar para fora (relativo ao centro do anel)
    def quad(j, k):
        k2 = (k + 1) % n
        return (j * n + k, j * n + k2, (j + 1) * n + k2, (j + 1) * n + k)
    q = quad(0, n // 2)
    Vv = np.array(P.verts)
    nrm = np.cross(Vv[q[1]] - Vv[q[0]], Vv[q[3]] - Vv[q[0]])
    outward = Vv[q[0]] - C[0]
    flip = np.dot(nrm, outward) < 0
    for j in range(len(rings) - 1):
        for k in range(n):
            f = quad(j, k)
            if flip:
                f = tuple(reversed(f))
            P.faces.append(f)
            us = [k / n, (k + 1) / n, (k + 1) / n, k / n]
            vs = [v[j], v[j], v[j + 1], v[j + 1]]
            uv = [(x0 + .5 + u * (w - 1), y0 + .5 + vv * (h - 1)) for u, vv in zip(us, vs)]
            if flip:
                uv = list(reversed(uv))
            P.uvs.append(uv)

    def cap(j, at_v, start):
        ids = [j * n + k for k in range(n)]
        # normal deve olhar para longe do restante do tubo
        pts = Vv[ids]
        nn = np.cross(pts[1] - pts[0], pts[2] - pts[0])
        other = C[1] - C[0] if start else C[-2] - C[-1]
        if np.dot(nn, other) > 0:
            ids = ids[::-1]
        uvc = []
        for i in ids:
            k = i % n
            uvc.append((x0 + .5 + (k / n) * (w - 1), y0 + .5 + at_v * (h - 1)))
        P.faces.append(tuple(ids))
        P.uvs.append(uvc)
    if cap_start:
        cap(0, 0.0, True)
    if cap_end:
        cap(len(rings) - 1, 1.0, False)
    return P


def keyrow(part, key):
    """linha (px relativa ao retangulo) para uma chave (z ou y) do anel"""
    ks = np.array(part.keys)
    order = np.argsort(ks[:, 0])
    v = np.interp(key, ks[order, 0], ks[order, 1])
    return .5 + v * (SIZES[part.rect_name][1] - 1)


def keywidth(part, key):
    ks = np.array(part.ringa)
    order = np.argsort(ks[:, 0])
    return float(np.interp(key, ks[order, 0], ks[order, 1]))


# ------------------------------------------------------------------ medidas
SHOULDER = np.array([0.205, 0.0, 1.41])
L_UP, L_FORE = 0.30, 0.27
D_UP = _norm((sin(radians(22)), 0.0, -cos(radians(22))))
D_FORE = _norm((sin(radians(16)), -0.12, -cos(radians(16))))
ELBOW = SHOULDER + D_UP * L_UP
WRIST = ELBOW + D_FORE * L_FORE
HIP_X = 0.09
PALM_END = 0.095
FINGERS = [  # x local (mao esquerda, polegar em +X), comp. prox, comp. dist, raio
    (0.0315, 0.037, 0.030, 0.0108),
    (0.0105, 0.041, 0.033, 0.0112),
    (-0.0105, 0.038, 0.031, 0.0106),
    (-0.0315, 0.031, 0.026, 0.0096),
]
THUMB = dict(pivot=(0.040, 0.028, -0.004), prox=0.034, dist=0.030, r=0.0122, yaw=-34.0, pitch=-14.0)


def frame(d, out):
    Y = _norm(d)
    Z = np.array(out, float)
    Z = _norm(Z - Y * np.dot(Z, Y))
    X = np.cross(Y, Z)
    return np.column_stack([X, Y, Z])


def mat4(R, t):
    M = np.eye(4)
    M[:3, :3] = R
    M[:3, 3] = t
    return M


M_UP = mat4(frame(D_UP, (1, 0, 0)), ELBOW)
M_FORE = mat4(frame(D_FORE, (1, 0, 0)), WRIST)
M_HAND = mat4(frame(D_FORE, (1, 0, 0)), WRIST)


# ------------------------------------------------------------------ pecas
def make_torso():
    R = [(0, 0, 1.585, .075, .075), (0, 0, 1.545, .088, .082), (0, 0, 1.500, .125, .098), (0, 0, 1.460, .190, .116),
         (0, -.005, 1.380, .216, .130), (0, 0, 1.100, .186, .120),
         (0, 0, .950, .210, .134), (0, 0, .780, .252, .160)]
    return loft("torso", "torso", R, 10)


def make_neck():
    R = [(0, 0, 1.605, .047, .051), (0, 0, 1.465, .056, .058)]
    return loft("neck", "neck", R, 8)


def make_head():
    R = [(0, 0, 1.795, .015, .020), (0, 0, 1.775, .062, .076), (0, 0, 1.745, .086, .100), (0, .004, 1.705, .090, .106),
         (0, 0, 1.665, .086, .098), (0, -.006, 1.630, .076, .090), (0, -.018, 1.600, .050, .064)]
    return loft("head", "head", R, 10, cap_end=True)


def make_hat():
    R = [(0, .002, 1.824, .012, .016), (0, .004, 1.806, .050, .062), (0, .004, 1.780, .082, .098),
         (0, .006, 1.752, .099, .113), (0, .004, 1.722, .098, .112), (0, .004, 1.713, .091, .105)]
    return loft("hat", "hat", R, 10, cap_start=True)


def make_nose():
    P = Part("nose", "nose")
    V = [(0, -.102, 1.703), (0, -.128, 1.655), (.017, -.107, 1.649), (-.017, -.107, 1.649), (0, -.113, 1.645)]
    P.verts = V
    x0, y0, w, h = RECTS["nose"]
    uvmap = [(4, 1), (4, 5), (1, 7), (7, 7), (4, 7)]
    cen = np.mean(np.array(V), axis=0)
    tris = [(0, 2, 1), (0, 1, 3), (1, 2, 4), (1, 4, 3)]
    for t in tris:
        a, b, c = [np.array(V[i]) for i in t]
        nn = np.cross(b - a, c - a)
        if np.dot(nn, (a + b + c) / 3 - cen) < 0:
            t = (t[0], t[2], t[1])
        P.faces.append(t)
        P.uvs.append([(x0 + uvmap[i][0] + .5, y0 + uvmap[i][1] + .5) for i in t])
    return P


def make_uparm():
    R = [(0, y, 0, a, b) for y, a, b in [(-.30, .060, .056), (-.265, .068, .062), (-.16, .060, .056), (-.05, .052, .050), (0, .050, .048)]]
    return loft("uparm", "uparm", [(0, y, 0, a, b) for _, y, _, a, b in R], 8, side=(1, 0, 0), front=(0, 0, 1), axis_key=1, cap_start=True)


def make_forearm():
    R = [(-.27, .050, .048), (-.21, .054, .050), (-.10, .046, .042), (-.04, .042, .038), (-.025, .049, .045), (0, .049, .045)]
    return loft("forearm", "forearm", [(0, y, 0, a, b) for y, a, b in R], 8, side=(1, 0, 0), front=(0, 0, 1), axis_key=1)


def make_hand():
    R = [(-.03, .044, .038), (.02, .041, .034), (.045, .046, .030), (.075, .047, .027), (PALM_END, .044, .023)]
    return loft("hand", "hand", [(0, y, 0, a, b) for y, a, b in R], 8, side=(1, 0, 0), front=(0, 0, 1), axis_key=1, cap_end=True)


def make_finger_seg(kind, length, r, name):
    """kind prox/dist; eixo +Y a partir da origem (junta); n=5"""
    if kind == "prox":
        R = [(0, 0, 0, r, r * .92), (0, length, 0, r * .90, r * .85)]
        return loft(name, "fprox", R, 5, side=(1, 0, 0), front=(0, 0, 1), axis_key=1)
    R = [(0, 0, 0, r * .90, r * .85), (0, length, 0, r * .50, r * .46)]
    return loft(name, "fdist", R, 5, side=(1, 0, 0), front=(0, 0, 1), axis_key=1, cap_end=True)


def make_thumb_seg(kind, name):
    T = THUMB
    r = T["r"]
    if kind == "prox":
        R = [(0, 0, 0, r, r * .95), (0, T["prox"], 0, r * .88, r * .85)]
        return loft(name, "tprox", R, 5, side=(1, 0, 0), front=(0, 0, 1), axis_key=1)
    R = [(0, 0, 0, r * .88, r * .85), (0, T["dist"], 0, r * .50, r * .46)]
    return loft(name, "tdist", R, 5, side=(1, 0, 0), front=(0, 0, 1), axis_key=1, cap_end=True)


def rx(a):
    c, s = cos(a), sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def rz(a):
    c, s = cos(a), sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def make_thigh():
    R = [(HIP_X, 0, .92, .088, .092), (HIP_X, .004, .72, .078, .085), (HIP_X, .004, .50, .058, .066)]
    return loft("thigh", "thigh", R, 8, cap_start=True)


def make_shin():
    R = [(HIP_X, 0, .50, .058, .064), (HIP_X, .012, .32, .052, .060), (HIP_X, 0, .17, .054, .058), (HIP_X, 0, .145, .056, .060)]
    return loft("shin", "shin", R, 8)


def make_shaft():
    R = [(HIP_X, 0, .20, .047, .052), (HIP_X, 0, .095, .050, .056)]
    return loft("shaft", "shaft", R, 8)


def make_foot():
    R = [(HIP_X, .070, .062, .048, .062), (HIP_X, -.020, .050, .053, .052), (HIP_X, -.120, .040, .052, .036), (HIP_X, -.185, .030, .038, .026)]
    # eixo Y (frente -Y): aneis perpendiculares a Y, 'front' = +Z (cima), costura embaixo
    return loft("foot", "foot", R, 8, side=(1, 0, 0), front=(0, 0, 1), axis_key=1, cap_start=True, cap_end=True)
