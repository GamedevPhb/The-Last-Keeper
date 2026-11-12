"""Pintura do atlas 256x256 do Tome Valadares (numpy + PIL). paint_atlas(parts) -> PIL.Image RGB.
parts: dict nome_do_retangulo -> Part (de keeper_geo) para mapear z/y -> linha e posicao lateral -> coluna."""
import numpy as np
from math import pi, asin, sin, cos
from PIL import Image, ImageDraw
import keeper_geo as G

# paleta suja
COAT = np.array([88, 106, 97.0])
COAT_D = np.array([52, 64, 59.0])
COAT_L = np.array([132, 158, 140.0])
PANTS = np.array([38, 46, 46.0])
LEATHER = np.array([96, 56, 30.0])
LEATHER_D = np.array([58, 34, 20.0])
GLOVE = np.array([120, 70, 36.0])
GLOVE_D = np.array([78, 44, 24.0])
GLOVE_L = np.array([168, 112, 62.0])
BRASS = np.array([199, 163, 87.0])
SKIN = np.array([158, 120, 92.0])
SKIN_D = np.array([112, 80, 64.0])
SKIN_L = np.array([188, 150, 116.0])
GREY = np.array([138, 136, 128.0])
BONE = np.array([224, 214, 179.0])
BLACK = np.array([8, 13, 13.0])


def noise(w, h, cell, seed, wrap=True):
    rng = np.random.default_rng(seed)
    gw, gh = max(2, w // cell + 1), max(2, h // cell + 2)
    g = rng.random((gh, gw))
    if wrap:
        g[:, -1] = g[:, 0]
    im = Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    return np.array(im) / 255.0


def base(w, h, color, seed, amp=14, cells=(3, 7)):
    n = noise(w, h, cells[0], seed) * 0.6 + noise(w, h, cells[1], seed + 1) * 0.4
    return np.clip(color[None, None, :] + (n[:, :, None] - 0.5) * 2 * amp, 0, 255)


def shade_u(arr, k=0.10, center=0.5, v_top=0.0, v_bot=0.0):
    h, w, _ = arr.shape
    u = (np.arange(w) + .5) / w
    f = (1 - k) + k * np.cos(2 * pi * (u - center))
    arr = arr * f[None, :, None]
    if v_top or v_bot:
        v = (np.arange(h) + .5) / h
        g = 1 + v_top * (1 - v) - v_bot * v
        arr = arr * g[:, None, None]
    return arr


def toim(arr):
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))


def blend_rect(arr, x0, y0, x1, y1, color, a=1.0):
    h, w, _ = arr.shape
    x0, x1 = max(0, int(x0)), min(w, int(x1))
    y0, y1 = max(0, int(y0)), min(h, int(y1))
    if x1 <= x0 or y1 <= y0:
        return
    arr[y0:y1, x0:x1] = arr[y0:y1, x0:x1] * (1 - a) + np.array(color) * a


def latx(part, xo, z, w):
    a = G.keywidth(part, z)
    t = asin(max(-1.0, min(1.0, xo / a)))
    return (0.5 + t / (2 * pi)) * w


def dashes(d, x0, y0, x1, y1, color, on=2, off=2):
    L = max(abs(x1 - x0), abs(y1 - y0))
    i = 0
    while i < L:
        t0, t1 = i / L, min(L, i + on) / L
        d.line([x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0, x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1], fill=tuple(int(c) for c in color))
        i += on + off


def C(c):
    return tuple(int(x) for x in c)


def scuffs(arr, seed, n, color, a=0.25, size=(2, 7)):
    rng = np.random.default_rng(seed)
    h, w, _ = arr.shape
    for _ in range(n):
        x, y = rng.integers(0, w), rng.integers(0, h)
        blend_rect(arr, x, y, x + rng.integers(1, 4), y + rng.integers(size[0], size[1]), color, a)


