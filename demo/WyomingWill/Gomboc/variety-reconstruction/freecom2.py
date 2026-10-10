import numpy as np, sys
from scipy.optimize import minimize
from scipy.spatial import ConvexHull
import opt21s as o
from optnk import make_verts
from eq import equilibria
def run(n,k,seeds=15):
    verts=make_verts(n,k)
    def score(x):
        p,zc=x[:-1],x[-1]
        if np.any(p[:n]<0.02): return 10
        V=verts(p); c=np.array([0,0,zc])
        try:
            H=ConvexHull(V)
            if np.max(H.equations[:,:3]@c+H.equations[:,3])>-1e-3: return 10   # COM must be inside
            m=o.margins_c(V,c)
        except Exception: return 10
        if m is None: return 10
        return -min(m.values())/np.ptp(V,axis=0).max()
    best=None
    for s in range(seeds):
        r2=np.random.default_rng(s); q=0.67; a1=160*(1-q)/(1-q**n); A=a1*q**np.arange(n); th=0;r=1;R=[];Z=[]
        for ai in A: th+=np.radians(ai); r*=np.cos(np.radians(ai)); R.append(r*np.sin(th)/np.cos(np.pi/k)); Z.append(r*np.cos(th))
        x0=np.r_[np.array(R+Z)*(1+0.15*r2.standard_normal(2*n)), np.mean(Z)*r2.uniform(0.5,1.5)]
        if score(x0)>=10: x0[-1]=np.mean(np.r_[1,Z])
        res=minimize(score,x0,method='Nelder-Mead',options=dict(maxiter=15000,xatol=1e-9,fatol=1e-12))
        if best is None or res.fun<best.fun: best=res
    V=verts(best.x[:-1]); c=np.array([0,0,best.x[-1]]); st,un,_=equilibria(V,c)
    s9=9/np.ptp(V,axis=0).max()
    return -best.fun*90, len(st), len(un), (c[2]-V[:,2].min())*s9
n,k=int(sys.argv[1]),int(sys.argv[2])
m,ns,nu,h=run(n,k)
print(f"free COM, ({n},{k}) {n*k+1} vertices: margin {m:+.2f} mm, exact count stable {ns} unstable {nu}, COM {h:.2f} cm above the bottom (9 cm tall)",flush=True)
