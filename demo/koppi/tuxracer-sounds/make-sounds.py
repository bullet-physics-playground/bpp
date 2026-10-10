#!/usr/bin/env python3
# Synthesizes the sound effects demo/koppi/tuxracer.lua plays:
#   fish.wav    -- a herring picked up: a bright two-note ping
#   jump.wav    -- Tux leaves the snow: a rising whoop
#   land.wav    -- touching down again: a soft thump in the snow
#   thud.wav    -- running into a tree: a heavy knock with a crunch
#   oops.wav    -- put back on the path after getting stuck: a falling slide
#   finish.wav  -- crossing the finish line: a short rising jingle
#   swish.wav   -- snow under the belly; the script repeats it, overlapping
#                  copies, louder the faster Tux goes
# Mono, 16 bit, 44.1 kHz. Run from this directory: python3 make-sounds.py

import wave
import numpy as np

RATE = 44100
rng = np.random.default_rng(7)


def t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def lowpass(x, cutoff):
    # one-pole low-pass
    a = 1 - np.exp(-2 * np.pi * cutoff / RATE)
    y = np.empty_like(x)
    acc = 0.0
    for i, s in enumerate(x):
        acc += a * (s - acc)
        y[i] = acc
    return y


def noise(n, lo=None, hi=None):
    x = rng.standard_normal(n)
    if hi:
        x = lowpass(x, hi)
    if lo:
        x = x - lowpass(x, lo)
    return x


def tone(x, freq, tau, amp=1.0, harmonics=(1.0,)):
    # a decaying note with a few overtones
    y = sum(h * np.sin(2 * np.pi * freq * (k + 1) * x)
            for k, h in enumerate(harmonics))
    return amp * y * np.exp(-x / tau)


def sweep(x, f0, f1):
    # sine with an exponential glide from f0 to f1 over the length of x
    f = f0 * (f1 / f0) ** (x / x[-1])
    return np.sin(2 * np.pi * np.cumsum(f) / RATE)


def save(name, samples, peak):
    attack = int(RATE * 0.0005)   # no click from a hard start
    samples[:attack] *= np.linspace(0, 1, attack)
    samples = samples / np.abs(samples).max() * peak
    with wave.open(name, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((samples * 32767).astype("<i2").tobytes())


# fish: C6 then G6, the second one rings on
x = t(0.35)
fish = tone(x, 1046.5, 0.05, 0.8, (1, 0.3)) \
     + np.where(x > 0.07, tone(np.maximum(x - 0.07, 0), 1568, 0.09, 1.0, (1, 0.3)), 0)
save("fish.wav", fish, 0.55)

# jump: a glide up with a little air in it
x = t(0.28)
env = np.sin(np.pi * x / x[-1]) ** 0.7
save("jump.wav", env * (sweep(x, 260, 760) + 0.25 * noise(len(x), 800, 4000)), 0.5)

# land: low-passed noise burst plus a low knock
x = t(0.22)
save("land.wav",
     np.exp(-x / 0.05) * noise(len(x), None, 900) * 3 + tone(x, 85, 0.06, 1.0),
     0.7)

# thud: heavy knock with a crunchy tail
x = t(0.38)
save("thud.wav",
     tone(x, 62, 0.09, 1.0) + tone(x, 130, 0.05, 0.7)
     + np.exp(-x / 0.04) * noise(len(x), 300, 3000) * 2.5,
     0.95)

# oops: a falling slide, wobbling
x = t(0.5)
wobble = 1 + 0.15 * np.sin(2 * np.pi * 9 * x)
save("oops.wav", np.exp(-x / 0.3) * sweep(x, 720, 190) * wobble, 0.5)

# finish: C5 E5 G5 C6, the last note held
notes = [(523.25, 0.00), (659.25, 0.12), (783.99, 0.24), (1046.5, 0.36)]
x = t(1.3)
fin = np.zeros(len(x))
for f, start in notes:
    xs = np.maximum(x - start, 0)
    fin += np.where(x >= start, tone(xs, f, 0.5 if f > 1000 else 0.12, 1.0, (1, 0.4, 0.15)), 0)
save("finish.wav", fin, 0.6)

# swish: band-passed noise with a smooth in/out envelope so that copies
# played 0.3 s apart blend into one steady hiss
x = t(0.5)
n = noise(len(x), 600, 5000)
save("swish.wav", np.sin(np.pi * x / x[-1]) ** 2 * n, 0.8)