# ---------------------------------------------------------------- pecas
def p_torso(P):
    t = P["torso"]
    w, h = G.SIZES["torso"]
    r = lambda z: G.keyrow(t, z)
    A = base(w, h, COAT, 11, 13)
    A = shade_u(A, 0.12)
    # realce nos ombros e escurecimento no fundo (agua/barro)
    v = (np.arange(h) + .5) / h
    A *= (1.10 - 0.42 * np.clip((v - 0.55) / 0.45, 0, 1) ** 1.3)[:, None, None]
    # dobras verticais
    rng = np.random.default_rng(5)
    for _ in range(16):
        x = int(rng.integers(0, w)); y0 = int(rng.integers(int(r(1.46)), int(r(1.1)))); ln = int(rng.integers(8, 26))
        blend_rect(A, x, y0, x + 1, y0 + ln, COAT_D, 0.55)
        blend_rect(A, x + 1, y0 + 2, x + 2, y0 + ln - 2, COAT_L, 0.25)
    # dobras de cintura
    for _ in range(14):
        x = int(rng.integers(0, w)); y = int(r(1.09)) + int(rng.integers(-9, -1))
        blend_rect(A, x, y, x + int(rng.integers(4, 9)), y + 1, COAT_D, 0.6)
    scuffs(A, 3, 18, COAT_L, 0.22)
    scuffs(A, 4, 10, np.array([122, 69, 33.0]), 0.35, (1, 3))   # ferrugem
    im = toim(A); d = ImageDraw.Draw(im)
    cx = w / 2
    # gola
    d.rectangle([0, int(r(1.585)), w, int(r(1.545))], fill=C(COAT_D))
    d.line([0, int(r(1.545)), w, int(r(1.545))], fill=C(COAT_L))
    d.line([0, int(r(1.52)), w, int(r(1.52))], fill=C(COAT_D))
    # abertura central + botoes
    d.line([cx, int(r(1.545)), cx, int(r(.80))], fill=C(COAT_D))
    d.line([cx + 1, int(r(1.545)) + 2, cx + 1, int(r(.80)) - 1], fill=C(COAT_L))
    for z in (1.43, 1.34, 1.25, 1.17, .98, .89):
        y = int(r(z))
        d.rectangle([cx - 1, y - 1, cx + 1, y], fill=(48, 34, 24))
        d.point([cx - 1, y - 1], fill=C(GLOVE_L))
    # cinto + fivela
    yb = int(r(1.12)); yb2 = int(r(1.075))
    d.rectangle([0, yb, w, yb2], fill=(52, 36, 24))
    d.line([0, yb, w, yb], fill=(104, 74, 44)); d.line([0, yb2, w, yb2], fill=(28, 20, 14))
    d.rectangle([cx - 5, yb - 1, cx + 5, yb2 + 1], fill=C(BRASS))
    d.rectangle([cx - 3, yb + 1, cx + 3, yb2 - 1 if yb2 - 1 > yb + 1 else yb + 1], fill=(52, 36, 24))
    d.line([cx, yb, cx, yb2 + 1], fill=(120, 92, 50))
    d.line([cx - 5, yb2 + 1, cx + 5, yb2 + 1], fill=(120, 92, 50))
    # bolsos com aba
    for sgn in (-1, 1):
        x0 = latx(t, sgn * 0.065, .95, w); x1 = latx(t, sgn * 0.165, .95, w)
        x0, x1 = min(x0, x1), max(x0, x1)
        y0, y1 = int(r(.99)), int(r(.905))
        d.rectangle([x0, y0, x1, y1], fill=C(COAT * 1.08))
        d.line([x0, y1, x1, y1], fill=C(COAT_D)); d.line([x0, y1 + 1, x1, y1 + 1], fill=C(COAT_D * 0.8))
        d.line([x0, y0, x1, y0], fill=C(COAT_L * 0.8))
        dashes(d, x0 + 1, y0 + 1, x1 - 1, y0 + 1, (160, 178, 150), 2, 2)
        d.rectangle([(x0 + x1) / 2 - 1, y1 - 1, (x0 + x1) / 2 + 1, y1 + 1], fill=(48, 34, 24))
    # bolso do peito (esquerda do personagem = +X)
    x0 = latx(t, .07, 1.33, w); x1 = latx(t, .15, 1.33, w); y0, y1 = int(r(1.37)), int(r(1.30))
    d.rectangle([x0, y0, x1, y1], fill=C(COAT * 1.06)); d.line([x0, y1, x1, y1], fill=C(COAT_D))
    dashes(d, x0 + 1, y0 + 1, x1 - 1, y0 + 1, (160, 178, 150), 2, 2)
    # costuras laterais e dos ombros
    for u in (0.25, 0.75):
        dashes(d, u * w, int(r(1.43)), u * w, int(r(.82)), (152, 170, 144), 2, 2)
    dashes(d, 0, int(r(1.41)), w, int(r(1.41)), (150, 168, 142), 2, 3)
    d.line([0, int(r(1.46)), w, int(r(1.46))], fill=C(COAT_D * 1.05))
    dashes(d, 1, int(r(1.45)), 1, int(r(.82)), (150, 168, 142), 2, 2)
    dashes(d, w - 2, int(r(1.45)), w - 2, int(r(.82)), (150, 168, 142), 2, 2)
    # bainha
    yh = int(r(.80))
    d.line([0, yh, w, yh], fill=C(COAT_D * 0.8)); dashes(d, 0, yh - 1, w, yh - 1, (150, 168, 142), 2, 2)
    # manchas de agua escura perto da bainha
    A = np.array(im).astype(float)
    for _ in range(9):
        x = int(rng.integers(0, w)); y = int(r(.80)) - int(rng.integers(2, 14))
        blend_rect(A, x, y, x + int(rng.integers(3, 9)), y + int(rng.integers(3, 10)), (28, 36, 33), 0.32)
    return np.array(toim(A))


