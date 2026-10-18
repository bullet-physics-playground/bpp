"""Margin vs print size and wall thickness for the (6,6) family (supportless),
each re-optimised from the 15 cm / 1.0 mm design scaled."""
import numpy as np
from opt2 import run, evaluate
x15 = np.load('runs/a_6_6_t10.npy')
for size, t in [(8, 1.0), (10, 1.0), (12, 1.0), (18, 1.0), (15, 0.8), (15, 1.2), (15, 1.6), (10, 0.8)]:
    x0 = x15 * size / 15
    b = run(6, 6, t / 10, size, size, 1, 4, x0, verbose=False)
    sc, I = evaluate(b.x, 6, 6, t / 10, size, size, 1, full=True)
    np.save(f'runs/size_{size}_{t}.npy', b.x)
    print(f"size {size} cm, wall {t} mm: margin {-sc:.2f} mm, mass {I['M']:.0f} g, COM {I['zc']*10:.1f} mm, solid to {I['zs']*10:.1f} mm, PLA {I['vol']:.0f} cm3", flush=True)
