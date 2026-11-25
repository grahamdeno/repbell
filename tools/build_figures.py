#!/usr/bin/env python3
"""Builds App/Studio/figures.json: the animated line figure for every Workouts movement and desk stretch.

Each clip is a few key positions built from joint angles (so limbs keep their length), plus simple props
and turn arrows. Nothing here is drawn art or outside media: positions are numbers, so requirement R-1
(origin and rights of coach media) does not apply. Run after editing; CI checks every movement has a clip.

Angles: 0 points down, 90 points forward (side view) or out to the side (front view), 180 points up.
"""
import json
import math
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "App" / "Studio" / "figures.json"
MOVES = ROOT / "App" / "Studio" / "movements.json"

TORSO, NECK, HEAD = 50.0, 7.0, 13.0
UPPER, FORE, THIGH, SHIN = 26.0, 24.0, 37.0, 37.0
HEAD_R = 10.0
BOX_W, BOX_H, FLOOR = 300.0, 200.0, 184.0


def v(a):
    r = math.radians(a)
    return (math.sin(r), math.cos(r))


def add(p, d, n):
    return (p[0] + d[0] * n, p[1] + d[1] * n)


PREF = {"f": (1, 0), "b": (-1, 0), "u": (0, -1), "d": (0, 1), "fu": (1, -1), "bu": (-1, -1), "fd": (1, 1), "bd": (-1, 1),
        "o": None}


def ik(root, target, l1, l2, pref):
    """Two-bone reach from root toward target; the middle joint bends toward pref (a direction)."""
    dx, dy = target[0] - root[0], target[1] - root[1]
    d = math.hypot(dx, dy) or 0.001
    dd = max(abs(l1 - l2) + 0.5, min(l1 + l2 - 0.3, d))
    base = math.atan2(dy, dx)
    cosa = max(-1.0, min(1.0, (l1 * l1 + dd * dd - l2 * l2) / (2 * l1 * dd)))
    a = math.acos(cosa)
    cands = [(root[0] + l1 * math.cos(base + s * a), root[1] + l1 * math.sin(base + s * a)) for s in (1, -1)]
    pv = PREF[pref] if isinstance(pref, str) else pref
    mid = max(cands, key=lambda m: (m[0] - root[0]) * pv[0] + (m[1] - root[1]) * pv[1])
    end = (root[0] + dx / d * dd, root[1] + dy / d * dd)
    return mid, end


def limb(root, spec, l1, l2, pref):
    """spec is ('a', angle, bend) for angles, or a target point (x, y) to reach."""
    if isinstance(spec[0], str):
        _, a, e = spec
        m = add(root, v(a), l1)
        return m, add(m, v(a + e), l2)
    return ik(root, spec, l1, l2, pref)


def A(a, e=0):
    return ("a", a, e)


def S(hip=(0, -74), t=0, arm=None, arm2=None, leg=None, leg2=None, head=0, ep="b", ep2=None, kp="f", kp2=None):
    """Side view facing right; floor is y = 0. t: 0 upright, 90 bent forward flat, -90 leaning back flat.
    arm/leg: a target point to reach, or A(angle, bend). Angles: 0 down, 90 forward, 180 up.
    arm2/leg2 are the far side (drawn dimmer); they copy the near side unless given."""
    arm = arm or A(8, 12)
    leg = leg or (hip[0] + 2, 0)
    arm2 = arm2 or arm
    leg2 = leg2 or leg
    up = v(180 - t)
    sh = add(hip, up, TORSO)
    nk = add(sh, up, NECK)
    hd = add(nk, v(180 - t - head), HEAD)
    el, ha = limb(sh, arm, UPPER, FORE, ep)
    el2, ha2 = limb(sh, arm2, UPPER, FORE, ep2 or ep)
    kn, ft = limb(hip, leg, THIGH, SHIN, kp)
    kn2, ft2 = limb(hip, leg2, THIGH, SHIN, kp2 or kp)
    return {"hd": hd, "nk": nk, "sh": sh, "hp": hip, "el": el, "ha": ha, "el2": el2, "ha2": ha2,
            "kn": kn, "ft": ft, "kn2": kn2, "ft2": ft2}


def F(hip=(0, -74), lean=0, arm=None, arm2=None, leg=None, leg2=None, head=0, sw=17.0, hw=10.0,
      ep="o", ep2=None, kp="o", kp2=None):
    """Front view; floor y = 0. arm/leg are screen-left, arm2/leg2 screen-right (mirrored copies if omitted).
    A(angle, bend): 0 down, 90 straight out to that side, 180 up; positive bend turns the forearm or shin outward."""
    up = v(180 - lean)
    across = (math.cos(math.radians(lean)), math.sin(math.radians(lean)))
    hp, hp2 = (hip[0] - hw, hip[1]), (hip[0] + hw, hip[1])
    c = add(hip, up, TORSO)
    sh, sh2 = add(c, across, -sw), add(c, across, sw)
    nk = add(c, up, NECK)
    hd = add(nk, v(180 - lean - head), HEAD)
    arm = arm or A(14, 0)
    leg = leg or (hp[0] - 4, 0)
    mx = lambda q: q if isinstance(q[0], str) else (2 * hip[0] - q[0], q[1])
    arm2 = arm2 or mx(arm)
    leg2 = leg2 or mx(leg)

    def one(root, spec, l1, l2, pref, out):
        if isinstance(spec[0], str):
            _, a, e = spec
            m = add(root, v(out * a), l1)
            return m, add(m, v(out * (a + e)), l2)
        return ik(root, spec, l1, l2, (out, 0) if pref == "o" else pref)

    el, ha = one(sh, arm, UPPER, FORE, ep, -1)
    el2, ha2 = one(sh2, arm2, UPPER, FORE, ep2 or ep, 1)
    kn, ft = one(hp, leg, THIGH, SHIN, kp, -1)
    kn2, ft2 = one(hp2, leg2, THIGH, SHIN, kp2 or kp, 1)
    return {"hd": hd, "nk": nk, "sh": sh, "sh2": sh2, "hp": hp, "hp2": hp2, "c": hip, "el": el, "ha": ha,
            "el2": el2, "ha2": ha2, "kn": kn, "ft": ft, "kn2": kn2, "ft2": ft2}


