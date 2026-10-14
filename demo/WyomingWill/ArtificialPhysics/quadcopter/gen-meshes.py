"""Quadcopter meshes for the AP quadcopter demos.

    python3 gen-meshes.py meshes/

Writes frame.obj, front.obj and props.obj, all in metres, in the drone's
body frame: x forward, y up, z to the right, origin at the centre of mass.
The airframe is a generic 450 mm X quad (motor-to-motor 450 mm, so each
motor sits 0.225 m from the centre on a diagonal) with 10-inch props.

  frame.obj  centre plates, battery, the two rear arms, all four motors and
             the landing legs -- drawn in the drone's AP colour
  front.obj  the two front arms (+x side), drawn red, as on most real quads,
             so heading is visible
  props.obj  four thin prop discs (the blur of a spinning 10" prop), drawn
             translucent
"""
import math
import os
import sys

ARM = 0.225                    # motor distance from the centre
A = ARM / math.sqrt(2)         # motor x/z offset on the diagonals
PROP_R = 0.127                 # 10-inch prop
MOTOR_TOP = 0.040              # top of the motor bell
PROP_Y = 0.046                 # prop plane height


class Obj:
    def __init__(self):
        self.v, self.f = [], []

    def quad(self, a, b, c, d):
        self.f.append((a, b, c))
        self.f.append((a, c, d))

    def box(self, cx, cy, cz, sx, sy, sz, yaw=0.0):
        """a box of size sx*sy*sz centred at (cx,cy,cz), rotated by yaw about y"""
        c, s = math.cos(yaw), math.sin(yaw)
        base = len(self.v)
        for dx in (-sx / 2, sx / 2):
            for dy in (-sy / 2, sy / 2):
                for dz in (-sz / 2, sz / 2):
                    x = cx + dx * c - dz * s
                    z = cz + dx * s + dz * c
                    self.v.append((x, cy + dy, z))
        i = lambda dx, dy, dz: base + dx * 4 + dy * 2 + dz
        self.quad(i(0, 0, 0), i(1, 0, 0), i(1, 0, 1), i(0, 0, 1))  # bottom
        self.quad(i(0, 1, 0), i(0, 1, 1), i(1, 1, 1), i(1, 1, 0))  # top
        self.quad(i(0, 0, 0), i(0, 1, 0), i(1, 1, 0), i(1, 0, 0))  # -z
        self.quad(i(0, 0, 1), i(1, 0, 1), i(1, 1, 1), i(0, 1, 1))  # +z
        self.quad(i(0, 0, 0), i(0, 0, 1), i(0, 1, 1), i(0, 1, 0))  # -x
        self.quad(i(1, 0, 0), i(1, 1, 0), i(1, 1, 1), i(1, 0, 1))  # +x

    def cylinder(self, cx, cy, cz, r, h, n=20):
        """a closed cylinder along y, from cy - h/2 to cy + h/2"""
        base = len(self.v)
        for k in range(n):
            t = 2 * math.pi * k / n
            x, z = cx + r * math.cos(t), cz + r * math.sin(t)
            self.v.append((x, cy - h / 2, z))
            self.v.append((x, cy + h / 2, z))
        bot, top = len(self.v), len(self.v) + 1
        self.v.append((cx, cy - h / 2, cz))
        self.v.append((cx, cy + h / 2, cz))
        for k in range(n):
            a0, a1 = base + 2 * k, base + 2 * ((k + 1) % n)
            self.quad(a0, a1, a1 + 1, a0 + 1)
            self.f.append((bot, a1, a0))
            self.f.append((top, a0 + 1, a1 + 1))

    def write(self, path, comment):
        with open(path, "w") as f:
            f.write("# %s\n" % comment)
            for v in self.v:
                f.write("v %.5f %.5f %.5f\n" % v)
            for t in self.f:
                f.write("f %d %d %d\n" % (t[0] + 1, t[1] + 1, t[2] + 1))


def arm(o, sx, sz):
    """one arm from near the centre out to the motor at (sx*A, sz*A)"""
    yaw = math.atan2(sz, sx)
    r0, r1 = 0.045, ARM
    mid = (r0 + r1) / 2
    o.box(mid * math.cos(yaw), 0.006, mid * math.sin(yaw), r1 - r0, 0.016, 0.022, yaw)


def main(out):
    os.makedirs(out, exist_ok=True)

    frame = Obj()
    frame.box(0, 0.000, 0, 0.140, 0.004, 0.140, math.pi / 4)   # bottom plate
    frame.box(0, 0.028, 0, 0.115, 0.004, 0.115, math.pi / 4)   # top plate
    frame.box(0, 0.016, 0, 0.060, 0.022, 0.050)                # flight controller stack
    frame.box(0, -0.026, 0, 0.140, 0.036, 0.046)               # battery, slung underneath
    arm(frame, -1, 1)
    arm(frame, -1, -1)
    for sx in (-1, 1):
        for sz in (-1, 1):
            frame.cylinder(sx * A, 0.026, sz * A, 0.022, 0.028)          # motor bell
            frame.cylinder(sx * A, MOTOR_TOP + 0.003, sz * A, 0.006, 0.010, 10)  # prop hub
    for sx in (-1, 1):
        for sz in (-1, 1):
            frame.box(sx * 0.075, -0.040, sz * 0.075, 0.010, 0.060, 0.010)    # landing leg
            frame.box(sx * 0.075, -0.068, sz * 0.075, 0.022, 0.004, 0.022)    # foot
    frame.write(os.path.join(out, "frame.obj"),
                "450 mm X quad: plates, battery, rear arms, motors, legs (metres, x fwd, y up)")

    front = Obj()
    arm(front, 1, 1)
    arm(front, 1, -1)
    front.write(os.path.join(out, "front.obj"), "450 mm X quad: the two front (+x) arms")

    props = Obj()
    for sx in (-1, 1):
        for sz in (-1, 1):
            props.cylinder(sx * A, PROP_Y, sz * A, PROP_R, 0.002, 32)
    props.write(os.path.join(out, "props.obj"), "four 10-inch prop discs")


main(sys.argv[1] if len(sys.argv) > 1 else "meshes")
