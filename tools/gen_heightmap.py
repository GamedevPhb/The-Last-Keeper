"""Gera o heightmap da ilha organica (grade 1 m) a partir do campo de tools/mapa_organico.py,
com platos planos em y=0 sob as estruturas do jogo. Saida: tools/terrain_height.f32 (RGBA float32,
151 x 181) que tools/pack_heightmap.gd converte em res://world/terrain_height.res.
Canais: R altura (m), G areia, B mata, A terra batida.  Uso: python3 tools/gen_heightmap.py [preview.png]"""
import math, sys
import numpy as np

PPM = 4
X0, X1, Z0, Z1 = -92, 88, -82, 68
W, H = (X1 - X0) * PPM + 1, (Z1 - Z0) * PPM + 1
xs = X0 + np.arange(W) / PPM
zs = Z0 + np.arange(H) / PPM
X, Z = np.meshgrid(xs, zs)
SEA = -1.2


def smooth(a, b, v):
    t = np.clip((v - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def lattice_noise(scale_m, seed):
    r = np.random.default_rng(seed)
    gw, gh = int((X1 - X0) / scale_m) + 3, int((Z1 - Z0) / scale_m) + 3
    g = r.random((gh, gw))
    u = (X - X0) / scale_m; v = (Z - Z0) / scale_m
    i, j = u.astype(int), v.astype(int); fu, fv = u - i, v - j
    fu = fu * fu * (3 - 2 * fu); fv = fv * fv * (3 - 2 * fv)
    a = g[j, i] * (1 - fu) + g[j, i + 1] * fu
    b = g[j + 1, i] * (1 - fu) + g[j + 1, i + 1] * fu
    return a * (1 - fv) + b * fv


def fbm(scale_m, seed, octaves=5):
    t, amp, tot = 0, 1.0, 0
    for o in range(octaves):
        t = t + amp * lattice_noise(scale_m / (2 ** o), seed + o * 17); tot += amp; amp *= .5
    return t / tot


def blur(a, sigma_px):
    ky = np.fft.fftfreq(a.shape[0])[:, None]; kx = np.fft.fftfreq(a.shape[1])[None, :]
    k = np.exp(-2 * (math.pi * sigma_px) ** 2 * (kx ** 2 + ky ** 2))
    return np.real(np.fft.ifft2(np.fft.fft2(a) * k))


def g2(cx, cz, sx, sz, rot=0.0):
    c, s = math.cos(rot), math.sin(rot)
    dx, dz = X - cx, Z - cz
    u, v = dx * c + dz * s, -dx * s + dz * c
    return np.exp(-(u * u / (2 * sx * sx) + v * v / (2 * sz * sz)))


# ---------- distancias ----------
def d_circle(cx, cz): return np.hypot(X - cx, Z - cz)
def d_rect(x0, x1, z0, z1):
    return np.hypot(np.maximum(np.maximum(x0 - X, X - x1), 0), np.maximum(np.maximum(z0 - Z, Z - z1), 0))
def d_seg(ax, az, bx, bz):
    abx, abz = bx - ax, bz - az
    t = np.clip(((X - ax) * abx + (Z - az) * abz) / (abx * abx + abz * abz), 0, 1)
    return np.hypot(X - (ax + abx * t), Z - (az + abz * t))


# ---------- platos (todos em y = target; default 0) ----------
# (nome, distancia, r_plano, r_transicao, target, tipo)  tipo: 'p' plato, 'path' corredor de trilha
PADS = []
def pad(name, dist, flat, blend, target=0.0, kind='p'): PADS.append((name, dist, flat, blend, target, kind))

pad('farol', d_circle(0, -12), 12.0, 9.0)
pad('casa', d_rect(24.45, 30.05, 4.95, 9.55), 4.0, 6.0)
pad('galpao', d_rect(-21.45, -17.85, 12.9, 16.5), 4.0, 6.0)
pad('oficina', d_circle(-27, 8), 4.0, 6.0)
pad('fabrica_oleo', d_circle(-12, 21.5), 5.0, 5.0)
pad('fabrica_comb', d_circle(-8.5, 21.5), 5.0, 5.0)
pad('horta', d_rect(30.8, 35.6, -6.2, 0.2), 2.5, 5.0)
pad('estacao_horta', d_circle(22, 18), 3.5, 5.0)
pad('base_pier', d_rect(-3.0, 4.0, 27.0, 36.0), 0.0, 2.5)
pad('cemiterio', d_rect(-18.0, -8.0, -28.5, -21.5), 3.0, 5.0)
# trilhas da ilha (eixos L de island_details)
for nm, a, b in (('t7', (1.9, -13.55), (5.8, -13.55)), ('t6', (5, -14.35), (5, 20.8)), ('t0', (0, 19.2), (0, 37.8)),
                 ('t1', (-0.8, 20), (28.05, 20)), ('t2', (27.25, 9.2), (27.25, 20.8)), ('t3', (-14.8, 20), (0.8, 20)),
                 ('t4', (-14, 13.9), (-14, 20.8)), ('t5', (-18.2, 14.7), (-13.2, 14.7))):
    pad(nm, d_seg(a[0], a[1], b[0], b[1]), 1.9, 4.0, 0.0, 'path')
# trilha do oeste (expansion) e acessos
W_TRAIL = [(-12, -10), (-24, -8), (-35, -4), (-45, -6), (-53, -9), (-57.5, -11.5), (-60, -17), (-67, -19)]
for i in range(len(W_TRAIL) - 1):
    pad('wt%d' % i, d_seg(*W_TRAIL[i], *W_TRAIL[i + 1]), 1.9, 4.0, 0.0, 'path')
pad('cabana', d_rect(-65.2, -58.8, -14.7, -9.3), 4.0, 5.0)
pad('torre_vigia', d_circle(-67, -19), 4.5, 5.0)
# passagem norte pela faixa alta (garganta)
pad('pass_norte', d_seg(0, -22, -2, -46), 2.4, 5.0, 0.0, 'path')
# costa norte (pier de pesca, destrocos, algas)
pad('norte', d_rect(-26, 16, -57, -45), 2.0, 5.0)
pad('norte_praia', d_rect(-22, 14, -60.5, -57), 0.0, 3.5, -0.4)
pad('acesso_gruta', d_seg(14, -52, 24, -56), 3.0, 5.0)
pad('gruta', d_rect(24, 38, -69, -55), 1.0, 4.0)
# praias onde os invasores chegam (y = 0 hardcoded nos scripts)
for i, (bx, bz) in enumerate(((-14, 33), (10, 30), (-5, 37), (18, 25), (-22, 28))):
    pad('praia%d' % i, d_circle(bx, bz), 2.6, 3.0)
pad('praia5', d_circle(3, 41), 1.1, 2.4)
# postes da rede eletrica (fios a y fixo)
for i, (px, pz) in enumerate(((-17.5, 17.8), (-9, 8), (-3.5, -3), (9, -1), (19, 3.5))):
    pad('poste%d' % i, d_circle(px, pz), 1.5, 4.0)
# pontas da passagem de mare
pad('mare_a', d_circle(28.3, 24.6), 1.2, 2.0, 0.0)
pad('mare_b', d_circle(45.2, 39.0), 1.2, 2.0, 0.0)
pad('mare_leste', d_circle(36.0, -1.2), 2.0, 3.0, 0.0)

Pall = np.zeros_like(X)
for nm, dist, flat, blend, tgt, kind in PADS:
    Pall = 1 - (1 - Pall) * (1 - (1 - smooth(flat, flat + blend, dist)))

# nucleo (relevo suave): perto de tudo que o jogo usa
core = np.zeros_like(X)
CORE_R0, CORE_R1 = 2.0, 8.0
for nm, dist, flat, blend, tgt, kind in PADS:
    core = np.maximum(core, 1 - smooth(flat + CORE_R0, flat + CORE_R1, dist))
for cx, cz, r in ((0, -12, 8), (-60, -14, 4), (51, 42, 2)):
    core = np.maximum(core, 1 - smooth(r + 2, r + 12, d_circle(cx, cz)))

# ---------- campo da ilha ----------
field = (1.00 * g2(2, 2, 27, 24) + 0.95 * g2(-56, -6, 22, 29, 0.25) + 0.80 * g2(-2, -50, 26, 7.5, 0.05)
         + 0.60 * g2(32, -60, 10, 8) + 0.78 * g2(31, -70, 11, 5.5) + 0.55 * g2(2, -30, 8, 13) + 0.75 * g2(22, -26, 9, 10) + 0.5 * g2(12, -38, 8, 7)
         + 0.6 * g2(11, 40, 5, 5) + 0.6 * g2(-9, 42, 5, 5)
         + 0.45 * g2(18, 30, 8, 9) + 0.85 * g2(50, 42, 7.0, 6.0) + 0.50 * g2(-26, 40, 6, 5))
bay = 1.7 * g2(-0.5, 45.0, 6.5, 7.0) + 0.30 * g2(-14, 46, 6, 6) + 0.35 * g2(41, 14, 6, 6) + 0.7 * g2(-41, 27, 7, 7)
warp = fbm(34, 3) - .5
warp2 = fbm(12, 9) - .5
f = field - bay + 0.26 * warp + 0.08 * warp2
f = f + 0.8 * blur(Pall, 10)                      # garante terra sob os platos
COAST = 0.46
d = f - COAST

# ---------- relevo ----------
hills = (5.5 * g2(-50, 17, 9, 7) + 6.0 * g2(-76, 4, 7, 10) + 5.5 * g2(-58, -36, 11, 7) + 5.0 * g2(-79, -24, 6, 8)
         + 4.5 * g2(2, -37, 24, 5.5) + 3.2 * g2(-30, -37, 8, 6) + 3.0 * g2(26, -34, 8, 5)
         + 14.0 * g2(31, -71, 9, 3.6) + 11.0 * g2(44, -61, 5, 8) + 7.0 * g2(20, -66, 5, 5)
         + 3.2 * g2(28, 34, 7, 4) + 2.2 * g2(-38, 36, 6, 5) + 1.2 * g2(50, 42, 4, 3.5))
noise = (fbm(15, 70) - .5) * 2
ridge = np.abs(fbm(22, 40) - .5) * 2
free = 1 - core
inner = noise * (1.3 + 1.3 * free) + hills + 1.5 * (1 - ridge) * free * smooth(0.1, 0.25, d)
inner = np.maximum(inner, -0.8)
sbeach = smooth(0.0, 0.085, d)
h_land = SEA + (-SEA + inner) * sbeach
h_sea = SEA - 3.2 * smooth(0.0, 0.22, -d)
h = np.where(d > 0, h_land, h_sea)
h = blur(h, 1.5)
# platos
for nm, dist, flat, blend, tgt, kind in PADS:
    p = 1 - smooth(flat, flat + blend, dist)
    h = h * (1 - p) + tgt * p

# ---------- canais de cor ----------
sand = (1 - smooth(0.05, 0.17, d)) * (h < 0.7)
sand = np.clip(sand, 0, 1)
dens = fbm(9, 21) * 0.6 + fbm(26, 22) * 0.6
west = np.clip(1.15 - np.hypot(X + 52, (Z + 6) * .8) / 36, 0, 1)
fd = np.clip(dens + 0.55 * west - 0.65 + 0.3 * free, 0, 1)
forest = np.clip((fd - .05) * 5, 0, 1) * (1 - Pall) * smooth(0.12, 0.22, d)
dirt = np.zeros_like(X)
for nm, dist, flat, blend, tgt, kind in PADS:
    if kind == 'path':
        dirt = np.maximum(dirt, 1 - smooth(flat - 0.2, flat + 0.8, dist))
    elif nm in ('casa', 'galpao', 'cemiterio', 'horta'):
        dirt = np.maximum(dirt, 0.35 * (1 - smooth(flat, flat + 1.5, dist)))
out = np.stack([h, sand, forest, dirt], -1)[::PPM, ::PPM].astype(np.float32)
out.tofile('tools/terrain_height.f32')
print('grade', out.shape, 'min', out[..., 0].min(), 'max', out[..., 0].max())

# ---------- sondas ----------
def probe(nm, x, z):
    i, j = int(round((x - X0))), int(round((z - Z0)))
    print('%-14s (%6.1f,%6.1f) h=%.2f' % (nm, x, z, out[j, i, 0]))
for nm, x, z in (('spawn', 0.4, 49.8), ('bau', -0.7, 47.2), ('farol', 0, -12), ('porta casa', 27.25, 9.8), ('gerador', -20.4, 14.7),
                 ('oilfab', -12, 21.5), ('fuelfab', -8.5, 21.5), ('pier base', 0.4, 36), ('pier z40', 0.4, 40), ('boat', 3.3, 47.5),
                 ('praia (3,41)', 3, 41), ('praia(-5,37)', -5, 37), ('gruta', 31, -57), ('cabana', -62, -12), ('torre', -67, -19),
                 ('algas', -14, -58.6), ('pesca', 7, -55), ('mare_a', 30, 26), ('mare_b', 43, 38), ('mare L', 39.2, -0.8),
                 ('ilheu', 50, 42), ('horta', 33, -3), ('cemit', -13, -25), ('cume NE', 31, -77), ('oeste', -50, 17), ('ridge', 10, -39),
                 ('wreck', -40, 24), ('ilhota', 51, -2)):
    probe(nm, x, z)
if len(sys.argv) > 1:
    from PIL import Image
    sandc, grass, forest_c, rock, dirtc = (np.array(c, float) for c in [(176, 160, 112), (88, 122, 60), (40, 80, 46), (112, 106, 98), (120, 98, 64)])
    img = np.zeros(h.shape + (3,))
    gz, gx = np.gradient(h, 1 / PPM)
    slope = np.hypot(gx, gz)
    land = h >= SEA
    t = np.clip((SEA - h) / 7, 0, 1)[..., None]
    img[...] = (1 - t) * np.array([40, 120, 130.]) + t * np.array([8, 24, 40.])
    terr = np.where((sand > .5)[..., None], sandc, grass)
    terr = terr * (1 - forest[..., None] * .7) + forest_c * forest[..., None] * .7
    terr = terr * (1 - dirt[..., None] * .6) + dirtc * dirt[..., None] * .6
    rk = np.clip((slope - 0.6) / 0.5, 0, 1) + np.clip((h - 9) / 3, 0, 1)
    terr = terr * (1 - np.clip(rk, 0, 1)[..., None]) + rock * np.clip(rk, 0, 1)[..., None]
    img = np.where(land[..., None], terr, img)
    sh = np.clip(1 + 0.5 * (gx * .55 + gz * .6) / 2, 0.45, 1.5) * (0.85 + 0.03 * np.clip(h, 0, 10))
    img = img * np.where(land, sh, 1)[..., None]
    for lv in (2, 4, 6, 8, 10, 12):
        m = h >= lv
        e = (m ^ np.roll(m, 1, 0)) | (m ^ np.roll(m, 1, 1))
        img[e & land] *= 0.6
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(sys.argv[1])