def clip(view, frames, seconds=0.8, hold=0.5, props=None, arrows=None, still=None, floor=True):
    """Frames are in world coordinates (floor y = 0); the clip is scaled to fit the box with the floor at FLOOR."""
    prims = [p(frames[0]) for p in (props or [])]
    arcs = [a(frames[0]) for a in (arrows or [])]
    xs, ys = [], []
    for f in frames:
        for k, p in f.items():
            if k == "c":
                continue
            r = HEAD_R if k == "hd" else 4
            xs += [p[0] - r, p[0] + r]
            ys += [p[1] - r, p[1] + r]
    for p in prims:
        for pt in p.get("pts", []):
            xs.append(pt[0]); ys.append(pt[1])
    for a in arcs:
        xs += [a["at"][0] - a["r"], a["at"][0] + a["r"]]
        ys += [a["at"][1] - a["r"], a["at"][1] + a["r"]]
    by = max(ys + ([0.0] if floor else []))
    w, h = max(xs) - min(xs), by - min(ys)
    s = min((BOX_W - 40) / max(w, 1), (FLOOR - 12) / max(h, 1), 1.35)
    cx = (max(xs) + min(xs)) / 2
    T = lambda p: [round(BOX_W / 2 + (p[0] - cx) * s, 1), round(FLOOR - (by - p[1]) * s, 1)]
    out_frames = [{k: T(p) for k, p in f.items() if k != "c"} for f in frames]
    out_props = []
    for p in prims:
        q = {k: val for k, val in p.items() if k != "pts"}
        if "pts" in p:
            q["pts"] = [T(pt) for pt in p["pts"]]
        if "r" in q:
            q["r"] = round(q["r"] * s, 1)
        out_props.append(q)
    out_arcs = [{"at": T(a["at"]), "r": round(a["r"] * s, 1), "from": a["from"], "to": a["to"]} for a in arcs]
    c = {"view": view, "frames": out_frames, "seconds": seconds, "hold": hold, "floor": floor,
         "still": still if still is not None else (1 if len(frames) > 1 else 0)}
    if out_props:
        c["props"] = out_props
    if out_arcs:
        c["arrows"] = out_arcs
    return c


def hold_clip(view, start, pose, **kw):
    """A stretch or yoga hold: ease from a neutral start into the pose and hold it."""
    kw.setdefault("seconds", 1.2)
    kw.setdefault("hold", 2.4)
    return clip(view, [start, pose], **kw)


# Props: functions of the first frame, returning primitives in world coordinates.
def at(f, j, dx=0, dy=0):
    return (f[j][0] + dx, f[j][1] + dy)


def line(p, q, width=3):
    return {"kind": "line", "pts": [p, q], "width": width, "tone": "prop"}


def box(x0, y0, x1, y1, kind="rect"):
    return {"kind": kind, "pts": [(x0, y0), (x1, y1)], "tone": "prop"}


def chair(x, top, w=34):
    return lambda f: box(x - w / 2, top, x + w / 2, 0.0, "chair")


def wall(x, height=160):
    return lambda f: line((x, 0.0), (x, -height), 4)


def bar(y, x0=-46, x1=46):
    return lambda f: line((x0, y), (x1, y), 4)


def bell(j="ha"):
    return lambda f: {"kind": "bell", "follow": j, "r": 8, "pts": [at(f, j, 0, 10)], "tone": "prop"}


def band(j, to):
    return lambda f: {"kind": "band", "follow": j, "pts": [to], "tone": "prop"}


def bag(j="ha", dx=0, dy=16):
    return lambda f: {"kind": "bag", "follow": j, "r": 13, "pts": [at(f, j, dx, dy)], "tone": "prop"}


def board(x, w=68):
    return lambda f: box(x - w / 2, -8.0, x + w / 2, 0.0, "board")


def block(x):
    return lambda f: box(x - 7, -16.0, x + 7, 0.0)


def arc(j, r, a0, a1, dx=0, dy=0):
    return lambda f: {"at": at(f, j, dx, dy), "r": r, "from": a0, "to": a1}


def up_from(base, t, n):
    u = v(180 - t)
    return (base[0] + u[0] * n, base[1] + u[1] * n)


def stand(**kw):
    return S(**kw)


def plank_pose(t=66, feet=(0, 0), hands=None, ep="bu", **kw):
    hip = up_from(feet, t, 74)
    sh = up_from(hip, t, 50)
    return S(hip=hip, t=t, arm=hands or (sh[0], 0), leg=feet, ep=ep, **kw)


def knee_plank_pose(t=55, hands=None):
    hip = up_from((0, 0), t, 37)
    sh = up_from(hip, t, 50)
    return S(hip=hip, t=t, arm=hands or (sh[0], 0), leg=(-30, -24), kp="d", ep="bu")


TOP = plank_pose(66)
BOTTOM = plank_pose(80, hands=(TOP["ha"][0], 0))
ALL4 = S(hip=(0, -37), t=77, arm=(49, 0), leg=(-37, -1), kp="fd")
LIE = S(hip=(0, -6), t=90, arm=A(-90), leg=(-74, -6))            # on the back, head right
LIE_KNEES = S(hip=(0, -6), t=90, arm=A(-90), leg=(-40, 0), kp="u")
PRONE = S(hip=(0, -6), t=90, arm=A(90), leg=(-74, -6), ep="u")
SIT = S(hip=(0, -6), t=0, arm=A(20), leg=(74, -4), kp="u")
STAND_F = F()
GUARD = dict(arm=(28, -134), arm2=(22, -132), ep="d", leg=(14, 0), leg2=(-14, 0))
SQUAT = S(hip=(-22, -38), t=40, arm=A(90), leg=(6, 0))


def lunge(hip, front=(36, 0), back=(-56, 0), **kw):
    kw.setdefault("kp", "f")
    kw.setdefault("kp2", "d")
    return S(hip=hip, leg=front, leg2=back, **kw)


