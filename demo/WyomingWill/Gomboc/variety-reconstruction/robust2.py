"""Robustness for a real build: flat panels made accurately but ring sizes/heights
off by `err`, each weight's centre off by `err` in a random direction, weights
scattered 3% in mass. Returns the fraction still exactly 1 stable + 1 unstable."""
import numpy as np, sys
from scipy.spatial import ConvexHull
from optnk import make_verts
from eq import equilibria
import genshell as g
def com_of(V, wpos, wm):
    H=ConvexHull(V); sig=g.T_MM/10*g.RHO_PC; M=wm.sum(); mom=(wpos*wm[:,None]).sum(0)
    for s in H.simplices:
        a,b,c=V[s]; m=sig*0.5*np.linalg.norm(np.cross(b-a,c-a)); M+=m; mom+=m*(a+b+c)/3
    return mom/M
def trial(n,k,p,err,rng):
    q=p.copy(); V0=make_verts(n,k)(p); s=9.0/np.ptp(V0,axis=0).max()
    q=q+err/s*rng.standard_normal(len(q))            # ring radii and heights (cm errors)
    V=make_verts(n,k)(q)*s
    cen=V.mean(0); d=cen-V; d/=np.linalg.norm(d,axis=1)[:,None]
    wpos=V+g.INSET*d+err*rng.standard_normal(V.shape)
    wm=g.M_W*(1+0.03*rng.standard_normal(len(V)))
    st,un,_=equilibria(V,com_of(V,wpos,wm)); return len(st)==1 and len(un)==1
res={}
for name,(n,k,f) in {"p26":(5,5,"shell_5_5.npy"),"p37":(6,6,"shell_6_6.npy"),"p21-ideal":(4,5,"nk_4_5.npy")}.items():
    p=np.load(f); rng=np.random.default_rng(0); row=[]
    for err in (0.02,0.05,0.1):
        if name=="p21-ideal":
            g.T_MM=0.0; g.INSET=0.0
        else:
            g.T_MM=0.5; g.INSET=0.3
        row.append(np.mean([trial(n,k,p,err,rng) for _ in range(300)]))
    res[name]=row; print(name, "errors 0.2/0.5/1.0 mm ->", [f"{r*100:.0f}%" for r in row], flush=True)
