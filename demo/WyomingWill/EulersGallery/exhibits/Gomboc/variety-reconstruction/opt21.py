import numpy as np
from scipy.spatial import ConvexHull
from scipy.optimize import minimize, differential_evolution
K=5
def verts(p):
    R=p[:4]; Z=p[4:]
    V=[(0,0,1.0)]
    for i in range(4):
        for j in range(K):
            ph=2*np.pi*j/K
            V.append((R[i]*np.cos(ph), R[i]*np.sin(ph), Z[i]))
    return np.array(V)
def faces_of(V):
    h=ConvexHull(V); F={}
    for s,e in zip(h.simplices,h.equations):
        F.setdefault(tuple(np.round(e,6)),set()).update(s)
    return h,F
def margins(V):
    c=V.mean(0)
    try: h,F=faces_of(V)
    except Exception: return None
    if len(h.vertices)!=len(V): return None
    fm=[]; bottom=None
    for key,vs in F.items():
        n=np.array(key[:3]); d=key[3]; vs=list(vs)
        p=c-(n@c+d)*n
        u=np.cross(n,[1,0,0]);
        if np.linalg.norm(u)<1e-6: u=np.cross(n,[0,1,0])
        u/=np.linalg.norm(u); w=np.cross(n,u)
        q=np.c_[V[vs]@u,V[vs]@w]; pp=np.array([p@u,p@w])
        hh=ConvexHull(q)
        out=np.max(hh.equations[:,:2]@pp+hh.equations[:,2])  # >0 outside
        if n[2]<-0.999: bottom=-out   # bottom must be stable: inside depth
        else: fm.append(out)
    vm=[]
    for i in range(1,len(V)):
        d=V[i]-c; L=np.linalg.norm(d); d/=L
        vm.append(np.max((V-V[i])@d))   # >0 => some vertex further: not an equilibrium
    top=V[0]-c; top/=np.linalg.norm(top)
    topm=V[0]@top-np.max(np.delete(V,0,0)@top)
    return dict(face=min(fm), vert=min(vm), bottom=bottom if bottom is not None else -1, top=topm, nf=len(F))
def score(p):
    if np.any(p[:4]<0.02): return 10
    V=verts(p); m=margins(V)
    if m is None: return 10
    size=np.ptp(V,axis=0).max()
    return -min(m['face'],m['vert'],m['bottom'],m['top'])/size
if __name__=="__main__":
    A=[66.173,44.519,29.875,19.716]; th=0;r=1;R=[];Z=[]
    for a in A:
        th+=np.radians(a); r*=np.cos(np.radians(a)); R.append(r*np.sin(th)/np.cos(np.pi/5)); Z.append(r*np.cos(th))
    p0=np.array(R+Z)
    print("start",score(p0),margins(verts(p0)))
    best=None
    rng=np.random.default_rng(1)
    for t in range(30):
        x0=p0*(1+0.15*rng.standard_normal(8)) if t else p0
        r=minimize(score,x0,method='Nelder-Mead',options=dict(maxiter=6000,xatol=1e-7,fatol=1e-9))
        if best is None or r.fun<best.fun: best=r; print(t,r.fun)
    np.save("best21.npy",best.x)
    print(best.x.tolist(), margins(verts(best.x)))