C = {}

# ---- Warm-up, cardio and recovery
C["march"] = clip("side", [S(arm=A(-30, 20), arm2=A(35, 25), leg=A(85, -95), leg2=(2, 0)), S(arm=A(35, 25), arm2=A(-30, 20), leg=(2, 0), leg2=A(85, -95))], 0.45, 0.1)
C["high-knees"] = clip("side", [S(hip=(0, -78), arm=A(-35, 70), arm2=A(45, 70), leg=A(100, -110), leg2=(2, -4)), S(hip=(0, -78), arm=A(45, 70), arm2=A(-35, 70), leg=(2, -4), leg2=A(100, -110))], 0.28, 0.04)
C["butt-kick"] = clip("side", [S(arm=A(-25, 70), arm2=A(30, 70), leg=A(-8, -160), leg2=(2, 0)), S(arm=A(30, 70), arm2=A(-25, 70), leg=(2, 0), leg2=A(-8, -160))], 0.3, 0.05)
C["march-reach"] = clip("side", [S(arm=A(-20, 15), arm2=A(175), leg=A(85, -95), leg2=(2, 0)), S(arm=A(175), arm2=A(-20, 15), leg=(2, 0), leg2=A(85, -95))], 0.5, 0.15)
C["easy-walk"] = clip("side", [S(arm=A(-20, 15), arm2=A(22, 15), leg=(26, 0), leg2=(-22, 0), hip=(2, -70)), S(arm=A(22, 15), arm2=A(-20, 15), leg=(-22, 0), leg2=(26, 0), hip=(2, -70))], 0.6, 0.05)
C["arm-circles"] = clip("front", [F(arm=A(86), arm2=A(86)), F(arm=A(94), arm2=A(94))], 0.35, 0.0, arrows=[arc("ha", 8, 0, 300), arc("ha2", 8, 0, 300)])
C["hip-circles"] = clip("front", [F(hip=(-6, -73), arm=A(40, -110), lean=4), F(hip=(6, -73), arm=A(40, -110), lean=-4)], 0.8, 0.2, arrows=[arc("c", 14, 20, 340)])
HANDS_HEAD = dict(arm=A(165, 150), ep="b")
C["good-morning"] = clip("side", [S(**HANDS_HEAD), S(hip=(-10, -72), t=80, arm=A(85, 150), leg=(2, 0))], 0.9, 0.5)
C["inchworm"] = clip("side", [S(hip=(-4, -72), t=155, arm=(26, 0), leg=(2, 0), head=15), plank_pose(66, feet=(-88, 0))], 1.2, 0.4)
C["childs-pose"] = hold_clip("side", S(hip=(-20, -38), t=0, arm=A(5), leg=(-45, -3), kp="f"),
                             S(hip=(-20, -16), t=100, arm=(85, -4), ep="u", leg=(-45, -3), kp="f", head=10))
C["wall-chest"] = hold_clip("side", S(arm=A(90, 90), ep="b"), S(arm=A(70, 110)), props=[wall(54)], arrows=[arc("sh", 18, 200, 320)])
C["hamstring-fold"] = hold_clip("side", S(), S(hip=(-6, -72), t=160, arm=A(4), leg=(2, 0), head=15))
C["breathing"] = clip("front", [F(arm=(-6, -88), ep="o"), F(arm=(-6, -88), ep="o", sw=18.5, head=-4)], 2.0, 1.0)

# ---- Push-ups and upper body
C["push-up"] = clip("side", [TOP, BOTTOM], 0.8, 0.3)
C["wide-push-up"] = C["push-up"]
C["diamond-push-up"] = C["push-up"]
KTOP = knee_plank_pose(55)
C["knee-push-up"] = clip("side", [KTOP, knee_plank_pose(78, hands=(KTOP["ha"][0], 0))], 0.8, 0.3)
IT = S(hip=up_from((0, 0), 42, 74), t=42, arm=(83, -42), leg=(0, 0))
IB = S(hip=up_from((0, 0), 61, 74), t=61, arm=(83, -42), leg=(0, 0), ep="bu")
C["incline-push-up"] = clip("side", [IT, IB], 0.8, 0.3, props=[chair(83, -42, 30)])
DT = S(hip=up_from((0, -40), 85.4, 74), t=85.4, arm=(123.6, 0), leg=(0, -40))
DB = S(hip=up_from((0, -40), 99, 74), t=99, arm=(123.6, 0), leg=(0, -40), ep="bu")
C["decline-push-up"] = clip("side", [DT, DB], 0.8, 0.3, props=[chair(-4, -40, 30)])
C["band-row"] = clip("side", [S(arm=A(86), hip=(-4, -72), leg=(12, 0), leg2=(-14, 0)), S(arm=A(-35, 125), hip=(-4, -72), leg=(12, 0), leg2=(-14, 0))], 0.7, 0.35,
                     props=[band("ha", (100, -100))])
C["underhand-band-row"] = C["band-row"]
C["towel-row"] = clip("side", [S(hip=up_from((0, 0), -26, 74), t=-26, arm=(78, -96), leg=(0, 0)), S(hip=up_from((0, 0), -10, 74), t=-10, arm=(78, -96), leg=(0, 0), ep="bd")], 0.8, 0.3,
                      props=[wall(86, 170)])
TR0 = S(hip=(0, -12), t=84, arm=(52, -66), leg=(-74, 0), ep="d", kp="u")
TR1 = S(hip=(0, -30), t=70, arm=(52, -66), leg=(-72, 0), ep="d", kp="u")
C["table-row"] = clip("side", [TR0, TR1], 0.8, 0.3, props=[lambda f: line((20, -68), (90, -68), 5)])
BK0 = S(hip=(0, -12), t=84, arm=(52, -66), leg=(-46, 0), kp="u", ep="d")
BK1 = S(hip=(0, -30), t=70, arm=(52, -66), leg=(-46, 0), kp="u", ep="d")
C["bent-knee-table-row"] = clip("side", [BK0, BK1], 0.8, 0.3, props=[lambda f: line((20, -68), (90, -68), 5)])
HANG = F(hip=(0, -60), arm=(-22, -168), ep="o", leg=(-6, 12), kp="f")
PULL = F(hip=(0, -86), arm=(-22, -168), ep="o", leg=(-6, -14), kp="f")
C["pull-up"] = clip("front", [HANG, PULL], 1.0, 0.4, floor=False, props=[bar(-170)])
C["chin-up"] = C["pull-up"]
C["negative-pull-up"] = clip("front", [PULL, HANG], 3.0, 0.6, floor=False, props=[bar(-170)])

