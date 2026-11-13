"""Gera docs/shots/mapa_expansao_plano.png: esquema do plano de expansão (coords do jogo: x leste, z sul)."""
import math, random
from PIL import Image, ImageDraw, ImageFont

random.seed(7)
S = 2                       # supersampling
PPM = 6.4                   # px por metro
X0, Z0 = -88, -76           # canto superior esquerdo (m)
W, H = 1120, 910            # painel do mapa (px)
TOT_W = 1980
img = Image.new("RGB", (TOT_W * S, 960 * S), (255, 255, 255))
d = ImageDraw.Draw(img)
FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FR = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
def font(sz, bold=False): return ImageFont.truetype(FB if bold else FR, int(sz * S))

OX, OY = 50, 25
def P(x, z): return ((OX + (x - X0) * PPM) * S, (OY + (z - Z0) * PPM) * S)
def R(r): return r * PPM * S

def blob(cx, cz, rx, rz, jit=0.06, n=48, seed=0):
    rnd = random.Random(seed)
    ph = [rnd.uniform(0, 6.28) for _ in range(3)]
    pts = []
    for i in range(n):
        a = i / n * 6.2832
        k = 1 + jit * (math.sin(2 * a + ph[0]) + .6 * math.sin(3 * a + ph[1]) + .4 * math.sin(5 * a + ph[2]))
        pts.append(P(cx + rx * k * math.cos(a), cz + rz * k * math.sin(a)))
    return pts

def dashed_circle(cx, cz, r, col, w=2, n=40):
    for i in range(n):
        if i % 2: continue
        a0, a1 = i / n * 360, (i + 1) / n * 360
        x, y = P(cx, cz); rr = R(r)
        d.arc([x - rr, y - rr, x + rr, y + rr], a0, a1, fill=col, width=w * S)

def dashed_line(a, b, col, w=2, dash=10):
    (x0, y0), (x1, y1) = P(*a), P(*b)
    L = math.hypot(x1 - x0, y1 - y0); n = int(L / (dash * S))
    for i in range(0, n, 2):
        t0, t1 = i / n, min((i + 1) / n, 1)
        d.line([x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0, x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1], fill=col, width=w * S)

def text(xy, s, sz=15, col=(200, 205, 200), bold=False, anchor="mm"):
    d.text(xy, s, font=font(sz, bold), fill=col, anchor=anchor)

def label(x, z, s, dz=0, sz=15, col=(190, 196, 190)):
    px, py = P(x, z); text((px, py + dz * S), s, sz, col)

def badge(x, z, n, col=(222, 168, 52)):
    px, py = P(x, z); r = 15 * S
    d.ellipse([px - r, py - r, px + r, py + r], fill=col)
    text((px, py), str(n), 17, (30, 24, 10), True)

# painel do mar
d.rounded_rectangle([OX * S, OY * S, (OX + W) * S, (OY + H) * S], radius=22 * S, fill=(10, 16, 24))
for i in range(26):
    x = random.uniform(-85, 85); z = random.uniform(-72, 66); l = random.uniform(6, 16)
    a, b = P(x, z), P(x + l, z)
    d.line([a, b], fill=(24, 36, 52), width=2 * S)

SAND, GRASS, GRASS2, ROCK = (58, 54, 42), (28, 40, 33), (22, 33, 27), (48, 50, 46)

# ---- ilhas e terreno ----
d.polygon(blob(0, 0, 38.5, 38.5, 0.025, seed=1), fill=(48, 56, 48))          # borda ilha atual
d.polygon(blob(0, 0, 36, 36, 0.03, seed=2), fill=GRASS)
d.polygon(blob(0, 0, 28, 28, 0.04, seed=3), fill=GRASS2)
# costa norte
d.polygon(blob(0, -52, 36, 12.5, 0.06, seed=4), fill=(52, 58, 52))
d.polygon(blob(0, -52, 33.5, 10, 0.07, seed=5), fill=SAND)
# mata oeste
d.polygon(blob(-58, -6, 24, 32, 0.05, seed=6), fill=(40, 52, 42))
d.polygon(blob(-58, -6, 21.5, 29.5, 0.06, seed=7), fill=(20, 34, 26))
# afloramento da gruta
d.polygon(blob(31, -58, 10, 8, 0.1, seed=8), fill=ROCK)
d.polygon(blob(31, -58, 8, 6, 0.1, seed=9), fill=(40, 42, 40))
# ilhéus
d.polygon(blob(51, -2, 6.5, 6.5, 0.1, seed=10), fill=(60, 56, 54))
d.polygon(blob(50, 42, 10, 8.5, 0.1, seed=11), fill=(52, 56, 50))
d.polygon(blob(50, 42, 8, 6.5, 0.1, seed=12), fill=GRASS)

