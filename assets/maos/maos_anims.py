# poses e animacoes (exec dentro de build_maos.py). Eixos da mao: Y dedos, Z dorso, X lado (polegar -X na direita).
def add3(a, b):
    return tuple(x + y for x, y in zip(a, b))


def lerp(a, b, t):
    return a + (b - a) * t


def sm(t):
    t = max(0, min(1, t))
    return t * t * (3 - 2 * t)


def lerp3(a, b, t):
    return tuple(lerp(x, y, t) for x, y in zip(a, b))


LB = dict(pos=(-0.105, 0.32, -0.19), rot=(38, 10, -9), wrist=(-6, 0, 4), curl=0.22, thumb=0.15, spread=4)
RB = dict(pos=(0.105, 0.32, -0.19), rot=(38, -10, 9), wrist=(-6, 0, -4), curl=0.22, thumb=0.15, spread=4)


def pose(h, base, dpos=(0, 0, 0), drot=(0, 0, 0), **kw):
    d = dict(base)
    d["pos"] = add3(base["pos"], dpos)
    d["rot"] = add3(base["rot"], drot)
    d.update(kw)
    h.set(**d)


anims = {}


def A(name, frames):
    def deco(fn):
        anims[name] = (frames, fn)
        return fn
    return deco


def lens(on):
    lens_obj.data.materials.clear()
    lens_obj.data.materials.append(M["lenteon"] if on else M["lenteoff"])


def hold_flash():
    flash_obj.parent = R.hand
    flash_obj.location = (0.0, GRIP[1], GRIP[2])
    flash_obj.rotation_euler = (0, 0, rad(90))
    show(flash_obj, True)


RF = dict(pos=(0.115, 0.32, -0.175), rot=(34, 0, 38), wrist=(0, 0, -62), curl=0.80, thumb=0.55)


def grip_flash(dpos=(0, 0, 0), drot=(0, 0, 0), **kw):
    d = dict(RF)
    d["pos"] = add3(RF["pos"], dpos)
    d["rot"] = add3(RF["rot"], drot)
    d.update(kw)
    R.set(**d)


def aim(h, target, **kw):
    """posiciona o pulso para que o ponto GRIP da mao fique em target (mundo)"""
    pos = Vector(target)
    for _ in range(4):
        h.set(pos=tuple(pos), **kw)
        bpy.context.view_layer.update()
        gp = h.hand.matrix_world @ Vector(GRIP)
        pos += Vector(target) - gp
    h.set(pos=tuple(pos), **kw)
    bpy.context.view_layer.update()
    return gp


@A("idle", 8)
def _(i, n):
    t = 2 * pi * i / n
    pose(L, LB, (0, 0, 0.004 * sin(t)), (0.8 * sin(t), 0, 0))
    pose(R, RB, (0, 0, 0.004 * sin(t + 0.5)), (0.8 * sin(t + 0.5), 0, 0))


@A("lanterna_idle", 8)
def _(i, n):
    t = 2 * pi * i / n
    pose(L, LB, (0, 0, 0.004 * sin(t)), (0.8 * sin(t), 0, 0))
    hold_flash(); lens(False)
    grip_flash((0.003 * sin(t), 0, 0.004 * sin(t + 0.6)), (1.2 * sin(t + 0.6), 0, 1.0 * sin(t)))


def ligar_frame(i, lens_on):
    pose(L, LB)
    hold_flash(); lens(lens_on)
    th = [0.55, 0.20, 0.95, 0.60, 0.55][i]
    dz = [0, 0.003, -0.007, -0.003, 0][i]
    grip_flash((0, 0, dz), (-[0, 0, 3, 1, 0][i], 0, 0), thumb=th)


@A("lanterna_ligar", 5)
def _(i, n):
    ligar_frame(i, i >= 2)


@A("lanterna_desligar", 5)
def _(i, n):
    j = 4 - i
    ligar_frame(j, j >= 2)


def walk_pose(i, n, amp, curl):
    t = 2 * pi * i / n
    b = sin(2 * t)
    pose(L, LB, (0.010 * amp * sin(t), 0.006 * amp * cos(t), 0.010 * amp * b), (2.5 * amp * b, 0, 3 * amp * sin(t)), curl=curl)
    hold_flash(); lens(False)
    grip_flash((-0.010 * amp * sin(t), -0.006 * amp * cos(t), 0.010 * amp * b), (2.5 * amp * b, 0, -3 * amp * sin(t)))


@A("andar", 8)
def _(i, n):
    walk_pose(i, n, 1.0, 0.25)


@A("correr", 8)
def _(i, n):
    walk_pose(i, n, 2.2, 0.55)


# ---- lata (alca = barra ao longo de X)
CARRY_T = (0.06, 0.38, -0.15)
CARRY = dict(rot=(40, 0, 24), wrist=(-34, 0, 0), curl=0.98, thumb=0.75)
CAN_AT = (0.03, 0.40, -0.30)     # alca da lata no chao (alvo da mao em pegar)
GRAB = dict(rot=(40, 0, 20), wrist=(-34, 0, 0))


