"""Gera docs/shots/mapa_ilha_organica.png: proposta de ilha natural (relevo, costa, enseada). Coords do jogo: x leste, z sul."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PPM = 6.0
X0, X1, Z0, Z1 = -92.0, 88.0, -82.0, 68.0
W, H = int((X1 - X0) * PPM), int((Z1 - Z0) * PPM)
rng = np.random.default_rng(11)
xs = X0 + (np.arange(W) + .5) / PPM
zs = Z0 + (np.arange(H) + .5) / PPM
X, Z = np.meshgrid(xs, zs)

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

# ---- campo da ilha (metaballs com contorno deformado) ----
field = (1.00 * g2(2, 2, 27, 24) + 0.95 * g2(-56, -6, 22, 29, 0.25) + 0.80 * g2(-2, -50, 26, 7.5, 0.05)
         + 0.55 * g2(30, -58, 9, 7) + 0.55 * g2(2, -30, 8, 13) + 0.5 * g2(-42, 22, 9, 8)
         + 0.45 * g2(18, 30, 8, 9) + 0.38 * g2(51, -2, 4.2, 4.2) + 0.60 * g2(50, 42, 6.5, 5.5)
         + 0.50 * g2(-26, 40, 6, 5))
bay = 0.55 * g2(9, 44, 8, 8) + 0.30 * g2(-14, 44, 6, 6) + 0.35 * g2(40, 16, 7, 6)   # enseada do píer e baías
warp = fbm(34, 3) - .5
warp2 = fbm(12, 9) - .5
coast = 0.46
f = field - bay + 0.30 * warp + 0.09 * warp2
land = f > coast
d = (f - coast)                                    # ~distância à costa (relativa)

# ---- relevo ----
hills = (13.0 * g2(0, -14, 9, 10) + 7.0 * g2(-60, -10, 9, 10) + 6.5 * g2(-46, 12, 9, 7)
         + 11.0 * g2(31, -61, 7, 5.5) + 5.5 * g2(26, 6, 9, 8, .3) + 4.0 * g2(51, -2, 3, 3) + 3.0 * g2(50, 42, 4, 3.5))
ridge = np.abs(fbm(22, 40) - .5) * 2
h = np.where(land, 0.6 + np.clip(d * 9, 0, 3.6) + hills * (0.55 + 0.9 * np.clip(d * 4, 0, 1)) + 2.2 * (fbm(15, 70) - .5) + 2.6 * (1 - ridge) * np.clip(d * 5, 0, 1), -1.0)
h = blur(h, 2.2)
h = np.where(land, np.maximum(h, 0.15), -1.0 - np.clip(-d * 6, 0, 8))
# falésia norte-nordeste: degrau forte
cliff = g2(31, -58, 12, 8) * (Z < -52)
h = np.where(land, h + 3.5 * cliff * (h > 5), h)
h = blur(np.where(land, h, 0), 1.0) * land + (~land) * h

gz, gx = np.gradient(blur(h, 1.2), 1 / PPM)
slope = np.hypot(gx, gz)
# luz NO
lx, lz, ly = -0.55, -0.6, 0.58
nx, nz, ny = -gx * 0.9, -gz * 0.9, np.ones_like(h)
nn = np.sqrt(nx * nx + nz * nz + ny * ny)
shade = np.clip((nx * lx + nz * lz + ny * ly) / nn, 0, 1)
shade = (shade - 0.45) * 1.6

# ---- cores ----
def lerp(a, b, t): return a + (b - a) * np.clip(t, 0, 1)[..., None]
img = np.zeros((H, W, 3))
sea_d = np.clip(-d * 5.5, 0, 1)
deep, mid, shal, reef = np.array([8, 24, 40.]), np.array([16, 56, 78.]), np.array([34, 112, 120.]), np.array([70, 150, 140.])
sea = lerp(shal, mid, sea_d / 0.5); sea = np.where((sea_d > .5)[..., None], lerp(mid, deep, (sea_d - .5) / .5), sea)
shoal = np.clip(1 - np.abs(d + 0.11) / 0.03, 0, 1) * (fbm(7, 5) > 0.45)             # recifes
sea = lerp(sea, reef, shoal * .8)
img[:] = sea
sand, grass, grass2, forest, rock, dirt = (np.array(c, float) for c in [(176, 160, 112), (88, 122, 60), (70, 104, 52), (38, 78, 44), (112, 106, 98), (120, 98, 64)])
lo = np.clip(h / 8, 0, 1)
terr = lerp(sand, grass, (h - 0.6) / 0.9)
terr = lerp(terr, grass2, (h - 2.0) / 3.0)
dens = fbm(9, 21) * 0.6 + fbm(26, 22) * 0.6
west = np.clip(1.15 - np.hypot(X + 52, (Z + 6) * .8) / 36, 0, 1)
fdens = np.clip(dens + 0.55 * west - 0.65 + 0.15 * np.clip((h - 2) / 4, 0, 1), 0, 1)
fmask = np.clip((fdens - .05) * 5, 0, 1) * (h > 1.8) * (slope < 1.2) * land
terr = lerp(terr, forest, fmask * .95)
terr = lerp(terr, rock, np.clip((slope - 0.75) / 0.6, 0, 1) + np.clip((h - 11) / 4, 0, 1))
terr = lerp(terr, dirt, np.clip(1 - np.hypot(X - 27, Z - 7) / 6, 0, 1) * .4)
img = np.where(land[..., None], terr, img)
sh = np.where(land, shade, 0.5 * (fbm(5, 8) - .5))
img = img * (1 + 0.42 * sh[..., None])
# espuma
foam = np.clip(1 - np.abs(d) / 0.012, 0, 1) * 0.9 + np.clip(1 - np.abs(d + 0.025) / 0.01, 0, 1) * 0.35
img = lerp(img, np.array([226, 238, 232.]), foam * (0.75 + 0.25 * (fbm(4, 31) > .4)))
base = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))

# ---- curvas de nível ----
S = 2
big = base.resize((W * S, H * S), Image.BICUBIC)
dr = ImageDraw.Draw(big, "RGBA")
hs = blur(h, 1.5)
for lvl in (2, 4, 6, 8, 10, 12):
    m = (hs >= lvl)
    edge = m ^ np.roll(m, 1, 0) | m ^ np.roll(m, 1, 1)
    ys, xs_ = np.nonzero(edge & land)
    a = 70 if lvl % 4 else 110
    for y, x in zip(ys[::1], xs_[::1]):
        dr.rectangle([x * S, y * S, x * S + 1, y * S + 1], fill=(30, 40, 30, a))

# ---- árvores ----
tr = np.random.default_rng(5)
cand = np.argwhere(fmask > .35)
tr.shuffle(cand)
placed = 0; pts = []
for (y, x) in cand[:9000]:
    if placed > 2600: break
    p = (x + tr.random(), y + tr.random())
    if any((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 < 15 for q in pts[-40:]): continue
    pts.append(p); placed += 1
pts.sort(key=lambda p: p[1])
for (x, y) in pts:
    r = tr.uniform(3.2, 5.0) * S
    cx, cy = x * S, y * S
    dr.ellipse([cx - r + 1.5, cy - r + 2.5, cx + r + 1.5, cy + r + 2.5], fill=(10, 24, 14, 120))
    g = int(tr.uniform(58, 92))
    dr.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(20, g, 36, 255))
    dr.ellipse([cx - r * .6, cy - r * .75, cx + r * .1, cy - r * .1], fill=(70, g + 50, 60, 150))

# ---- riacho do farol até a enseada ----
def stream(x, z, steps=900):
    pts = []
    hh = blur(h, 3)
    ix, iz = (x - X0) * PPM, (z - Z0) * PPM
    for _ in range(steps):
        i, j = int(ix), int(iz)
        if not (1 < i < W - 2 and 1 < j < H - 2) or not land[j, i]: break
        pts.append((ix * S, iz * S))
        ddx = (hh[j, i + 1] - hh[j, i - 1]); ddz = (hh[j + 1, i] - hh[j - 1, i])
        n = math.hypot(ddx, ddz) + 1e-6
        ix += -ddx / n * 1.0 + (tr.random() - .5) * .3; iz += -ddz / n * 1.0 + (tr.random() - .5) * .3
    return pts
for sx, sz in ((4, -6), (-8, -8)):
    sp = stream(sx, sz)
    if len(sp) > 20: dr.line(sp, fill=(90, 160, 190, 255), width=3 * S // 2 + 1, joint="curve")

def P(x, z): return ((x - X0) * PPM * S, (z - Z0) * PPM * S)
FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"; FR = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
def F(sz, b=False): return ImageFont.truetype(FB if b else FR, int(sz * S))
def tag(x, z, s, sz=13, dy=0, col=(255, 255, 250)):
    px, py = P(x, z); dr.text((px, py + dy * S), s, font=F(sz, True), fill=col, anchor="mm", stroke_width=3 * S // 2, stroke_fill=(14, 22, 28))

# ---- pontos de interesse ----
def sq(x, z, w, h2, col, edge=(25, 20, 15)):
    a, b = P(x - w / 2, z - h2 / 2), P(x + w / 2, z + h2 / 2); dr.rectangle([a, b], fill=col, outline=edge, width=2 * S)
# píer
for i in range(7):
    a, b = P(-2.5 + 9, 36.5 + i * 2.1), P(2.5 + 9, 38.2 + i * 2.1)
    dr.rectangle([a, b], fill=(110, 82, 52), outline=(50, 36, 22), width=S)
# farol
cx, cy = P(0, -12); r = 5 * PPM * S
dr.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(222, 222, 214), outline=(60, 60, 60), width=2 * S)
r = 2.2 * PPM * S; dr.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(240, 190, 60), outline=(120, 80, 20), width=S)
dr.polygon([(cx, cy), P(30, -48), P(36, -38)], fill=(255, 235, 150, 46))
sq(27, 7, 6.5, 5, (150, 96, 72)); sq(-20, 14.5, 4.2, 4.2, (110, 126, 118))
sq(-62, -12, 6, 5, (130, 98, 70)); sq(-12, 21.5, 4.4, 3.6, (214, 160, 60), (110, 70, 20)); sq(-7.5, 21.5, 4.4, 3.6, (150, 130, 120), (110, 70, 20))
sq(7, -54, 8, 2.2, (110, 82, 52)); sq(-27, 8, 3.4, 3, (130, 120, 110))
cx, cy = P(31, -60); r = 2.6 * PPM * S; dr.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=(8, 8, 10))
dr.polygon([P(-52, 41), P(-45, 43), P(-41, 48), P(-49, 47)], fill=(150, 56, 40), outline=(70, 24, 16))
for i in range(5):
    cx, cy = P(38.5 + i * 1.7, -1.8 - i * .1); dr.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(150, 146, 140), outline=(70, 70, 66), width=S)
for i in range(6):
    cx, cy = P(32 + i * 2.2, 29 + i * 1.8); dr.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(150, 146, 140), outline=(70, 70, 66), width=S)
# trilhas
def trail(pts_, col=(214, 190, 140, 230)):
    dr.line([P(*p) for p in pts_], fill=col, width=3 * S, joint="curve")
trail([(0, -9), (1, 4), (6, 20), (9, 40)]); trail([(1, 4), (14, 6), (27, 7)]); trail([(1, 6), (-10, 10), (-20, 14.5)])
trail([(-8, -10), (-22, -8), (-36, -5), (-48, -8), (-57, -11)]); trail([(0, -22), (0, -34), (-2, -46)]); trail([(-2, -46), (14, -52), (30, -56)])

tag(0, -12, "Farol 7", 15, 40); tag(27, 7, "Casa do vigia", 13, 30); tag(-20, 14.5, "Galpão / gerador", 12, -22)
tag(9, 58, "Píer (início)", 13, 0); tag(-62, -12, "Cabana do vigia 6", 12, -24); tag(43, -62, "Gruta", 13, 0)
tag(-46, 53, "Santa Aurora", 11, 0); tag(-58, 16, "Mata do oeste", 17, 0); tag(-24, -53, "Costa norte", 16, 0)
tag(53, -9, "Ilhota da maré", 11, 0); tag(51, 53, "Ilhéu sul", 12, 0); tag(-10, 29, "Fábricas", 11, 0)
tag(0, -26, "Colina do farol  ~14 m", 11, 0, (255, 236, 190)); tag(31, -54, "Penhasco ~13 m", 11, 0, (255, 236, 190))
tag(-3, 32, "Enseada", 12, 0, (190, 235, 255)); tag(-78, 38, "recifes", 11, 0, (190, 235, 255))
tag(-88, -76, "N ↑", 15, 0)
# escala
a, b = P(-86, 62), P(-66, 62); dr.line([a, b], fill=(255, 255, 255), width=3 * S)
dr.text(((a[0] + b[0]) / 2, a[1] - 14 * S), "20 m", font=F(12, True), fill=(255, 255, 255), anchor="mm", stroke_width=S, stroke_fill=(14, 22, 28))

# ---- compor com painel ----
mapimg = big.resize((W, H), Image.LANCZOS)
PANEL = 500
canvas = Image.new("RGB", (W + PANEL, H), (244, 240, 230))
canvas.paste(mapimg, (0, 0))
cd = ImageDraw.Draw(canvas)
def FT(sz, b=False): return ImageFont.truetype(FB if b else FR, sz)
x0 = W + 28
cd.text((x0, 30), "Nova ilha — relevo e costa", font=FT(26, True), fill=(30, 30, 28))
cd.text((x0, 66), "Proposta orgânica (coords do jogo, 6 px/m)", font=FT(15), fill=(100, 100, 96))
y = 110
cd.text((x0, y), "Altura", font=FT(18, True), fill=(40, 40, 36)); y += 30
for name, col in (("Mar fundo", (8, 24, 40)), ("Raso / recife", (60, 140, 140)), ("Praia  0–1 m", (176, 160, 112)), ("Campina  1–4 m", (88, 122, 60)), ("Mata  2–9 m", (38, 78, 44)), ("Rocha / penhasco  9–14 m", (112, 106, 98))):
    cd.rectangle([x0, y, x0 + 26, y + 18], fill=col, outline=(60, 60, 56)); cd.text((x0 + 38, y + 9), name, font=FT(15), fill=(50, 50, 46), anchor="lm"); y += 28
y += 14
cd.text((x0, y), "Como a ilha mudou", font=FT(18, True), fill=(40, 40, 36)); y += 32
for t in ("• Costa irregular: baías, pontas e uma enseada",
          "  abrigando o píer; praias nas orlas.",
          "• Colina do farol (~14 m): o ponto mais alto,",
          "  com riacho descendo até a enseada.",
          "• Penhasco no nordeste, com a gruta no pé.",
          "• Mata densa no oeste, em morros suaves;",
          "  cabana do vigia 6 numa clareira alta.",
          "• Costa norte baixa e ligada por um istmo.",
          "• Ilhota da maré e ilhéu sul por pedras de maré.",
          "• Recifes rasos ao redor; naufrágio nas pedras.",
          "• Trilhas seguem as curvas de nível."):
    cd.text((x0, y), t, font=FT(15), fill=(60, 60, 56)); y += 25
y += 14
cd.rectangle([x0, y, x0 + PANEL - 56, y + 74], fill=(252, 236, 232), outline=(190, 80, 76))
cd.text((x0 + 12, y + 10), "Impacto no jogo", font=FT(15, True), fill=(120, 30, 28))
cd.text((x0 + 12, y + 34), "Terreno deixa de ser plano: exige malha/heightmap", font=FT(13), fill=(100, 50, 48))
cd.text((x0 + 12, y + 52), "no lugar do CSG. Prévia aprovada antes de mexer.", font=FT(13), fill=(100, 50, 48))
canvas.save("docs/shots/mapa_ilha_organica.png")
print("ok", canvas.size)