def p_sleeve(P, which):
    pt = P[which]
    w, h = G.SIZES[which]
    r = lambda y: G.keyrow(pt, y)
    A = base(w, h, COAT, 21 if which == "uparm" else 31, 12)
    A = shade_u(A, 0.14)
    rng = np.random.default_rng(8)
    for _ in range(10):
        x = int(rng.integers(0, w)); y0 = int(rng.integers(2, h - 12)); ln = int(rng.integers(6, 16))
        blend_rect(A, x, y0, x + 1, y0 + ln, COAT_D, 0.55); blend_rect(A, x + 1, y0 + 1, x + 2, y0 + ln - 1, COAT_L, 0.22)
    scuffs(A, 9, 8, COAT_L, 0.2)
    im = toim(A); d = ImageDraw.Draw(im)
    if which == "uparm":
        blend = np.array(im).astype(float)
        blend_rect(blend, 0, 0, w, 6, COAT_L, 0.22)          # realce no ombro
        blend_rect(blend, 0, int(r(-.07)), w, h, COAT_D, 0.15)
        im = toim(blend); d = ImageDraw.Draw(im)
        for dy in (-.07, -.045, -.02):                       # dobras do cotovelo
            y = int(r(dy))
            for x in range(0, w, 11):
                d.line([x, y, x + 6, y + 1], fill=C(COAT_D))
        dashes(d, 0, int(r(-.29)), w, int(r(-.29)), (150, 168, 142), 2, 2)   # costura do ombro
        dashes(d, 1, 3, 1, h - 3, (150, 168, 142), 2, 2); dashes(d, w - 2, 3, w - 2, h - 3, (150, 168, 142), 2, 2)
    else:
        for dy in (-.255, -.235, -.215):                    # dobras do cotovelo
            y = int(r(dy))
            for x in range(3, w, 12):
                d.line([x, y, x + 6, y + 1], fill=C(COAT_D))
        # punho com ribana
        y0, y1 = int(r(-.03)), h
        d.rectangle([0, y0, w, y1], fill=C(COAT_D * 1.1))
        for x in range(0, w, 3):
            d.line([x, y0 + 1, x, y1], fill=C(COAT_D * 0.78))
        d.line([0, y0, w, y0], fill=C(COAT_L * 0.8)); d.line([0, y0 - 1, w, y0 - 1], fill=C(COAT_D * 0.7))
        dashes(d, 0, y0 - 3, w, y0 - 3, (150, 168, 142), 2, 2)
        dashes(d, 1, 3, 1, h - 6, (150, 168, 142), 2, 2); dashes(d, w - 2, 3, w - 2, h - 6, (150, 168, 142), 2, 2)
        blend = np.array(im).astype(float)
        blend_rect(blend, 0, int(r(-.14)), w, int(r(-.04)), COAT_D, 0.16)  # sujo no antebraco baixo
        im = toim(blend)
    return np.array(im)


