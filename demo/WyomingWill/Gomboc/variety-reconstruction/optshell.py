"""Fit a Conway (n,k)-spiral polyhedron that works as a REAL object: a thin
polycarbonate shell (all faces) with a tungsten weight in every corner, its
centre INSET cm inside the corner (towards the body's middle)."""
import numpy as np, sys
from scipy.optimize import minimize
import opt21s as o
from optnk import make_verts
n,k=int(sys.argv[1]),int(sys.argv[2]); T=float(sys.argv[3]); M=float(sys.argv[4]); INS=float(sys.argv[5])
o.T_MM=T; o.M_CORNER=M; o.INSET=INS
verts=make_verts(n,k)
def scaled(p): V=verts(p); return V*9.0/np.ptp(V,axis=0).max()
def score(p):
    if np.any(p[:n]<0.02): return 10
    try:
        V=scaled(p); _,_,c,_,_=o.mass_model(V); m=o.margins_c(V,c)
    except Exception: return 10
    if m is None: return 10
    return -min(m['face'],m['vert'],m['bottom'],m['top'])
p0=np.load(f"nk_{n}_{k}.npy"); rng=np.random.default_rng(5); best=None
for t in range(12):
    x0=p0 if t==0 else p0*(1+0.1*rng.standard_normal(len(p0)))
    r=minimize(score,x0,method='Nelder-Mead',options=dict(maxiter=20000,xatol=1e-9,fatol=1e-12))
    if best is None or r.fun<best.fun: best=r
V=scaled(best.x); _,ms,c,_,_=o.mass_model(V)
print(f"({n},{k}) shell {T} mm, {M*1e3:.1f} g weights {INS*10:.0f} mm in: margin {-best.fun*10:.2f} mm (point-mass fit gave {score(p0)*-10:.2f}), mass {ms.sum()*1e3:.0f} g",flush=True)
np.save(f"shell_{n}_{k}.npy",best.x)