# ---- Lower body
C["squat"] = clip("side", [S(arm=A(10, 10)), SQUAT], 0.9, 0.3)
C["chair-squat"] = clip("side", [S(arm=A(90)), S(hip=(-26, -44), t=36, arm=A(90), leg=(6, 0))], 0.9, 0.3, props=[chair(-44, -40, 30)])
C["reverse-lunge"] = clip("side", [S(leg=(0, 0), leg2=(-2, 0)), lunge((-10, -42), front=(0, 0), back=(-58, 0))], 0.9, 0.3)
C["static-lunge"] = clip("side", [lunge((-4, -62), front=(32, 0), back=(-40, 0)), lunge((-4, -40), front=(32, 0), back=(-40, 0))], 0.7, 0.3)
C["split-squat"] = clip("side", [lunge((-6, -62), front=(34, 0), back=(-56, -40)), lunge((-4, -38), front=(34, 0), back=(-56, -40))], 0.9, 0.3, props=[chair(-60, -40, 30)])
GB_UP = S(hip=(-2, -34), t=124, arm=(-6, -4), ep="u", leg=(-40, 0), kp="u")
C["glute-bridge"] = clip("side", [LIE_KNEES, GB_UP], 0.9, 0.4)
C["superman"] = clip("side", [PRONE, S(hip=(0, -6), t=76, arm=A(98), leg=(-72, -20), ep="u", head=-10)], 0.9, 0.6)
C["wall-sit"] = hold_clip("side", S(hip=(0, -74)), S(hip=(0, -37), arm=A(5, 10), leg=(37, 0), kp="fu"), props=[wall(-8, 150)])
C["calf-raise"] = clip("side", [S(arm=A(80)), S(hip=(0, -82), arm=A(78), leg=(2, -8))], 0.6, 0.4, props=[wall(52, 140)])
C["squat-calf-raise"] = clip("side", [SQUAT, S(hip=(0, -82), arm=A(10, 10), leg=(2, -8))], 0.7, 0.2)
C["squat-jump"] = clip("side", [S(hip=(-22, -38), t=40, arm=A(-40), leg=(6, 0)), S(hip=(0, -104), arm=A(176), leg=(2, -30))], 0.45, 0.2)
PIKE_T = S(hip=(30, -70), t=150, arm=(70, 0), leg=(0, 0), ep="u")
PIKE_B = S(hip=(36, -64), t=168, arm=(70, 0), leg=(0, 0), ep="bu")
C["pike-push-up"] = clip("side", [PIKE_T, PIKE_B], 0.9, 0.3)

# ---- Arms
C["lateral-raise"] = clip("front", [F(arm=A(8)), F(arm=A(88, 8))], 0.8, 0.3, props=[band("ha", (-14, 0)), band("ha2", (14, 0))])
C["curl"] = clip("side", [S(arm=A(14)), S(arm=A(14, 130))], 0.7, 0.3, props=[band("ha", (6, 0))])
C["hammer-curl"] = C["curl"]
C["overhead-press"] = clip("front", [F(arm=A(80, 100)), F(arm=A(172, 4))], 0.8, 0.3, props=[band("ha", (-14, 0)), band("ha2", (14, 0))])
C["triceps-extension"] = clip("side", [S(arm=A(160)), S(arm=A(158, 165))], 0.8, 0.3)
C["chair-dip"] = clip("side", [S(hip=(12, -44), t=-4, arm=(0, -40), leg=(76, 0), kp="u"), S(hip=(12, -20), t=-8, arm=(0, -40), leg=(72, 0), kp="u")], 0.8, 0.3, props=[chair(-10, -40, 34)])
C["bent-knee-dip"] = clip("side", [S(hip=(12, -44), t=-4, arm=(0, -40), leg=(46, 0), kp="u"), S(hip=(12, -20), t=-8, arm=(0, -40), leg=(46, 0), kp="u")], 0.8, 0.3, props=[chair(-10, -40, 34)])
C["shoulder-tap"] = clip("side", [TOP, S(hip=TOP["hp"], t=66, arm=(TOP["ha"][0], 0), arm2=(TOP["sh"][0] - 4, TOP["sh"][1] + 4), ep2="d", leg=(0, 0))], 0.5, 0.2)

# ---- Jumps and footwork
C["skater-hop"] = clip("front", [F(hip=(-32, -66), lean=-12, arm=A(30, 20), arm2=A(-30), leg=(-40, 0), leg2=(-20, -14), kp2=(1, 0)),
                                 F(hip=(32, -66), lean=12, arm=A(-30), arm2=A(30, 20), leg=(20, -14), leg2=(40, 0), kp=(-1, 0))], 0.5, 0.1)
