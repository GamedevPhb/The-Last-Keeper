#!/usr/bin/env python3
"""Converte os frames de duas maos em uma mao so (direita) e troca a lanterna creme por uma preta.
Le de _original/ (copia dos frames antigos, criada na primeira execucao) e grava em <anim>/NN.png.
Uso: python3 assets/maos/fix_single_hand.py"""
import math, os, shutil
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ORIG = os.path.join(HERE, "_original")
# anim -> (frames, x de corte: a esquerda dele some, lanterna?, luz por quadro)
ANIMS = {
	"idle": (8, 86, False, None),
	"lanterna_idle": (8, 80, True, lambda i: True),
	"lanterna_ligar": (5, 80, True, lambda i: i >= 2),
	"lanterna_desligar": (5, 80, True, lambda i: i < 2),
	"andar": (8, 80, True, lambda i: False),
	"correr": (8, 80, True, lambda i: False),
	"pegar": (10, 80, False, None),
	"segurar_lata": (6, 76, False, None),
	"interagir": (7, 78, False, None),
	"bombear": (8, 78, False, None),
}
EXTRA = {"andar_luz": "andar", "correr_luz": "correr"}  # variantes com a lente acesa

BODY = [(10, 10, 12), (22, 23, 26), (50, 52, 58), (28, 29, 33)]  # sombra, base, brilho, borda


def is_glove(p):
	return p[3] > 0 and p[0] - p[1] >= 50


def strip(im, cut, lantern):
	im = im.copy()
	px = im.load()
	for y in range(120):
		for x in range(160):
			if x < cut:
				px[x, y] = (0, 0, 0, 0)
			elif lantern and x <= 100 and 50 <= y <= 90 and px[x, y][3] > 0 and not is_glove(px[x, y]):
				px[x, y] = (0, 0, 0, 0)
	# remove fragmentos soltos (restos da mao esquerda)
	seen = set()
	for y in range(120):
		for x in range(160):
			if px[x, y][3] == 0 or (x, y) in seen:
				continue
			comp, stack = [], [(x, y)]
			seen.add((x, y))
			while stack:
				cx, cy = stack.pop()
				comp.append((cx, cy))
				for dx in (-1, 0, 1):
					for dy in (-1, 0, 1):
						nx, ny = cx + dx, cy + dy
						if 0 <= nx < 160 and 0 <= ny < 120 and (nx, ny) not in seen and px[nx, ny][3] > 0:
							seen.add((nx, ny))
							stack.append((nx, ny))
			if len(comp) < 60:
				for cx, cy in comp:
					px[cx, cy] = (0, 0, 0, 0)
	return im


def fist_top(im):
	px = im.load()
	for y in range(120):
		xs = [x for x in range(88, 160) if px[x, y][3] > 0]
		if xs:
			sel = []
			for yy in range(y, y + 5):
				sel += [x for x in range(88, 160) if px[x, yy][3] > 0 and x < xs[0] + 22]
			return sum(sel) / len(sel), y
	return 110, 70


def lantern_layer(cx, top, lit, ang=math.radians(8)):
	"""Lanterna vista por tras, apontando para frente (cima da tela, levemente ao centro)."""
	layer = Image.new("RGBA", (160, 120))
	px = layer.load()
	bx, by = cx, top               # base escondida no punho
	ax, ay = -math.sin(ang), -math.cos(ang)
	nx, ny = -ay, ax
	length = 34.0
	for y in range(120):
		for x in range(160):
			dx, dy = x - bx, y - by
			t = dx * ax + dy * ay
			s = dx * nx + dy * ny
			if t < 0 or t > length:
				continue
			head = t > length - 10
			half = 3.4 if not head else 3.4 + 1.6 * (t - (length - 10)) / 10 * 1.0
			if t > length - 10 and t < length - 8:
				half = 4.0
			if abs(s) > half:
				continue
			u = s / half
			col = BODY[0] if u < -0.7 else BODY[1] if u < -0.15 else BODY[2] if u < 0.2 else BODY[3] if u < 0.75 else BODY[0]
			if length - 11 <= t < length - 9.5:   # anel de latao
				col = (138, 108, 52) if u < 0.2 else (96, 74, 36)
			px[x, y] = col + (255,)
	# tampa da cabeca (vista de cima/atras): elipse com a lente
	tx, ty = bx + ax * length, by + ay * length
	for y in range(120):
		for x in range(160):
			ex, ey = (x - tx) / 6.2, (y - ty) / 2.6
			d = ex * ex + ey * ey
			if d <= 1.0:
				if lit:
					col = (255, 246, 196) if d < 0.45 else (236, 200, 120)
				else:
					col = (92, 100, 104) if d < 0.45 else (30, 31, 35)
				px[x, y] = col + (255,)
			elif d <= 1.5 and lit:
				px[x, y] = (150, 118, 60, 255)
	return layer


