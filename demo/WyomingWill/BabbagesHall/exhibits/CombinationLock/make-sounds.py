#!/usr/bin/env python3
"""
The safecracker's clicks: sounds/click-steep.wav and sounds/click-slope.wav,
what a contact microphone on the lock's case picks up when the fence meets
one of the cam's notch walls (the steep wall, turning right; the sloping
one, turning left); and sounds/click-pickup.wav, a lighter tick, when a
pin picks up a wheel (the dial's pin wheel 3, or a wheel's pin the next)
on the turns.

Not worked out from the physics, as the Newton's cradle's clack is: a
4 mm steel rod nudging a printed wall at 3 numbers a second makes almost no
sound in the air. A contact microphone hears the case ring instead, so
each click is a short knock (a millisecond of filtered noise) exciting a
few of the case's modes, each a decaying sine. The steep wall's is brighter
(it stops the rod squarely), the sloping wall's duller and softer (the rod
slides up it a little). 48 kHz, 16 bits, one channel, 0.15 s.

Run from this folder: python3 make-sounds.py (needs numpy).
"""
import os
import wave
import numpy as np

RATE = 48000
DUR = 0.15
rng = np.random.default_rng(1862)        # (Yale's Monitor Bank Lock: the same clicks every run)


def click(modes, knock_hz, level):
    """modes: (frequency Hz, decay time s, amplitude); knock_hz: the knock's
    low-pass corner (brighter knock, higher)."""
    n = int(RATE * DUR)
    t = np.arange(n) / RATE
    # the knock: a millisecond of noise, smoothed to knock_hz by a one-pole filter
    k = np.zeros(n)
    m = int(0.001 * RATE)
    k[:m] = rng.standard_normal(m) * np.hanning(m)
    a = np.exp(-2 * np.pi * knock_hz / RATE)
    for i in range(1, n):
        k[i] += a * k[i - 1]
    out = 0.35 * k / np.max(np.abs(k))
    # the case's modes, struck together
    for f, tau, amp in modes:
        out += amp * np.sin(2 * np.pi * f * t + rng.uniform(0, 2 * np.pi)) * np.exp(-t / tau)
    # a 0.5 ms rise, so it doesn't pop
    out[: int(0.0005 * RATE)] *= np.linspace(0, 1, int(0.0005 * RATE))
    return level * out / np.max(np.abs(out))


def write(path, x):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())
    print("  " + path)


os.makedirs("sounds", exist_ok=True)
write("sounds/click-steep.wav", click([(2350, 0.012, 1.0), (4100, 0.007, 0.6), (6900, 0.004, 0.35), (880, 0.020, 0.3)], 6000, 0.9))
write("sounds/click-pickup.wav", click([(3400, 0.006, 1.0), (5900, 0.004, 0.6), (8300, 0.003, 0.3)], 9000, 0.55))
write("sounds/click-slope.wav", click([(1650, 0.014, 1.0), (2900, 0.008, 0.5), (620, 0.024, 0.35)], 2500, 0.7))