C["skater-step"] = clip("front", [F(hip=(-26, -68), lean=-6, leg=(-34, 0), leg2=(-16, -6), kp2=(1, 0)), F(hip=(26, -68), lean=6, leg=(16, -6), leg2=(34, 0), kp=(-1, 0))], 0.7, 0.2)
C["lateral-shuffle"] = clip("front", [F(hip=(0, -62), arm=A(30, -60), leg=(-34, 0)), F(hip=(14, -64), arm=A(30, -60), leg=(0, 0), leg2=(28, 0))], 0.35, 0.1)
C["side-step"] = clip("front", [F(hip=(-12, -72), arm=A(40), leg=(-34, 0), leg2=(4, 0)), F(hip=(12, -72), arm=A(40), leg=(-4, 0), leg2=(34, 0))], 0.6, 0.15)
C["step-jack"] = clip("front", [F(hip=(6, -72), arm=A(160), leg=(-6, 0), leg2=(40, 0)), F(arm=A(8))], 0.5, 0.15)
C["split-jump"] = clip("side", [lunge((-8, -46), front=(30, 0), back=(-56, 0), arm=A(40, 30), arm2=A(-30, 30)), lunge((-8, -46), front=(-56, 0), back=(30, 0), arm=A(-30, 30), arm2=A(40, 30))], 0.4, 0.15)
CROUCH = S(hip=(-16, -34), t=55, arm=(30, 0), ep="bu", leg=(4, 0))
C["burpee"] = clip("side", [CROUCH, plank_pose(66, feet=(-82, 0), hands=(30, 0)), S(hip=(0, -86), arm=A(176), leg=(2, -12))], 0.55, 0.25)
C["step-back-burpee"] = clip("side", [CROUCH, plank_pose(66, feet=(-82, 0), hands=(30, 0)), S(arm=A(8, 12))], 0.8, 0.3)

# ---- Yoga and stretching
C["cat-cow"] = clip("side", [S(hip=(0, -37), t=84, arm=(49, 0), leg=(-37, -1), kp="fd", head=-30), S(hip=(0, -37), t=70, arm=(49, 0), leg=(-37, -1), kp="fd", head=45)], 1.6, 0.5)
DOG = S(hip=(34, -68), t=146, arm=(92, 0), ep="u", leg=(0, 0), head=5)
C["downward-dog"] = hold_clip("side", ALL4, DOG)
C["dolphin"] = hold_clip("side", ALL4, S(hip=(30, -64), t=146, arm=(92, -2), ep="d", leg=(0, 0)))
C["puppy"] = hold_clip("side", ALL4, S(hip=(0, -37), t=115, arm=(100, -4), ep="u", leg=(-37, -1), kp="fd", head=10))
C["low-lunge"] = hold_clip("side", lunge((-6, -34), front=(40, 0), back=(-55, -2), arm=A(10)), lunge((6, -30), front=(40, 0), back=(-55, -2), arm=A(176)))
C["hip-flexor"] = hold_clip("side", lunge((-6, -34), front=(40, 0), back=(-55, -2), arm=A(5)), lunge((8, -30), front=(40, 0), back=(-55, -2), arm=A(5), t=-4))
C["lizard"] = hold_clip("side", lunge((-6, -34), front=(40, 0), back=(-55, -2), arm=A(5)), lunge((2, -26), front=(40, 0), back=(-58, -2), t=62, arm=(36, 0), ep="bu"))
C["crescent-lunge"] = hold_clip("side", S(), lunge((-6, -50), front=(40, 0), back=(-62, 0), arm=A(176), kp2="f"))
C["warrior-one"] = hold_clip("side", S(), lunge((-8, -52), front=(38, 0), back=(-64, 0), arm=A(178), kp2="f"))
C["pyramid"] = hold_clip("side", S(hip=(0, -70), leg=(24, 0), leg2=(-24, 0)), S(hip=(-2, -70), t=125, arm=(38, -16), leg=(24, 0), leg2=(-24, 0), head=10), props=[block(38)])
C["warrior-three"] = hold_clip("side", S(), S(hip=(0, -74), t=90, arm=A(90), leg=(0, 0), leg2=A(-90)))
C["single-leg-reach"] = clip("side", [S(leg=(0, 0), leg2=A(80, -90)), S(t=90, arm=A(20), leg=(0, 0), leg2=A(-90))], 1.2, 0.6)
C["chair-pose"] = hold_clip("side", S(), S(hip=(-24, -52), t=30, arm=A(150), leg=(2, 0)))
C["bridge-pose"] = hold_clip("side", LIE_KNEES, GB_UP)
C["seated-fold"] = hold_clip("side", SIT, S(hip=(0, -6), t=58, arm=(70, -10), leg=(74, -4), kp="u", head=10))
C["seated-hamstring"] = hold_clip("side", S(hip=(0, -6), arm=A(20), leg=(74, -4), leg2=(26, -2), kp2="fu"),
                                  S(hip=(0, -6), t=58, arm=(70, -10), leg=(74, -4), leg2=(26, -2), kp="u", kp2="fu", head=10))
C["figure-four"] = hold_clip("side", LIE_KNEES, S(hip=(0, -6), t=90, arm=(-12, -48), ep="d", leg=(-14, -42), kp="fu", leg2=(-22, -52), kp2="u"))
C["reclined-toe"] = hold_clip("side", LIE, S(hip=(0, -6), t=90, arm=(10, -56), leg=(-2, -80), leg2=(-74, -6)), props=[lambda f: line(f["ha"], f["ft"], 2)])
C["happy-baby"] = hold_clip("side", LIE_KNEES, S(hip=(0, -6), t=90, arm=(14, -66), leg=(14, -66), kp="f"))
C["boat"] = hold_clip("side", SIT, S(hip=(0, -6), t=-35, arm=A(90), leg=A(130)))
C["crow"] = clip("side", [S(hip=(-4, -34), t=50, arm=(30, 0), ep="bu", leg=(0, 0)), S(hip=(6, -42), t=76, arm=(30, 0), ep="b", leg=(-4, -16), kp="f")], 1.0, 0.8)
C["garland"] = hold_clip("front", F(), F(hip=(0, -24), arm=(0, -60), ep="o", leg=(-22, 0), kp="o"))
C["goddess"] = hold_clip("front", F(), F(hip=(0, -46), arm=A(90, 90), leg=(-40, 0), kp="o"))
C["wide-fold"] = hold_clip("side", S(), S(hip=(-6, -66), t=160, arm=A(4), leg=(2, 0), head=15))
C["locust"] = clip("side", [PRONE, S(hip=(0, -6), t=76, arm=(10, -18), ep="u", leg=(-72, -18), head=-8)], 0.9, 0.7)
C["sphinx"] = hold_clip("side", PRONE, S(hip=(0, -6), t=64, arm=(70, -3), ep="d", leg=(-74, -6), head=-8))
C["pigeon"] = clip("side", [S(hip=(0, -14), t=-6, arm=(12, 0), ep="b", leg=(20, -2), kp="f", leg2=(-74, -4)),
                            S(hip=(0, -14), t=78, arm=(60, -2), ep="u", leg=(20, -2), kp="f", leg2=(-74, -4))], 1.4, 1.2)