def p_hand(P):
    pt = P["hand"]
    w, h = G.SIZES["hand"]
    r = lambda y: G.keyrow(pt, y)
    A = base(w, h, GLOVE, 41, 13, (2, 5))
    A = shade_u(A, 0.20)
    # palma (costura u=0): mais escura e suja
    u = (np.arange(w) + .5) / w
    palm = np.clip(1 - np.abs(((u + 0.5) % 1.0) - 0.5) * 6, 0, 1)   # 1 no u=0
    A = A * (1 - 0.28 * palm)[None, :, None]
    scuffs(A, 6, 16, GLOVE_L, 0.28, (1, 4))
    im = toim(A); d = ImageDraw.Draw(im)
    yg = int(r(.02))
    # gauntlet: faixa superior mais escura com tira e fivela
    blend = np.array(im).astype(float)
    blend_rect(blend, 0, 0, w, yg, GLOVE_D, 0.55)
    im = toim(blend); d = ImageDraw.Draw(im)
    d.line([0, yg, w, yg], fill=C(GLOVE_D * 0.7))
    d.line([0, yg - 1, w, yg - 1], fill=C(GLOVE_L * 0.8))
    ys = int(r(-.005))
    d.rectangle([0, ys, w, ys + 2], fill=(52, 34, 22)); d.line([0, ys, w, ys], fill=C(GLOVE_L * 0.7))
    bx = w / 2
    d.rectangle([bx - 3, ys - 1, bx + 3, ys + 3], fill=C(BRASS)); d.rectangle([bx - 1, ys, bx + 1, ys + 2], fill=(52, 34, 22))
    dashes(d, 0, 1, w, 1, (200, 160, 100), 2, 2)
    # tendoes no dorso (tres linhas ate os nos dos dedos) e costura central
    y0, y1 = int(r(.025)), int(r(.093))
    for xo in (-.024, -.008, .008, .024):
        x = latx(pt, xo, .06, w)
        dashes(d, x, y0, x + xo * 20, y1, C(GLOVE_D * 0.85), 3, 1)
    dashes(d, bx, y0, bx, y1, (196, 160, 104), 2, 2)
    # nos dos dedos (realces) e borda da mao
    for xo in (-.032, -.011, .011, .032):
        x = latx(pt, xo, .093, w)
        d.rectangle([x - 2, y1 - 1, x + 2, y1 + 1], fill=C(GLOVE_L))
    d.line([0, h - 1, w, h - 1], fill=C(GLOVE_D * 0.8))
    # remendo no dorso
    px = bx + 7
    d.rectangle([px, int(r(.05)), px + 6, int(r(.07))], fill=C(GLOVE * 0.78)); dashes(d, px, int(r(.05)), px + 6, int(r(.05)), (200, 160, 100), 1, 1)
    return np.array(im)