# árvores da mata e da ilha
for _ in range(95):
    a = random.uniform(0, 6.28); r = random.uniform(0, 1) ** .5
    x, z = -58 + 19 * r * math.cos(a), -6 + 27 * r * math.sin(a)
    if abs(x + 62) < 5 and abs(z + 12) < 5: continue
    px, py = P(x, z); rr = random.uniform(5, 8) * S
    d.ellipse([px - rr, py - rr, px + rr, py + rr], fill=random.choice([(26, 56, 38), (30, 62, 42), (22, 48, 34)]))
for _ in range(34):
    a = random.uniform(0, 6.28); r = random.uniform(.3, 1) ** .5 * 30
    x, z = r * math.cos(a), r * math.sin(a)
    if math.hypot(x, z + 12) < 7 or math.hypot(x - 27, z - 7) < 7 or abs(x) < 3 and z > 12: continue
    px, py = P(x, z); rr = random.uniform(4, 6) * S
    d.ellipse([px - rr, py - rr, px + rr, py + rr], fill=(26, 52, 36))
# algas / destroços na costa norte
for i in range(14):
    x = random.uniform(-26, 24); z = -52 + random.uniform(-5, 6.5)
    px, py = P(x, z); d.line([px, py, px + 6 * S, py - 10 * S], fill=(70, 120, 80), width=3 * S)