C["supine-twist"] = hold_clip("front", F(arm=A(90), leg=(-12, 0)), F(arm=A(90), leg=(-12, 0), leg2=(-4, -38), kp2=(-1, 0)), floor=False, arrows=[arc("c", 22, 150, 300, 0, 10)])
C["final-rest"] = clip("side", [LIE, LIE], 2.0, 2.0)
C["centering"] = clip("front", [F(hip=(0, -6), arm=(-30, -14), ep="o", leg=(10, -2), kp="o")] * 2, 2.0, 2.0)
C["warrior-two"] = hold_clip("front", F(), F(hip=(-8, -58), arm=A(90), leg=(-52, 0), leg2=(40, 0)))
C["reverse-warrior"] = hold_clip("front", F(hip=(-8, -58), arm=A(90), leg=(-52, 0), leg2=(40, 0)), F(hip=(-6, -58), lean=18, arm=A(165), arm2=A(10), leg=(-52, 0), leg2=(40, 0)))
C["triangle"] = hold_clip("front", F(hip=(0, -64), leg=(-46, 0)), F(hip=(4, -62), lean=-70, arm=A(0), arm2=A(180), leg=(-46, 0)), props=[block(-46)])
C["side-angle"] = hold_clip("front", F(hip=(-8, -58), arm=A(90), leg=(-52, 0), leg2=(40, 0)), F(hip=(-6, -52), lean=-55, arm=(-40, -46), ep="o", arm2=A(-150), leg=(-52, 0), leg2=(40, 0)))
C["half-moon"] = hold_clip("front", F(hip=(0, -64), leg=(-46, 0)), F(hip=(-10, -73), lean=-82, arm=A(0), arm2=A(180), leg=(-12, 0), leg2=A(95)), props=[block(-46)])
C["tree"] = hold_clip("front", F(), F(arm=(0, -152), ep="o", leg=(0, -40), kp="o", leg2=(6, 0)))
C["standing-knee-hold"] = hold_clip("side", S(), S(arm=(24, -96), ep="b", leg=(0, 0), leg2=(10, -54), kp2="fu"))
C["single-leg-balance"] = hold_clip("side", S(), S(arm=A(40), leg=(0, 0), leg2=(14, -40), kp2="fu"))
TN0 = {"hd": (0, -79), "nk": (0, -66), "sh": (-28, -60), "sh2": (28, -60), "el": (-31, -30), "ha": (-34, 0), "el2": (31, -30), "ha2": (34, 0),
       "hp": (-10, -34), "hp2": (10, -34), "kn": (-22, 0), "ft": (-26, 0), "kn2": (22, 0), "ft2": (26, 0), "c": (0, -34)}
TN1 = dict(TN0, hd=(-22, -10), nk=(-7, -20), sh=(-30, -40), sh2=(10, -11), el=(-37, -19), el2=(-22, -2), ha2=(-64, -1))
C["thread-needle"] = hold_clip("front", TN0, TN1)

# ---- Flows: several key positions in order
COBRA = S(hip=(-80, -6), t=50, arm=(-42, 0), ep="b", leg=(-154, -6))
C["sun-flow-a"] = clip("side", [S(arm=A(166)), S(hip=(-6, -72), t=160, arm=A(4), head=15), plank_pose(66, feet=(-88, 0)), COBRA, S(hip=(-54, -68), t=146, arm=(4, 0), ep="u", leg=(-88, 0))], 0.9, 0.6)
UPDOG = S(hip=(-80, -18), t=40, arm=(-38, 0), leg=(-154, -6))
C["sun-flow-b"] = clip("side", [S(hip=(-24, -52), t=30, arm=A(150)), plank_pose(66, feet=(-88, 0)), plank_pose(80, feet=(-88, 0), hands=(25, 0)), UPDOG, lunge((-8, -52), front=(38, 0), back=(-64, 0), arm=A(178), kp2="f")], 0.9, 0.6)

# ---- Planks and core
C["high-plank"] = hold_clip("side", ALL4, TOP)
C["board-plank"] = hold_clip("side", ALL4, plank_pose(62, hands=(116, -8)), props=[board(116, 44)])
FP = S(hip=up_from((0, 0), 78, 74), t=78, arm=(145, -2), ep="d", leg=(0, 0))
C["forearm-plank"] = hold_clip("side", ALL4, FP)
KP = S(hip=up_from((0, 0), 72, 37), t=72, arm=(108, -2), ep="d", leg=(-30, -24), kp="d")
C["knee-plank"] = hold_clip("side", ALL4, KP)
def side_plank(lean, knees=False):
    feet = (0, 0)
    n = 37 if knees else 74
    u = v(180 - lean)
    hip = (feet[0] + u[0] * n, feet[1] + u[1] * n)
    sh = (hip[0] + u[0] * 50, hip[1] + u[1] * 50)
    legs = dict(leg=(-30, -12), kp=(0, 1)) if knees else dict(leg=feet)
    return F(hip=hip, lean=lean, sw=2, hw=2, arm=(sh[0] + 22, -2), ep=(0, 1), arm2=A(180), **legs)
C["side-plank"] = hold_clip("front", side_plank(84), side_plank(76))
C["knee-side-plank"] = hold_clip("front", side_plank(84, True), side_plank(70, True))
C["mountain-climber"] = clip("side", [S(hip=TOP["hp"], t=66, arm=(TOP["ha"][0], 0), leg=(52, -6), kp="d", leg2=(0, 0)),
                                      S(hip=TOP["hp"], t=66, arm=(TOP["ha"][0], 0), leg=(0, 0), leg2=(52, -6), kp2="d")], 0.3, 0.05)