def p_finger(P, kind, prefix):
    nm = prefix + kind
    w, h = G.SIZES[nm]
    A = base(w, h, GLOVE, 51 + (kind == "dist") + (prefix == "t") * 5, 9, (2, 4))
    # 5 colunas: realce no dorso (x~12), sombra nas laterais e embaixo (costura)
    A = shade_u(A, 0.22)
    u = (np.arange(w) + .5) / w
    pal = np.clip(1 - np.abs(((u + 0.5) % 1.0) - 0.5) * 5, 0, 1)
    A = A * (1 - 0.30 * pal)[None, :, None]
    im = toim(A); d = ImageDraw.Draw(im)
    if kind == "prox":
        d.line([0, 0, w, 0], fill=C(GLOVE_D * 0.7))                       # base
        d.line([0, h - 2, w, h - 2], fill=C(GLOVE_D * 0.8))              # dobra da junta
        d.line([0, h - 1, w, h - 1], fill=C(GLOVE_D * 0.6))
        d.rectangle([w // 2 - 3, 1, w // 2 + 2, 3], fill=C(GLOVE_L))     # no do dedo
    else:
        d.line([0, 0, w, 0], fill=C(GLOVE_D * 0.7))
        d.rectangle([w // 2 - 2, 1, w // 2 + 1, 2], fill=C(GLOVE_L * 0.95))
        blend = np.array(im).astype(float)
        blend_rect(blend, 0, h - 3, w, h, GLOVE_D, 0.55)                  # ponta gasta e suja
        im = toim(blend)
    return np.array(im)


def p_neck(P):
    w, h = G.SIZES["neck"]
    A = base(w, h, SKIN * 0.92, 61, 9)
    A = shade_u(A, 0.18)
    blend_rect(A, 0, 0, w, 3, SKIN_D * 0.8, 0.7)
    blend_rect(A, 0, h - 4, w, h, COAT_D, 0.55)
    # barba rala no pescoco (frente)
    rng = np.random.default_rng(2)
    for _ in range(40):
        x = int(w * (0.5 + rng.normal(0, .13))); y = int(rng.integers(0, 5))
        blend_rect(A, x, y, x + 1, y + 1, GREY, 0.7)
    return np.array(toim(A))


def p_nose(P):
    A = np.zeros((8, 8, 3)) + SKIN
    for y in range(8):
        A[y] = SKIN_L * (1.0 - y * 0.05) if y < 4 else SKIN * (1.0 - (y - 4) * 0.13) + np.array([14, -6, -6.0])
    return np.array(toim(A))


def p_head(P):
    t = P["head"]
    w, h = G.SIZES["head"]
    r = lambda z: G.keyrow(t, z)
    fx = lambda xo, z: latx(t, xo, z, w)
    A = base(w, h, SKIN, 71, 9, (3, 6))
    A = shade_u(A, 0.10)
    u = (np.arange(w) + .5) / w
    # bochechas coradas + sombra sob o maxilar
    cheek = np.exp(-(((u - 0.5) * 7.5) ** 2) * 0.0 - 0)  # placeholder (nao usado)
    rng = np.random.default_rng(14)
    zt = lambda z: int(r(z))
    # ----- cabelo grisalho nas laterais/atras (abaixo da touca) e barba
    hair_mask = np.zeros((h, w), bool)
    beard_mask = np.zeros((h, w), bool)
    nz = noise(w, h, 3, 90, True)
    for y in range(h):
        # z aproximado da linha
        zz = np.interp(y / h, [k[1] for k in t.keys], [k[0] for k in t.keys][::1]) if False else None
    ks = np.array(t.keys)   # (z, v) com z decrescente
    zrow = np.interp((np.arange(h) + .5) / h, ks[:, 1], ks[:, 0])
    for x in range(w):
        lat = abs(((x + .5) / w) - 0.5)       # 0 frente, .5 atras
        for y in range(h):
            z = zrow[y]
            if lat > 0.30 and z > 1.625:      # costeletas, atras e nuca
                hair_mask[y, x] = True
            if lat > 0.38 and z < 1.625:
                hair_mask[y, x] = z > 1.60 - 0.02 * nz[y, x] and lat > 0.42
            top = 1.662 + 0.012 * (nz[y, x] - .5) * 2 + (0.045 * min(1.0, (lat - 0.20) / 0.1) if lat > 0.2 else 0.0)
            if z < top and lat < 0.36:
                beard_mask[y, x] = True
    A[hair_mask] = A[hair_mask] * 0 + (np.array([112, 110, 104.0]) + (nz[hair_mask][:, None] - .5) * 40)
    bm = beard_mask & ~hair_mask
    A[bm] = np.array([140, 138, 130.0]) + (nz[bm][:, None] - .5) * 52
    # tufos escuros na barba
    for _ in range(120):
        x, y = int(rng.integers(0, w)), int(rng.integers(0, h))
        if beard_mask[y, x]:
            A[y, x] = (72, 70, 66) if rng.random() < .5 else (186, 184, 172)
    im = toim(A); d = ImageDraw.Draw(im)
    # ----- testa: sulcos
    for z in (1.738, 1.728):
        for sg in (-1, 1):
            dashes(d, fx(sg * .012, z), zt(z), fx(sg * .05, z), zt(z) + (0 if z > 1.73 else 1), C(SKIN_D * 0.85), 3, 2)
    # ----- olhos / sobrancelhas / rugas
    ze, zb = 1.690, 1.708
    for sg in (-1, 1):
        xc = fx(sg * .036, ze)
        y = zt(ze)
        d.rectangle([xc - 3, y - 1, xc + 3, y + 1], fill=(205, 192, 164))      # esclera suja
        d.rectangle([xc - 1 + (1 if sg > 0 else 0) * 0, y - 1, xc, y + 1], fill=(44, 52, 54))   # iris
        d.line([xc - 4, y - 1, xc + 4, y - 1], fill=(48, 34, 28))              # palpebra superior
        d.line([xc - 3, y + 2, xc + 3, y + 2], fill=C(SKIN_D * 0.95))         # bolsa
        d.point([xc - 4 * sg, y], fill=C(SKIN_D * 0.8))                       # pe de galinha
        d.line([xc - 5 * sg, y - 1, xc - 7 * sg, y - 2], fill=C(SKIN_D * 0.8))
        yb = zt(zb)
        d.rectangle([xc - 4 + (3 if sg < 0 else 0) * 0, yb - 1, xc + 4, yb], fill=(88, 86, 80))   # sobrancelha grisalha
        d.point([xc + 4 * (-sg), yb + 1], fill=(88, 86, 80))
        d.line([xc - 2, yb - 3, xc + 2, yb - 3], fill=C(SKIN_D * 0.9))
    # glabela sombreada / dorso do nariz
    d.line([fx(0, 1.70), zt(1.705), fx(0, 1.70), zt(1.675)], fill=C(SKIN_D * 0.95))
    # sulcos nasolabiais e sombra lateral do nariz
    for sg in (-1, 1):
        d.line([fx(sg * .022, 1.665), zt(1.665), fx(sg * .034, 1.64), zt(1.64)], fill=C(SKIN_D * 0.85))
    # bigode e boca
    ym = zt(1.634)
    x0, x1 = fx(-.032, 1.64), fx(.032, 1.64)
    d.rectangle([x0, zt(1.648), x1, zt(1.636)], fill=(150, 148, 140))
    for _ in range(14):
        d.point([rng.integers(int(x0), int(x1)), rng.integers(zt(1.648), zt(1.636))], fill=(84, 82, 78))
    d.line([fx(-.019, 1.63), ym + 1, fx(.019, 1.63), ym + 1], fill=(66, 36, 32))   # boca
    d.line([fx(-.014, 1.63), ym + 2, fx(.014, 1.63), ym + 2], fill=(128, 84, 72))  # labio inferior
    # orelhas (laterais) em pele
    for sg in (-1, 1):
        xe = fx(sg * .0865, 1.69)
        d.rectangle([xe - 2, zt(1.704), xe + 2, zt(1.668)], fill=C(SKIN * 1.04))
        d.line([xe - 2, zt(1.668), xe + 2, zt(1.668)], fill=C(SKIN_D))
        d.point([xe, zt(1.69)], fill=C(SKIN_D * 0.8))
    return np.array(im)


def p_hat(P):
    t = P["hat"]
    w, h = G.SIZES["hat"]
    r = lambda z: G.keyrow(t, z)
    WOOL = np.array([54, 72, 78.0])
    A = base(w, h, WOOL, 81, 10, (2, 4))
    A = shade_u(A, 0.10)
    im = toim(A); d = ImageDraw.Draw(im)
    # malha: colunas de ribana
    A = np.array(im).astype(float)
    for x in range(0, w, 2):
        A[:, x] *= 0.86
    # aba dobrada (z < 1.752): mais clara
    yc = int(r(1.752))
    for y in range(yc, h):
        A[y] = A[y] * 1.12 + 6
        if (y - yc) % 2 == 1:
            A[y] *= 0.84
    A[yc - 1:yc + 1] *= 0.6
    # listra amarelada gasta no gorro
    ys = int(r(1.790))
    A[ys:ys + 2] = A[ys:ys + 2] * 0.3 + np.array([170, 142, 80.0]) * 0.7
    nz = noise(w, h, 2, 5)
    A += (nz[:, :, None] - .5) * 18
    # fiapos / remendos
    scuffs(A, 33, 18, np.array([150, 160, 150.0]), 0.25, (1, 3))
    return np.array(toim(A))


def p_pants(P, which):
    pt = P[which]
    w, h = G.SIZES[which]
    r = lambda z: G.keyrow(pt, z)
    A = base(w, h, PANTS, 91 + (which == "shin"), 9, (3, 6))
    A = shade_u(A, 0.16)
    rng = np.random.default_rng(12 if which == "thigh" else 13)
    for _ in range(14):
        x = int(rng.integers(0, w)); y0 = int(rng.integers(0, h - 10)); ln = int(rng.integers(5, 14))
        blend_rect(A, x, y0, x + 1, y0 + ln, (18, 24, 24), 0.6); blend_rect(A, x + 1, y0 + 1, x + 2, y0 + ln, (76, 88, 84), 0.3)
    scuffs(A, 7, 14, (82, 94, 90), 0.25)
    im = toim(A); d = ImageDraw.Draw(im)
    if which == "thigh":
        yk = int(r(.52))
        for dz in (0, 2, 4):    # dobras do joelho
            for x in range(0, w, 13):
                d.line([x, yk + dz, x + 7, yk + dz + 1], fill=(20, 26, 26))
        dashes(d, 1, 0, 1, h, (86, 98, 94), 2, 3); dashes(d, w - 2, 0, w - 2, h, (86, 98, 94), 2, 3)
        # bolsos traseiros: costura
        dashes(d, 5, int(r(.90)), 25, int(r(.90)), (86, 98, 94), 2, 2)
    else:
        # barra dobrada e barro
        yh = int(r(.17))
        d.line([0, yh, w, yh], fill=(20, 26, 26)); dashes(d, 0, yh + 1, w, yh + 1, (86, 98, 94), 2, 2)
        blend = np.array(im).astype(float)
        blend_rect(blend, 0, int(r(.20)), w, h, (92, 74, 56), 0.22)
        for _ in range(16):
            x = int(rng.integers(0, w)); y = int(rng.integers(int(r(.24)), h - 1))
            blend_rect(blend, x, y, x + int(rng.integers(1, 4)), y + int(rng.integers(1, 3)), (96, 70, 46), 0.55)
        im = toim(blend); d = ImageDraw.Draw(im)
        dashes(d, 1, 0, 1, h - 6, (86, 98, 94), 2, 3); dashes(d, w - 2, 0, w - 2, h - 6, (86, 98, 94), 2, 3)
    return np.array(im)


def p_boot(P, which):
    pt = P[which]
    w, h = G.SIZES[which]
    r = lambda k: G.keyrow(pt, k)
    A = base(w, h, LEATHER_D * 1.1, 101 + (which == "foot"), 10, (2, 5))
    A = shade_u(A, 0.20)
    scuffs(A, 15, 22, LEATHER * 1.35, 0.30, (1, 3))
    scuffs(A, 16, 12, (26, 18, 12), 0.4, (1, 3))
    u = (np.arange(w) + .5) / w
    im = toim(A); d = ImageDraw.Draw(im)
    if which == "shaft":
        d.line([0, 0, w, 0], fill=(28, 20, 14)); d.line([0, 1, w, 1], fill=C(LEATHER * 1.3))
        ys = int(r(.14)); d.rectangle([0, ys, w, ys + 2], fill=(34, 24, 16)); d.line([0, ys, w, ys], fill=C(LEATHER * 1.2))
        bx = w / 2; d.rectangle([bx - 3, ys - 1, bx + 3, ys + 3], fill=C(BRASS * 0.85)); d.rectangle([bx - 1, ys, bx + 1, ys + 2], fill=(34, 24, 16))
        # cadarco ate em cima
        for y in range(3, ys - 1, 3):
            d.line([bx - 4, y, bx + 4, y + 1], fill=(172, 150, 98)); d.line([bx + 4, y, bx - 4, y + 1], fill=(172, 150, 98))
        dashes(d, 0, h - 1, w, h - 1, (28, 20, 14), 1, 0)
    else:
        # sola preta embaixo (costura em u=0) e palmilha
        A2 = np.array(im).astype(float)
        sole = ((u < 0.10) | (u > 0.90))
        A2[:, sole] = A2[:, sole] * 0.12 + np.array([22, 18, 14.0]) * 0.88
        edge = ((u >= .10) & (u < .14)) | ((u > .86) & (u <= .90))
        A2[:, edge] = A2[:, edge] * 0.5 + np.array([120, 100, 70.0]) * 0.5
        # bico gasto, calcanhar escuro
        blend_rect(A2, 0, int(r(-.16)), w, h, LEATHER * 1.35, 0.22)
        blend_rect(A2, 0, 0, w, 4, (20, 14, 10), 0.4)
        im = toim(A2); d = ImageDraw.Draw(im)
        bx = w / 2
        # cadarcos no peito do pe
        for y in range(int(r(.04)), int(r(-.09)), 3):
            d.line([bx - 5, y, bx + 5, y + 1], fill=(172, 150, 98)); d.line([bx + 5, y, bx - 5, y + 1], fill=(172, 150, 98))
        d.line([bx - 5, int(r(.04)), bx - 5, int(r(-.09))], fill=(30, 22, 16)); d.line([bx + 5, int(r(.04)), bx + 5, int(r(-.09))], fill=(30, 22, 16))
        d.line([0, int(r(-.12)), w, int(r(-.12))], fill=(30, 22, 16))        # biqueira
        dashes(d, 0, int(r(-.115)), w, int(r(-.115)), (120, 96, 60), 2, 2)
    return np.array(im)


def paint_atlas(P):
    atlas = np.zeros((G.ATLAS, G.ATLAS, 3), np.uint8)
    atlas[:] = (40, 46, 44)
    jobs = {
        "head": p_head, "torso": p_torso, "hat": p_hat, "neck": p_neck, "nose": p_nose,
        "uparm": lambda P: p_sleeve(P, "uparm"), "forearm": lambda P: p_sleeve(P, "forearm"), "hand": p_hand,
        "fprox": lambda P: p_finger(P, "prox", "f"), "fdist": lambda P: p_finger(P, "dist", "f"),
        "tprox": lambda P: p_finger(P, "prox", "t"), "tdist": lambda P: p_finger(P, "dist", "t"),
        "thigh": lambda P: p_pants(P, "thigh"), "shin": lambda P: p_pants(P, "shin"),
        "shaft": lambda P: p_boot(P, "shaft"), "foot": lambda P: p_boot(P, "foot"),
    }
    for k, fn in jobs.items():
        x, y, w, h = G.RECTS[k]
        tile = fn(P)
        assert tile.shape[:2] == (h, w), (k, tile.shape)
        atlas[y:y + h, x:x + w] = tile
    im = Image.fromarray(atlas)
    # suja global (sombreamento pintado leve) e paleta reduzida estilo PS1
    return im.quantize(colors=96, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
