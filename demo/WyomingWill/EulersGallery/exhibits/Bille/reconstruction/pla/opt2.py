"""Fast co-design optimiser (symmetric evaluator sym.py; verified by core.py).
usage: python3 opt2.py n k t_mm Hmax_cm Dmax_cm supportless(0/1) seeds out.npy [x0.npy]
x = [R_0..R_{n-1}, Z_1..Z_{n-1}, H, zs] (cm); R = vertex (circum) radii.
Maximises the smallest margin (mm) over all non-base faces and non-apex
vertices: the distance the centre of mass would have to move to create an
extra equilibrium."""
import numpy as np, sys, warnings
from scipy.optimize import minimize
import sym
warnings.filterwarnings('ignore')
OVH = np.cos(np.radians(45)) + 1e-4

def unpack(x, n):
    return x[:n], np.r_[0.0, x[n:2 * n - 1]], x[2 * n - 1], x[2 * n]

def evaluate(x, n, k, t, Hmax, Dmax, supportless, full=False, minfloor=0.15):
    R, Z, H, zs = unpack(x, n)
    if np.any(R < 0.2) or np.any(np.diff(Z) < 0.01) or H < Z[-1] + 0.05: return 1e3, None
    P = sym.profile(R, Z, H, k)
    if not sym.convex_ok(P): return 1e3, None
    pen = 100 * max(0, H - Hmax) + 100 * max(0, 2 * R.max() - Dmax) + 100 * max(0, minfloor - zs)
    for (nr, nz), d in sym.seg_lines(P):
        if nz > OVH: pen += 50 * (nz - OVH)
        if supportless and nz < -OVH: pen += 50 * (-OVH - nz)
    try:
        M, zc, Izz, Ixx, vol, vv = sym.mass_z(R, Z, H, k, t, zs)
    except Exception:
        return 1e3, None
    if vv <= 0: pen += 10
    fm = sym.face_margins(P, zc); vm = sym.vertex_margins(R, Z, H, k, zc)
    m = 10 * min(fm.min(), vm.min())
    if zc <= 0 or zc >= H: return 1e3, None
    sc = -m + pen
    if full: return sc, dict(R=R, Z=Z, H=H, zs=zs, M=M, zc=zc, Izz=Izz, Ixx=Ixx, fm=fm, vm=vm, vol=vol, void=vv)
    return sc, None

def init(n, k, Hmax, Dmax, rng):
    a0 = rng.uniform(0.12, 0.4) * Dmax / 2 * 2
    c = rng.uniform(0.05, 0.8) * a0
    th0 = np.arctan2(c, a0)
    phis = np.sort(np.r_[-th0, rng.uniform(-th0, np.pi / 2, n - 1), np.pi / 2])
    phis = np.linspace(-th0, np.pi / 2, n + 1) if rng.uniform() < 0.5 else phis
    r0 = np.hypot(a0, c)
    g = np.log(max(1.05, (Hmax - c) / r0)) / (np.pi / 2 + th0)
    r = r0 * np.exp(g * (phis + th0))
    x = r * np.cos(phis); z = c + r * np.sin(phis)
    R = x[:n] / np.cos(np.pi / k); Z = z[:n] - z[0]; H = z[n] - z[0]
    s = min(Hmax / H, Dmax / (2 * R.max()))
    R *= s; Z *= s; H *= s
    return np.r_[R, Z[1:], H, max(0.2, rng.uniform(0.3, 1.0) * c * s)]

def run(n, k, t, Hmax, Dmax, sl, seeds, x0=None, verbose=True, seed=1):
    rng = np.random.default_rng(seed); best = None
    f = lambda x: evaluate(x, n, k, t, Hmax, Dmax, sl)[0]
    for s in range(seeds):
        if x0 is not None and s == 0: xs = x0.copy()
        elif x0 is not None and s < seeds // 3: xs = x0 * (1 + 0.03 * rng.standard_normal(len(x0)))
        else:
            for _ in range(200):
                xs = init(n, k, Hmax, Dmax, rng)
                if f(xs) < 100: break
        if f(xs) > 100: continue
        r = None
        for rep in range(3):
            r = minimize(f, xs if r is None else r.x, method='Nelder-Mead',
                         options=dict(maxiter=4000 * n, maxfev=4000 * n, xatol=1e-8, fatol=1e-10, adaptive=True))
        if best is None or r.fun < best.fun:
            best = r
            if verbose: print(f"  seed {s}: margin {-r.fun:.3f} mm", flush=True)
    return best

if __name__ == "__main__":
    n, k = int(sys.argv[1]), int(sys.argv[2]); t = float(sys.argv[3]) / 10
    Hmax, Dmax = float(sys.argv[4]), float(sys.argv[5]); sl = int(sys.argv[6]); seeds = int(sys.argv[7])
    x0 = np.load(sys.argv[9]) if len(sys.argv) > 9 else None
    b = run(n, k, t, Hmax, Dmax, sl, seeds, x0)
    sc, I = evaluate(b.x, n, k, t, Hmax, Dmax, sl, full=True)
    print(f"RESULT n={n} k={k} t={t*10:.1f}mm H<={Hmax} D<={Dmax} sl={sl}: margin {-sc:.3f} mm "
          f"(face {I['fm'].min()*10:.3f}, vert {I['vm'].min()*10:.3f}) mass {I['M']:.0f} g, zc {I['zc']:.3f} zs {I['zs']:.3f} "
          f"H {I['H']:.2f} D {2*I['R'].max():.2f}", flush=True)
    np.save(sys.argv[8], b.x)