def put_can(gp, sway=0.0, rz=0.0):
    show(can_obj, True)
    can_obj.parent = None
    can_obj.location = (gp[0] - 0.03, gp[1] + 0.005, gp[2])
    can_obj.rotation_euler = (0, rad(sway), rad(rz))


@A("pegar", 10)
def _(i, n):
    pose(L, LB)
    if i <= 3:
        k = sm(i / 3)
        tgt = lerp3((RB["pos"][0], RB["pos"][1], RB["pos"][2] + 0.02), (CAN_AT[0] + 0.03, CAN_AT[1], CAN_AT[2] + 0.075), k)
        kw = dict(rot=lerp3(RB["rot"], GRAB["rot"], k), wrist=lerp3(RB["wrist"], GRAB["wrist"], k), curl=lerp(0.2, 0.15, k), thumb=lerp(0.2, 0.1, k))
        aim(R, tgt, **kw)
        put_can(CAN_AT)
    elif i <= 5:
        k = (i - 3) / 2
        kw = dict(rot=GRAB["rot"], wrist=GRAB["wrist"], curl=lerp(0.15, 0.98, k), thumb=lerp(0.1, 0.75, k))
        gp = aim(R, (CAN_AT[0] + 0.03, CAN_AT[1], CAN_AT[2] + 0.075), **kw)
        put_can(CAN_AT)
    else:
        k = sm((i - 5) / 4)
        tgt = lerp3((CAN_AT[0] + 0.03, CAN_AT[1], CAN_AT[2] + 0.075), CARRY_T, k)
        kw = dict(rot=lerp3(GRAB["rot"], CARRY["rot"], k), wrist=lerp3(GRAB["wrist"], CARRY["wrist"], k), curl=0.98, thumb=0.75)
        gp = aim(R, tgt, **kw)
        put_can(gp, 0, 0)


@A("segurar_lata", 6)
def _(i, n):
    t = 2 * pi * i / n
    pose(L, LB, (0, 0, 0.004 * sin(t + 1)), (0.8 * sin(t + 1), 0, 0))
    tgt = (CARRY_T[0] + 0.004 * sin(t), CARRY_T[1], CARRY_T[2] + 0.004 * cos(t))
    gp = aim(R, tgt, **CARRY)
    put_can(gp, 3 * sin(t), 0)


# ---- valvula (roda no plano XZ voltada para a camera); a mao segura o aro no quadrante superior direito
WC = (0.0, 0.44, -0.20)
WR = 0.115


def rim(a):
    return (WC[0] + WR * cos(rad(a)), WC[1] - 0.012, WC[2] + WR * sin(rad(a)))


def rim_pose(a):
    return dict(rot=(42, 90 - a - 40, 16), wrist=(-34, 0, 0), curl=0.92, thumb=0.7)


@A("interagir", 7)
def _(i, n):
    show(wheel, True)
    wheel.location = WC
    pose(L, LB)
    a0, a1 = 80.0, 30.0
    if i < 2:
        k = sm(i / 1.0)
        kw = rim_pose(a0)
        kw = dict(rot=lerp3(RB["rot"], kw["rot"], k), wrist=lerp3(RB["wrist"], kw["wrist"], k), curl=lerp(0.2, 0.92, k), thumb=lerp(0.2, 0.7, k))
        aim(R, lerp3(RB["pos"], rim(a0), k), **kw)
        wheel.rotation_euler = (0, 0, 0)
    elif i <= 5:
        a = lerp(a0, a1, (i - 2) / 3.0)
        wheel.rotation_euler = (0, rad(a0 - a), 0)
        aim(R, rim(a), **rim_pose(a))
    else:
        wheel.rotation_euler = (0, rad(a0 - a1), 0)
        kw = rim_pose(a1)
        k = 0.6
        kw = dict(rot=lerp3(kw["rot"], RB["rot"], k), wrist=lerp3(kw["wrist"], RB["wrist"], k), curl=0.4, thumb=0.3)
        aim(R, lerp3(rim(a1), RB["pos"], k), **kw)


# ---- bomba: alavanca com cabo
PUMP = (0.27, 0.46, -0.27)


@A("bombear", 8)
def _(i, n):
    show(pump, True)
    pump.location = PUMP
    pose(L, LB)
    phi = rad(18) * cos(2 * pi * i / n)
    lever.rotation_euler = (0, phi, 0)
    tip = (PUMP[0] - 0.20 * cos(phi), PUMP[1] - 0.012, PUMP[2] + 0.20 * sin(phi))
    aim(R, tip, rot=(40, -phi * 57.3, 18), wrist=(-34, 0, 0), curl=0.95, thumb=0.7)
