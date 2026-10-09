import numpy as np, opt21s as o
from scipy.optimize import minimize
import sys
T,M,INS=map(float,sys.argv[1:4]); o.T_MM=T; o.M_CORNER=M; o.INSET=INS
p0=np.load("best21.npy"); rng=np.random.default_rng(3); best=None
for t in range(15):
    x0=p0*(1+0.2*rng.standard_normal(8)) if t else p0
    r=minimize(o.score,x0,method='Nelder-Mead',options=dict(maxiter=6000,xatol=1e-8,fatol=1e-10))
    if best is None or r.fun<best.fun: best=r
V=o.scaled(best.x); _,ms,c,_,_=o.mass_model(V)
print(f"shell {T} mm corner {M*1e3:.1f} g inset {INS*10:.0f} mm: margin {-best.fun*10:.3f} mm, mass {ms.sum()*1e3:.0f} g, shell {ms[21:].sum()*1e3:.1f} g", np.round(best.x,4).tolist(), flush=True)
np.save(f"s_{T}_{M}_{INS}.npy",best.x)
