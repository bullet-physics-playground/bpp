"""Re-fit the 21-vertex polyhedron as a SOLID-LOOKING object: a thin polycarbonate
shell (closed faces) with a tungsten weight glued into each corner."""
import numpy as np
from scipy.spatial import ConvexHull
from scipy.optimize import minimize
from collections import defaultdict
from opt21 import verts
SIZE=9.0; T_MM=0.5; RHO_SHELL=1.2e-3; M_CORNER=0.0052; INSET=0.5   # cm
def mass_model(V):
    H=ConvexHull(V)
    faces=defaultdict(set)
    for simp,e in zip(H.simplices,H.equations): faces[tuple(np.round(e,6))].update(simp)
    cen=V.mean(0); pts=[]; ms=[]
    for v in V:
        d=cen-v; d/=np.linalg.norm(d); pts.append(v+INSET*d); ms.append(M_CORNER)
    for s in H.simplices:           # shell: triangles (area-weighted centroids)
        a,b,c=V[s]; A=0.5*np.linalg.norm(np.cross(b-a,c-a)); pts.append((a+b+c)/3); ms.append(A*T_MM/10*RHO_SHELL)
    pts=np.array(pts); ms=np.array(ms)
    return pts, ms, (pts*ms[:,None]).sum(0)/ms.sum(), H, faces
def margins_c(V,c):
    h,F=None,None
    H=ConvexHull(V)
    if len(H.vertices)!=len(V): return None
    F=defaultdict(set)
    for simp,e in zip(H.simplices,H.equations): F[tuple(np.round(e,6))].update(simp)
    fm=[]; bottom=None
    for key,vs in F.items():
        n=np.array(key[:3]); d=key[3]; vs=list(vs); p=c-(n@c+d)*n
        u=np.cross(n,[1,0,0]); u=u if np.linalg.norm(u)>1e-6 else np.cross(n,[0,1,0]); u/=np.linalg.norm(u); w=np.cross(n,u)
        q=np.c_[V[vs]@u,V[vs]@w]; pp=np.array([p@u,p@w]); hh=ConvexHull(q)
        out=np.max(hh.equations[:,:2]@pp+hh.equations[:,2])
        if n[2]<-0.999: bottom=-out
        else: fm.append(out)
    vm=[]
    for i in range(1,len(V)):
        d=V[i]-c; d/=np.linalg.norm(d); others=np.delete(np.arange(len(V)),i)
        vm.append(np.max((V[others]-V[i])@d))
    top=V[0]-c; top/=np.linalg.norm(top); topm=V[0]@top-np.max(V[1:]@top)
    return dict(face=min(fm),vert=min(vm),bottom=bottom if bottom is not None else -1,top=topm)
def scaled(p):
    V=verts(p); return V*SIZE/np.ptp(V,axis=0).max()
def score(p):
    if np.any(p[:4]<0.03): return 10
    try:
        V=scaled(p); _,_,c,_,_=mass_model(V); m=margins_c(V,c)
    except Exception: return 10
    if m is None: return 10
    return -min(m['face'],m['vert'],m['bottom'],m['top'])
if __name__=="__main__":
    p0=np.load("best21.npy"); best=None; rng=np.random.default_rng(2)
    print("start",score(p0))
    for t in range(40):
        x0=p0*(1+0.2*rng.standard_normal(8)) if t else p0
        r=minimize(score,x0,method='Nelder-Mead',options=dict(maxiter=8000,xatol=1e-8,fatol=1e-10))
        if best is None or r.fun<best.fun: best=r; print(t,"margin %.4f cm"%-r.fun, flush=True)
    np.save("best21s.npy",best.x); V=scaled(best.x); _,ms,c,_,_=mass_model(V)
    print(best.x.tolist()); print("mass %.1f g"%(ms.sum()*1e3), margins_c(V,c))
