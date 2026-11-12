"""Preview: flatpak run org.blender.Blender --background keeper.blend --python preview_keeper.py -- <saida_dir> [anim frame]"""
import bpy, sys, os
from math import radians
argv = sys.argv[sys.argv.index("--") + 1:]
out = argv[0]; os.makedirs(out, exist_ok=True)
sc = bpy.context.scene
rig = bpy.data.objects["KeeperRig"]
for t in rig.animation_data.nla_tracks: t.mute = True
if len(argv) < 3:
    for pb in rig.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0); pb.location = (0, 0, 0)
if len(argv) >= 3:
    act = bpy.data.actions[argv[1]]
    rig.animation_data.action = act
    sc.frame_set(int(argv[2]))
cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
cam.data.type = "ORTHO"
sun = bpy.data.objects.new("s", bpy.data.lights.new("s", "SUN")); sc.collection.objects.link(sun)
sun.data.energy = 3.5; sun.data.color = (1, .92, .8)
fill = bpy.data.objects.new("f", bpy.data.lights.new("f", "SUN")); sc.collection.objects.link(fill)
fill.data.energy = 1.2; fill.data.color = (.6, .75, .9)
sc.world = bpy.data.worlds.new("w"); sc.world.use_nodes = True
bg = next(n for n in sc.world.node_tree.nodes if n.type == "BACKGROUND"); bg.inputs[0].default_value = (.15, .17, .17, 1)
sc.render.engine = "CYCLES"; sc.cycles.samples = 16; sc.cycles.device = "CPU"
sc.render.resolution_x, sc.render.resolution_y = 360, 540
views = {"front": (0, -4, 0.9, 90, 0), "back": (0, 4, .9, 90, 180), "side": (4, 0, .9, 90, 90), "q34": (-3, -3, .9, 90, -45)}
zoom = os.environ.get("ZOOM")
for n, (x, y, z, rx, rz) in views.items():
    cam.location = (x, y, z); cam.rotation_euler = (radians(rx), 0, radians(rz))
    cam.data.ortho_scale = 2.0
    if zoom:
        zz, ss = [float(v) for v in zoom.split(",")]
        cam.location.z = zz; cam.data.ortho_scale = ss
    sun.rotation_euler = (radians(50), 0, radians(rz + 30)); fill.rotation_euler = (radians(110), 0, radians(rz - 130))
    sc.render.filepath = os.path.join(out, n + ".png")
    bpy.ops.render.render(write_still=True)
