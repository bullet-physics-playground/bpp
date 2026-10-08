#!/usr/bin/env python3
# Synthesizes the two sound effects demo/koppi/hanoi.lua plays:
#   pick.wav  -- a stone lifted off a tower: a light, quiet tick
#   place.wav -- a stone set down on a tower: a duller, heavier wooden knock
# Mono, 16 bit, 44.1 kHz. Run from this directory: python3 make-sounds.py

import wave
import numpy as np

RATE = 44100
rng = np.random.default_rng(1)


def t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def ring(x, freq, tau, amp=1.0):
    # a damped sine: one resonant mode of the struck object
    return amp * np.sin(2 * np.pi * freq * x) * np.exp(-x / tau)


def click(x, tau, amp=1.0):
    # a burst of high-passed noise: the moment of contact
    n = rng.standard_normal(len(x))
    n = np.diff(n, prepend=0)
    return amp * n * np.exp(-x / tau) / 2


def save(name, samples, peak):
    attack = int(RATE * 0.0005) # no click from a hard start
    samples[:attack] *= np.linspace(0, 1, attack)
    samples = samples / np.abs(samples).max() * peak
    with wave.open(name, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((samples * 32767).astype("<i2").tobytes())


x = t(0.09)
save("pick.wav",
     ring(x, 1100, 0.008) + ring(x, 1900, 0.004, 0.5) + click(x, 0.004, 0.5),
     0.45)

x = t(0.25)
save("place.wav",
     ring(x, 150, 0.05) + ring(x, 330, 0.03, 0.7) + ring(x, 590, 0.015, 0.4)
     + click(x, 0.003, 0.6),
     0.9)