C["slow-climber"] = clip("side", [S(hip=TOP["hp"], t=66, arm=(TOP["ha"][0], 0), leg=(52, -6), kp="d", leg2=(0, 0)),
                  S(hip=TOP["hp"], t=66, arm=(TOP["ha"][0], 0), leg=(0, 0), leg2=(52, -6), kp2="d")], 0.8, 0.4)
C["bird-dog"] = clip("side", [ALL4, S(hip=(0, -37), t=77, arm=A(92), arm2=(49, 0), leg=(-37, -1), kp="fd", leg2=A(-92))], 1.0, 0.8)
DB0 = S(hip=(0, -6), t=90, arm=A(180), leg=(-37, -43), kp="u")
C["dead-bug"] = clip("side", [DB0, S(hip=(0, -6), t=90, arm=A(100), arm2=A(180), leg=(-37, -43), kp="u", leg2=A(-96))], 1.0, 0.5)
C["hollow-hold"] = hold_clip("side", LIE, S(hip=(0, -6), t=72, arm=A(118), leg=A(-108)))
CR0 = S(hip=(0, -6), t=90, arm=(48, -20), ep="u", leg=(-40, 0), kp="u")
C["crunch"] = clip("side", [CR0, S(hip=(0, -6), t=62, arm=(36, -46), ep="u", leg=(-40, 0), kp="u")], 0.7, 0.3)
C["reverse-crunch"] = clip("side", [S(hip=(0, -6), t=90, arm=A(-90), leg=(-37, -43), kp="u"), S(hip=(4, -18), t=104, arm=A(-90), leg=(20, -52), kp="u")], 0.7, 0.3)
C["leg-raise"] = clip("side", [S(hip=(0, -6), t=90, arm=A(-90), leg=A(180)), S(hip=(0, -6), t=90, arm=A(-90), leg=A(-104))], 1.0, 0.3)
C["flutter-kick"] = clip("side", [S(hip=(0, -6), t=90, arm=A(-90), leg=A(-102), leg2=A(-116)), S(hip=(0, -6), t=90, arm=A(-90), leg=A(-116), leg2=A(-102))], 0.25, 0.0)
C["bridge-march"] = clip("side", [S(hip=(-2, -34), t=124, arm=(-6, -4), ep="u", leg=(-40, 0), kp="u", leg2=(-2, -60), kp2="u"),
                                  S(hip=(-2, -34), t=124, arm=(-6, -4), ep="u", leg=(-2, -60), kp="u", leg2=(-40, 0), kp2="u")], 0.7, 0.3)
C["russian-twist"] = clip("front", [F(hip=(0, -6), lean=-8, arm=(-34, -44), ep="o", arm2=(-30, -40), leg=(-16, -2), kp="o"),
                                    F(hip=(0, -6), lean=8, arm=(30, -40), arm2=(34, -44), ep="o", leg=(-16, -2), kp="o")], 0.6, 0.2, arrows=[arc("nk", 26, 200, 340, 0, 20)])
C["bicycle"] = clip("side", [S(hip=(0, -6), t=66, arm=(36, -70), ep="u", leg=(20, -40), kp="u", leg2=A(-104)), S(hip=(0, -6), t=66, arm=(36, -70), ep="u", leg=A(-104), leg2=(20, -40), kp2="u")], 0.6, 0.2)

# ---- Kettlebell, sandbag and carries
C["kettlebell-swing"] = clip("side", [S(hip=(-14, -66), t=72, arm=(-4, -34), ep="f", leg=(6, 0)), S(arm=A(90))], 0.6, 0.15, props=[bell("ha")])
C["kb-deadlift"] = clip("side", [S(hip=(-16, -54), t=68, arm=(12, -14), leg=(6, 0)), S(arm=A(2))], 0.9, 0.3, props=[bell("ha")])
C["goblet-squat"] = clip("side", [S(arm=(18, -108), ep="d"), S(hip=(-22, -38), t=30, arm=(8, -76), ep="d", leg=(6, 0))], 0.9, 0.3, props=[bell("ha")])
C["kb-press"] = clip("front", [F(arm2=A(10, 168)), F(arm2=A(176))], 0.8, 0.3, props=[bell("ha2")])
C["kb-row"] = clip("side", [S(hip=(-10, -64), t=72, arm=(36, -10), arm2=(16, -40), ep2="b", leg=(14, 0), leg2=(-26, 0)),
                            S(hip=(-10, -64), t=72, arm=(10, -56), ep="bu", arm2=(16, -40), ep2="b", leg=(14, 0), leg2=(-26, 0))], 0.8, 0.3, props=[bell("ha")])
C["halo"] = clip("front", [F(arm=(-2, -112), ep="o"), F(arm=(-2, -152), ep="o")], 0.9, 0.2, props=[bell("ha2")], arrows=[arc("hd", 22, 0, 330)])
HG0 = S(hip=(0, -6), t=90, arm=A(180), arm2=A(-60), leg=(-40, 0), kp="u", leg2=(-74, -6))
HG1 = S(hip=(0, -6), t=58, arm=A(180), arm2=(10, -4), ep2="d", leg=(-40, 0), kp="u", leg2=(-74, -6))
HG2 = S(hip=(0, -6), t=28, arm=A(180), arm2=(-26, 0), leg=(-40, 0), kp="u", leg2=(-74, -6))
C["half-get-up"] = clip("side", [HG0, HG1, HG2], 1.2, 0.6, props=[bell("ha")])
C["suitcase-carry"] = clip("side", [S(hip=(2, -70), arm=A(0), leg=(26, 0), leg2=(-22, 0)), S(hip=(2, -70), arm=A(0), leg=(-22, 0), leg2=(26, 0))], 0.6, 0.05, props=[bell("ha")])
C["farmer-carry"] = C["suitcase-carry"]
C["gi-row"] = clip("side", [S(hip=(-10, -64), t=72, arm=(36, -14), leg=(14, 0), leg2=(-26, 0)), S(hip=(-10, -64), t=72, arm=(12, -56), ep="bu", leg=(14, 0), leg2=(-26, 0))], 0.8, 0.3, props=[bag("ha")])
C["gi-drag"] = clip("side", [S(hip=(0, -50), t=-20, arm=A(60), leg=(26, 0), leg2=(-24, 0)), S(hip=(-8, -50), t=-24, arm=A(50, 20), leg=(-30, 0), leg2=(20, 0))], 0.6, 0.2,
                    props=[lambda f: {"kind": "bag", "r": 13, "pts": [(f["ha"][0] + 50, -13.0)], "tone": "prop"}, lambda f: {"kind": "band", "follow": "ha", "pts": [(f["ha"][0] + 50, -13.0)], "tone": "prop"}])