ANCHOR = (112.0, 80.0)   # punho (x, y) no quadro de referencia; HAND_ANCHOR_X em hands.gd casa com isso
ANG = math.radians(10)


def glove_arm(ox, oy):
	"""Antebraco de oleado + luva de couro fechada, desenhados do zero, alinhados com o cabo."""
	layer = Image.new("RGBA", (160, 120))
	px = layer.load()
	wx, wy = ANCHOR[0] + ox, ANCHOR[1] + oy
	ax, ay = -math.sin(ANG), -math.cos(ANG)
	nx, ny = -ay, ax
	SL = [(52, 59, 47), (71, 78, 61), (89, 97, 75), (116, 124, 95), (71, 78, 61)]
	LE = [(36, 19, 10), (89, 42, 18), (143, 71, 32), (177, 99, 47), (104, 55, 24)]
	for y in range(120):
		for x in range(160):
			dx, dy = x - wx, y - wy
			t = dx * ax + dy * ay      # para frente a partir do pulso
			s = dx * nx + dy * ny      # lateral (negativo = esquerda)
			col = None
			if t < 0:
				half = 9.0 + (-t) * 0.07
				if abs(s) <= half:
					u = s / half
					col = SL[0] if u < -0.8 else SL[1] if u < -0.3 else SL[2] if u < 0.35 else SL[3] if u < 0.7 else SL[4]
					if -6 <= t < -4 or -9.5 <= t < -8:
						col = (214, 184, 112) if u < 0.5 else (150, 124, 72)   # punho do oleado
					elif -4 <= t < 0:
						col = SL[4] if u < 0.5 else SL[0]
			# punho fechado (luva): elipse achatada
			if ((s / 9.6) ** 2 + ((t - 7) / 10.5) ** 2) <= 1.0:
				u = s / 9.6
				col = LE[1] if u < -0.7 else LE[2] if u < 0.0 else LE[3] if u < 0.35 else LE[4] if u < 0.75 else LE[0]
				for ft in (3.0, 7.0, 11.0):          # dedos envolvendo o cabo
					if abs(t - (ft + s * s * 0.025)) < 0.6 and abs(s) < 8.6:
						col = LE[0]
				if t > 14.2 and abs(s) < 7:
					col = LE[3]                          # brilho dos nos dos dedos
			# polegar sobre o cabo, do lado esquerdo
			if (((s + 7.2) / 3.0) ** 2 + ((t - 9) / 5.5) ** 2) <= 1.0:
				col = LE[2] if s > -8.5 else LE[1]
			if col:
				px[x, y] = col + (255,)
	return layer, wx, wy, ax, ay


def build(src, cut, lantern, lit, ref=None):
	hand = strip(src, cut, lantern)
	if not lantern:
		return hand
	cx, top = fist_top(hand)
	ox, oy = cx - ref[0], top - ref[1]
	arm, wx, wy, ax, ay = glove_arm(ox, oy)
	# o cabo sai do topo do punho (t ~ 15 a partir do pulso)
	fx, fy = wx + ax * 14, wy + ay * 14
	out = lantern_layer(fx, fy - 7 + 7, lit, ANG)
	out.alpha_composite(arm)
	return out


def main():
	if not os.path.isdir(ORIG):
		os.makedirs(ORIG)
		for a, (n, *_r) in ANIMS.items():
			for i in range(n):
				shutil.copy(f"{HERE}/{a}/{i:02d}.png", f"{ORIG}/{a}_{i:02d}.png")
		open(f"{ORIG}/.gdignore", "w").close()
	jobs = [(a, a) for a in ANIMS] + [(k, v) for k, v in EXTRA.items()]
	for dst, a in jobs:
		n, cut, lantern, lit = ANIMS[a]
		os.makedirs(f"{HERE}/{dst}", exist_ok=True)
		frames = []
		ref = None
		if lantern:
			ref = fist_top(strip(Image.open(f"{ORIG}/{a}_00.png").convert("RGBA"), cut, True))
		for i in range(n):
			src = Image.open(f"{ORIG}/{a}_{i:02d}.png").convert("RGBA")
			l = (lit(i) if lit else False) or dst.endswith("_luz")
			f = build(src, cut, lantern, l, ref)
			f.save(f"{HERE}/{dst}/{i:02d}.png")
			frames.append(f)
		sheet = Image.new("RGBA", (160 * n, 120))
		for i, f in enumerate(frames):
			sheet.paste(f, (160 * i, 0))
		sheet.save(f"{HERE}/{dst}/{dst}_sheet.png")


main()
