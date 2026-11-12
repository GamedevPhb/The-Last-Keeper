"""Pinta keeper_atlas.png (python3 do sistema com numpy+PIL): python3 paint_atlas.py"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import keeper_geo as G, keeper_tex as T
Pm = {"torso": G.make_torso(), "head": G.make_head(), "hat": G.make_hat(), "neck": G.make_neck(),
      "uparm": G.make_uparm(), "forearm": G.make_forearm(), "hand": G.make_hand(),
      "thigh": G.make_thigh(), "shin": G.make_shin(), "shaft": G.make_shaft(), "foot": G.make_foot()}
T.paint_atlas(Pm).save(os.path.join(HERE, "keeper_atlas.png"))
print("atlas ok")