C["gi-hold"] = hold_clip("side", S(arm=A(10, 10)), S(arm=A(4)), props=[bag("ha")])
C["board-stand"] = hold_clip("front", F(hip=(0, -82), leg=(-16, -8)), F(hip=(0, -82), arm=A(70), leg=(-16, -8)), props=[board(0)])
C["board-squat"] = clip("front", [F(hip=(0, -82), leg=(-16, -8)), F(hip=(0, -54), arm=A(80), leg=(-16, -8), kp="o")], 1.0, 0.4, props=[board(0)])
C["board-rock"] = clip("front", [F(hip=(-3, -82), lean=-5, leg=(-16, -10), leg2=(16, -6)), F(hip=(3, -82), lean=5, leg=(-16, -6), leg2=(16, -10))], 0.8, 0.3, props=[board(0)])

# ---- Striking
C["fighting-stance"] = clip("side", [S(hip=(0, -72), **GUARD), S(hip=(0, -68), **GUARD)], 0.35, 0.1)
C["bounce"] = C["fighting-stance"]
C["jab"] = clip("side", [S(hip=(0, -72), **GUARD), S(hip=(0, -72), **dict(GUARD, arm=A(90)))], 0.25, 0.2)
C["jab-cross"] = clip("side", [S(hip=(0, -72), **dict(GUARD, arm=A(90))), S(hip=(2, -72), t=6, **dict(GUARD, arm2=A(92)))], 0.25, 0.15)
C["shadow-boxing"] = C["jab-cross"]
C["hook"] = clip("front", [F(arm=(-12, -128), ep="d"), F(lean=6, arm=A(82, -150), arm2=(14, -128), ep2="d")], 0.3, 0.2, arrows=[arc("sh", 30, 200, 300)])
C["uppercut"] = clip("side", [S(hip=(0, -64), **dict(GUARD, leg=(16, 0))), S(hip=(0, -72), **dict(GUARD, arm=A(30, 130)))], 0.3, 0.2)
C["front-kick"] = clip("side", [S(hip=(0, -72), **dict(GUARD, leg=A(90, -100), leg2=(-4, 0))), S(hip=(0, -72), t=-8, **dict(GUARD, leg=A(92), leg2=(-4, 0)))], 0.35, 0.2)
C["knee-strike"] = clip("side", [S(arm=A(150), leg=(2, 0), leg2=(-14, 0)), S(t=-6, arm=A(40, 90), leg=A(110, -130), leg2=(-4, 0))], 0.35, 0.2)
C["knee-drive"] = clip("side", [S(arm=A(160), leg=(14, 0), leg2=(-26, 0)), S(arm=A(-20, 40), leg=(2, 0), leg2=A(110, -130))], 0.45, 0.15)
C["side-kick"] = clip("front", [F(lean=10, arm=(-12, -128), ep="d", leg=(-6, -40), kp=(1, -1), leg2=(14, 0)), F(lean=30, arm=(-12, -128), ep="d", leg=A(95), leg2=(14, 0))], 0.35, 0.2)

# ---- Desk stretches not covered above
C["neck-stretch"] = hold_clip("front", F(), F(head=55, arm2=A(4)))
C["doorway-chest"] = hold_clip("side", S(arm=A(90, 90)), S(t=10, hip=(10, -72), arm=(-6, -150), ep="d", leg=(30, 0), leg2=(-14, 0)), props=[lambda f: line((-6, 0.0), (-6, -170.0), 4)])
C["cross-shoulder"] = hold_clip("front", F(), F(arm=(28, -108), ep=(0, 1), arm2=(-4, -98), ep2=(0, 1)))
C["quad-stretch"] = hold_clip("side", S(arm=A(80)), S(arm=A(80), arm2=(-14, -66), ep2="b", leg=(2, 0), leg2=A(-6, -168)), props=[wall(52, 140)])
C["calf-wall"] = hold_clip("side", S(arm=A(80)), S(hip=(-4, -70), t=22, arm=(44, -112), leg=(24, 0), leg2=(-34, 0)), props=[wall(48, 150)])


# ---- Hand close-ups (no body): the hand is the whole move
for mid, motion, bucket in (("grip-squeeze", "squeeze", False),):
    C[mid] = {"view": "hand", "hand": motion, "bucket": bucket, "frames": [{}, {}], "seconds": 0.55 if motion == "twist" else 0.35,
              "hold": 0.1 if motion == "twist" else 0.25, "floor": False, "still": 1}


def main():
    movements = json.loads(MOVES.read_text())["movements"]
    ids = [m["id"] for m in movements]
    missing = [i for i in ids if i not in C]
    extra = [i for i in C if i not in ids]
    if missing or extra:
        print("missing:", missing, "extra:", extra)
        sys.exit(1)
    for k, c in C.items():
        for f in c["frames"]:
            for j, (x, y) in f.items():
                if not (-4 <= x <= BOX_W + 4 and -4 <= y <= BOX_H + 4):
                    print(f"{k}: {j} out of box at {x},{y}")
                    sys.exit(1)
    OUT.write_text(json.dumps({"version": 1, "box": [BOX_W, BOX_H], "floor": FLOOR, "clips": {k: C[k] for k in ids}}, separators=(",", ":")) + "\n")
    print(f"Wrote {len(ids)} clips to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
