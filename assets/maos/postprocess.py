"""Alfa binario, paleta unica reduzida (sem dither) e sheets. Entrada: _raw/<anim>/NN.png"""
import os, glob
from PIL import Image
import numpy as np
D = os.path.dirname(os.path.abspath(__file__))
FPS = {"idle": 8, "lanterna_idle": 8, "lanterna_ligar": 10, "lanterna_desligar": 10, "andar": 10, "correr": 12,
       "pegar": 10, "segurar_lata": 8, "interagir": 8, "bombear": 10}
anims = sorted(d for d in os.listdir(os.path.join(D, "_raw")))
frames = {a: [Image.open(f).convert("RGBA") for f in sorted(glob.glob(os.path.join(D, "_raw", a, "*.png")))] for a in anims}
px = []
for fr in frames.values():
    for im in fr:
        a = np.array(im).reshape(-1, 4)
        px.append(a[a[:, 3] >= 128, :3])
px = np.concatenate(px)
side = int(np.ceil(np.sqrt(len(px))))
buf = np.zeros(side * side * 3, np.uint8); buf[:len(px) * 3] = px.reshape(-1)
pal = Image.fromarray(buf.reshape(side, side, 3)).quantize(colors=28, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
for a, fr in frames.items():
    out = os.path.join(D, a); os.makedirs(out, exist_ok=True)
    res = []
    for k, im in enumerate(fr):
        arr = np.array(im)
        alpha = np.where(arr[:, :, 3] >= 128, 255, 0).astype(np.uint8)
        q = Image.fromarray(arr[:, :, :3]).quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
        rgba = np.dstack([np.array(q), alpha]); rgba[alpha == 0, :3] = 0
        r = Image.fromarray(rgba, "RGBA"); r.save(os.path.join(out, "%02d.png" % k)); res.append(r)
    sheet = Image.new("RGBA", (160 * len(res), 120), (0, 0, 0, 0))
    for k, r in enumerate(res): sheet.paste(r, (160 * k, 0))
    sheet.save(os.path.join(out, a + "_sheet.png"))
    print(a, len(res), "frames", FPS.get(a))