# pedras de maré
def stones(a, b, n):
    for i in range(n):
        t = (i + .5) / n; px, py = P(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
        rr = 3.6 * S; d.ellipse([px - rr, py - rr, px + rr, py + rr], fill=(110, 104, 98))
stones((38, -1.6), (45, -2.2), 5)
stones((30, 26), (43, 38), 6)

# trilhas
TRAIL = (150, 132, 100)
dashed_line((0, -12), (0, 38), TRAIL)                       # farol -> píer
dashed_line((0, 6), (27, 7), TRAIL); dashed_line((0, 8), (-19, 14), TRAIL)
dashed_line((-35, -4), (-62, -12), TRAIL)                    # mata
dashed_line((0, -23), (0, -46), TRAIL); dashed_line((0, -46), (28, -56), TRAIL); dashed_line((0, -46), (-22, -50), TRAIL)
dashed_line((20, 20), (29, 28), TRAIL)

# píer
for i in range(6):
    px, py = P(0, 38 + i * 2.3)
    d.rectangle([px - 5 * S, py - 7 * S, px + 5 * S, py + 7 * S], fill=(62, 48, 34), outline=(34, 26, 18))
# naufrágio
w = [P(-38, 22), P(-31, 24), P(-27, 31), P(-35, 29)]
d.polygon(w, fill=(104, 44, 32), outline=(60, 24, 18))
# farol
px, py = P(0, -12); r = R(4.8)
d.ellipse([px - r, py - r, px + r, py + r], fill=(80, 86, 98))
r = R(1.8); d.ellipse([px - r, py - r, px + r, py + r], fill=(228, 180, 60))
# casa, galpão
def box(x, z, w, h, col, edge=(30, 30, 28)):
    a, b = P(x - w / 2, z - h / 2), P(x + w / 2, z + h / 2); d.rectangle([a, b], fill=col, outline=edge, width=2 * S)
box(27, 7, 5.6, 4.6, (74, 62, 50))
box(-20, 14.5, 3.8, 3.8, (60, 72, 66))
box(-62, -12, 6, 5, (70, 56, 44)); box(-62, -12, 3, 2.2, (36, 28, 22))        # vigia 6
# fábricas (provisório)
box(-11, 21, 4.6, 3.6, (112, 84, 40), (220, 168, 60)); box(-11, 27, 4.6, 3.6, (88, 70, 62), (220, 168, 60))
# entrada da gruta
px, py = P(31, -58); r = R(2.6); d.pieslice([px - r, py - r, px + r, py + r], 180, 360, fill=(6, 8, 10))
# oficina / horta / cerca / pesca
box(-27, 8, 3.4, 3.0, (80, 70, 60), (120, 160, 190))
box(7, -53, 8, 2.2, (66, 50, 36), (120, 160, 190))                               # píer de pesca
px, py = P(22, 18); r = R(3); d.rectangle([px - r, py - r, px + r, py + r], outline=(120, 160, 190), width=2 * S)  # horta
dashed_circle(27, 7, 8, (120, 160, 190), 2, 36)                                  # cerca da casa
# zonas de tensão
RED = (180, 56, 52)
dashed_circle(31, -58, 8.5, RED); dashed_circle(0, 47, 9, RED); dashed_circle(-62, -12, 10, RED)
# raio de fog 45 m do farol
dashed_circle(0, -12, 45, (60, 80, 100), 1, 90)

# rótulos
label(0, -12, "Farol 7", 38, 16, (232, 232, 220))
label(27, 7, "Casa do vigia", 40)
label(-20, 14.5, "Galpão", -26)
label(51, -2, "Ilhota da maré", 9.2)
label(50, 42, "Ilhéu sul", 11.5)
label(-34, 33, "Santa Aurora", 0, 13, (150, 110, 100))
label(-58, 24, "Mata do oeste", 0, 18, (110, 160, 120))
label(-62, -12, "Cabana do vigia 6", 6.8, 14)
label(0, -63.5, "Costa norte", 0, 18, (170, 160, 120))
label(31, -66, "Gruta", 0, 15)
label(0, 59.5, "Píer (início)", 0, 15)
label(-20, 21, "Fábrica de óleo", 0, 12, (240, 200, 110))
label(-24, 28, "Fábrica de combustível", 0, 12, (240, 200, 110))
text((P(80, -72)), "Norte ↑", 16, (160, 168, 160))
# escala
a, b = P(-82, 62), P(-62, 62); d.line([a, b], fill=(190, 196, 190), width=3 * S)
text((a[0] + (b[0] - a[0]) / 2, a[1] - 12 * S), "20 m", 13)

# numeração
items = [(-11, 21, 1), (-11, 27, 2), (-62, -12, 3), (0, -52, 4), (31, -58, 5), (7, -53, 6), (-27, 8, 7), (22, 18, 8), (50, 42, 9), (27, 7, 10)]
for x, z, n in items: badge(x + 3.4, z - 3.4, n)

# ---- painel lateral ----
LX = OX + W + 45
def head(y, s, fill=(238, 238, 232), edge=(150, 150, 146), col=(60, 60, 58)):
    d.rounded_rectangle([LX * S, y * S, (LX + 740) * S, (y + 50) * S], radius=10 * S, fill=fill, outline=edge, width=2 * S)
    text(((LX + 370) * S, (y + 25) * S), s, 24, col)
def row(y, n, t, sub):
    if n: 
        px, py = LX * S + 18 * S, (y + 14) * S; r = 13 * S
        d.ellipse([px - r, py - r, px + r, py + r], fill=(222, 168, 52)); text((px, py), str(n), 15, (30, 24, 10), True)
    d.text(((LX + 42) * S, y * S), t, font=font(21), fill=(20, 20, 20), anchor="lm" if False else "la")
    d.text(((LX + 42) * S, (y + 27) * S), sub, font=font(16), fill=(100, 100, 98), anchor="la")

head(25, "Estruturas por noite")
row(100, 1, "Fábrica de óleo", "Noite 1 · madeira, gordura, algas → óleo")
row(165, 2, "Fábrica de combustível", "Noite 1 · madeira, carvão, restos → combustível")
row(230, 3, "Cabana do vigia 6 + torre", "Noite 3 · binóculo mostra o navio; lore")
row(295, 4, "Coleta: lenha, algas, gordura", "Noite 2 · mata e costa norte")
row(360, 5, "Gruta de carvão", "Noite 2 · risco: Lavado lá dentro")
row(425, 6, "Pesca / armadilha", "Noite 2 · peixe e água")
row(490, 7, "Oficina", "Noite 2 · munição, pilhas, limpador de lente")
row(555, 8, "Horta e cisterna", "Noite 3 · comida e água por noite")
row(620, 9, "Ilhéu sul (maré)", "Noite 3 · sucata e abrigo")
row(685, 10, "Reforço de cerca e portas", "Noite 3 · atrasa as ondas da invasão")
head(770, "Zonas de tensão", (252, 232, 232), (190, 80, 76), (120, 30, 28))
d.text(((LX + 6) * S, 835 * S), "Gruta: escura, apertada, um Lavado", font=font(18), fill=(100, 100, 98), anchor="la")
d.text(((LX + 6) * S, 868 * S), "Mata: pouca visão, cabana isolada", font=font(18), fill=(100, 100, 98), anchor="la")
d.text(((LX + 6) * S, 901 * S), "Fim do píer: névoa densa", font=font(18), fill=(100, 100, 98), anchor="la")

img = img.resize((TOT_W, 960), Image.LANCZOS)
img.save("docs/shots/mapa_expansao_plano.png")
print("ok")
