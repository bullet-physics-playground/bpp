#!/usr/bin/env python3
"""
The clack of Newton's cradle, worked out from the physics: cradle-sounds/
clack-n<N>-v<U>.wav, the sound of N balls striking the row at U cm/s.

1. The strike, as the exhibit works it out: five steel balls (25 mm, 64 g)
   in a row, touching, N of them coming in at U; Hertz's law between
   neighbours (E* = E / (2 (1 - nu^2)), E 200 GPa, nu 0.3) with the
   exhibit's damping (a quarter of Hunt and Crossley's, alpha = 0.03 s/m);
   velocity Verlet, 20 ns steps. Out of it: each ball's acceleration
   through the strike, about a tenth of a millisecond.

2. The sound: a ball jerked along the row pushes the air in front of it and
   pulls it behind -- "acceleration noise", which is nearly all a Newton's
   cradle's clack is (the balls' own ringing is far above hearing: a 25 mm
   steel ball's lowest note is about 100 kHz). For each frequency, a rigid
   sphere of radius a moving with velocity U cos(wt) along x sends out
   exactly
        p(r, theta) = B cos(theta) h2(kr),  B = -i w rho U / (k h2'(ka))
   (h2 the spherical Hankel function of the second kind, order 1; time
   e^{iwt}). Each ball's sound is that, at its own distance and angle from
   the listener, all summed; and again from each ball's image under the
   table (the ball's centre 8.25 cm above it), at 0.85 of the strength;
   and a short, quiet room tail. The listener: 60 cm in front, 40 cm to
   the right, 15 cm up.

3. 48 kHz, 16 bits, one channel, 0.3 s. All the files share one scale, so
   their loudness is in proportion: the loudest (one ball at 100 cm/s)
   peaks at 0.95; the console says how loud the clack is, in pascals and
   dB, at the listener.

Usage: python3 make-sounds.py      (NumPy, SciPy)
"""

import math
import os
import wave

import numpy as np
from scipy.special import spherical_jn, spherical_yn

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "cradle-sounds")

R = 0.0125                       # m
RHO_STEEL = 7850.0
M = RHO_STEEL * 4 / 3 * math.pi * R ** 3
E_STAR = 200e9 / (2 * (1 - 0.3 ** 2))
K_H = 4 / 3 * E_STAR * math.sqrt(R / 2)
ALPHA = 0.25 * 0.12              # s/m
NB = 5
RHO_AIR, C_AIR = 1.204, 343.0
FS = 48000
DUR = 0.3
LISTENER = np.array([0.40, 0.15, 0.60])     # m, from the row's middle: right, up, in front
TABLE_H = 0.0825                             # the balls' centres above the table
REFLECT = 0.85


def strike(n, u, dt=2e-8, tmax=1.5e-3):
    """The row: n balls in at u (m/s). Returns the time step and each ball's acceleration."""
    x = np.zeros(NB)                 # displacement from the start
    w = np.zeros(NB)
    w[:n] = u
    steps = int(tmax / dt)
    acc = np.zeros((steps, NB))

    def forces(x, w):
        sq = x[:-1] - x[1:]          # squeeze of each contact (touching at the start)
        rate = w[:-1] - w[1:]
        f = np.where(sq > 0, K_H * np.clip(sq, 0, None) ** 1.5 * (1 + 1.5 * ALPHA * rate), 0.0)
        f = np.clip(f, 0, None)
        a = np.zeros(NB)
        a[:-1] -= f / M
        a[1:] += f / M
        return a

    a = forces(x, w)
    for s in range(steps):
        w += 0.5 * dt * a
        x += dt * w
        a = forces(x, w)
        w += 0.5 * dt * a
        acc[s] = a
    return dt, acc, w


def h2(nu, z):
    return spherical_jn(nu, z) - 1j * spherical_yn(nu, z)


