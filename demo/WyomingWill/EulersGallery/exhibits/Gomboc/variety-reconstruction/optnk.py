"""Conway (n,k)-spiral 0-skeletons: apex + n horizontal regular k-gons, equal point masses.
Fit ring radii/heights to maximise the mono-monostatic margins (relative to size)."""
import numpy as np, sys
from scipy.spatial import ConvexHull
from scipy.optimize import minimize
import opt21, opt21s
def make_verts(n,k):
    def verts(p):
        R=p[:n]; Z=p[n:]; V=[(0,0,1.0)]
        for i in range(n):
            for j in range(k):
                ph=2*np.pi*j/k; V.append((R[i]*np.cos(ph),R[i]*np.sin(ph),Z[i]))
        return np.array(V)
    return verts
def run(n,k,tries=20,seed=0):
    verts=make_verts(n,k)
    def score(p):
        if np.any(p[:n]<0.02): return 10
        V=verts(p)
        try: m=opt21s.margins_c(V,V.mean(0))
        except Exception: return 10
        if m is None: return 10
        return -min(m['face'],m['vert'],m['bottom'],m['top'])/np.ptp(V,axis=0).max()
    # start: Conway-like spiral, angles shrinking
    rng=np.random.default_rng(seed); best=None
    q=0.67; a1=160*(1-q)/(1-q**n); A=a1*q**np.arange(n)
    th=0;r=1;R=[];Z=[]
    for ai in A:
        th+=np.radians(ai); r*=np.cos(np.radians(ai)); R.append(r*np.sin(th)); Z.append(r*np.cos(th))
    base=np.array(R+Z)
    for t in range(tries):
        f=1+(1/np.cos(np.pi/k)-1)*rng.uniform(0,1)          # vertex radius between spiral and apothem
        x0=base.copy(); x0[:n]*=f
        if t: x0=x0*(1+0.15*rng.standard_normal(2*n))
        res=minimize(score,x0,method='Nelder-Mead',options=dict(maxiter=20000,xatol=1e-9,fatol=1e-12))
        if best is None or res.fun<best.fun: best=res
    return best, verts
if __name__=="__main__":
    n,k=int(sys.argv[1]),int(sys.argv[2])
    b,verts=run(n,k)
    V=verts(b.x)
    print(f"(n,k)=({n},{k}) vertices {len(V)}: margin {-b.fun*90:.3f} mm at 9 cm  ({'works' if b.fun<0 else 'FAILS'})",flush=True)
    np.save(f"nk_{n}_{k}.npy",b.x)