def h2p(nu, z):
    return spherical_jn(nu, z, derivative=True) - 1j * spherical_yn(nu, z, derivative=True)


def sound(n, u):
    dt, acc, wout = strike(n, u)
    # each ball's acceleration, averaged to 1 MHz (its integral, the change
    # of speed, kept), and to frequency; only up to FS/2 is kept
    DEC = int(round(1e-6 / dt))
    acc = acc[: len(acc) // DEC * DEC].reshape(-1, DEC, NB).mean(axis=1)
    dtd = dt * DEC
    n_out = int(round(DUR * FS))
    N = int(round(DUR / dtd))
    f = np.fft.rfftfreq(N, dtd)[: n_out // 2 + 1]
    w = 2 * np.pi * f
    k = np.where(w > 0, w / C_AIR, 1e-9)
    P = np.zeros(len(f), complex)
    xs = (np.arange(NB) - (NB - 1) / 2) * 2 * R
    for i in range(NB):
        A = np.fft.rfft(acc[:, i], N)[: len(f)] * dtd     # its acceleration, by frequency (continuous transform)
        U = A / (1j * np.where(w > 0, w, 1e-9))            # its velocity
        B = -1j * w * RHO_AIR * U / (k * h2p(1, k * R))
        for src, gain in ((np.array([xs[i], 0.0, 0.0]), 1.0), (np.array([xs[i], -2 * TABLE_H, 0.0]), REFLECT)):
            d = LISTENER - src
            r = np.linalg.norm(d)
            cos = d[0] / r                                 # (the motion is along x, the row)
            P += gain * B * cos * h2(1, k * r)
    P[0] = 0
    # (a gentle roll-off over the top 6 kHz, rather than a brick wall at 24)
    P *= np.where(f > FS / 2 - 6000, 0.5 * (1 + np.cos(np.pi * np.clip(f - (FS / 2 - 6000), 0, 6000) / 6000)), 1.0)
    p = np.fft.irfft(P * FS, n_out)                        # the pressure at the listener, 48 kHz
    p = np.roll(p, int(0.005 * FS))                        # (5 ms of quiet before it)
    # a short, quiet room: a decaying hiss after the clack, 20 dB down
    rng = np.random.default_rng(int(n * 1000 + u * 100))
    t = np.arange(int(0.25 * FS)) / FS
    tail = rng.standard_normal(len(t)) * np.exp(-t / 0.05) * np.clip(t / 0.003, 0, 1)
    tail *= 10 ** (-20 / 20) / math.sqrt(np.sum(tail ** 2))
    tail[0] = 1.0
    return np.convolve(p, tail)[:n_out], wout


def write(path, p, scale):
    s = np.clip(p * scale, -1, 1)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(FS)
        wf.writeframes((s * 32767).astype("<i2").tobytes())


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    SPEEDS = (10, 20, 35, 60, 100)       # cm/s
    sounds = {}
    for n in (1, 2, 3, 4):
        for u in SPEEDS:
            p, wout = sound(n, u / 100)
            sounds[(n, u)] = p
            print(f"{n} in at {u} cm/s: peak {np.max(np.abs(p)):.2f} Pa "
                  f"({20 * math.log10(np.max(np.abs(p)) / 20e-6):.0f} dB peak); "
                  f"out: {' '.join(f'{x * 100:.1f}' for x in wout)} cm/s")
    top = max(np.max(np.abs(p)) for p in sounds.values())
    for (n, u), p in sounds.items():
        write(os.path.join(OUT, f"clack-n{n}-v{u}.wav"), p, 0.95 / top)
    # how loudness goes with speed (the exhibit scales between the files by it)
    ps = [np.max(np.abs(sounds[(1, u)])) for u in SPEEDS]
    slope = np.polyfit(np.log(SPEEDS), np.log(ps), 1)[0]
    print(f"peak pressure goes as speed^{slope:.2f} (one ball in); the loudest file: {top:.2f} Pa = 0.95")
