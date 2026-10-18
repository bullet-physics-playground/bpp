"""Fewest corners in the Conway (n,k)-spiral family for one stable face + one unstable
vertex, under different mass models:
  vertices : equal point masses at the corners (0-skeleton)
  edges    : uniform wire frame (1-skeleton)
  faces    : uniform thin shell (2-skeleton)
  solid    : uniform solid (3-skeleton)"""
import numpy as np, sys
from scipy.spatial import ConvexHull
from scipy.optimize import minimize
from collections import defaultdict
import opt21s as o
from optnk import make_verts
from eq import equilibria
def com(V, model):
    if model=="vertices": return V.mean(0)
    H=ConvexHull(V)
    if model=="faces":
        A=0; m=np.zeros(3)
        for s in H.simplices:
            a,b,c=V[s]; t=0.5*np.linalg.norm(np.cross(b-a,c-a)); A+=t; m+=t*(a+b+c)/3
        return m/A
    if model=="solid":
        c0=V.mean(0); vol=0; m=np.zeros(3)
        for s in H.simplices:
            a,b,c=V[s]; v=abs(np.dot(a-c0,np.cross(b-c0,c-c0)))/6; vol+=v; m+=v*(a+b+c+c0)/4
        return m/vol
    if model=="edges":
        F=defaultdict(list)
        for s,e in zip(H.simplices,H.equations): F[tuple(np.round(e,6))].append(s)
        E=set()
        for tris in F.values():
            cnt=defaultdict(int)
            for t in tris:
                for a,b in ((t[0],t[1]),(t[1],t[2]),(t[2],t[0])): cnt[tuple(sorted((a,b)))]+=1
            E|={e for e,c in cnt.items() if c==1}
        L=0; m=np.zeros(3)
        for a,b in E:
            l=np.linalg.norm(V[a]-V[b]); L+=l; m+=l*(V[a]+V[b])/2
        return m/L
def fit(n,k,model,seeds=12):
    verts=make_verts(n,k)
    def score(p):
        if np.any(p[:n]<0.02): return 10
        V=verts(p)
        try: m=o.margins_c(V,com(V,model))
        except Exception: return 10
        if m is None: return 10
        return -min(m.values())/np.ptp(V,axis=0).max()
    best=None
    for s in range(seeds):
        r2=np.random.default_rng(s); q=r2.uniform(0.55,0.8); tot=r2.uniform(140,175)
        a1=tot*(1-q)/(1-q**n); A=a1*q**np.arange(n); th=0;r=1;R=[];Z=[]
        for ai in A: th+=np.radians(ai); r*=np.cos(np.radians(ai)); R.append(r*np.sin(th)); Z.append(r*np.cos(th))
        x0=np.array(R+Z); x0[:n]*=1+(1/np.cos(np.pi/k)-1)*r2.uniform()
        if s: x0*=1+0.1*r2.standard_normal(2*n)
        res=minimize(score,x0,method='Nelder-Mead',options=dict(maxiter=20000,xatol=1e-9,fatol=1e-12))
        if best is None or res.fun<best.fun: best=res
    V=verts(best.x); st,un,_=equilibria(V,com(V,model))
    np.save(f"skel_{model}_{n}_{k}.npy",best.x)
    return -best.fun*90, len(st), len(un)
if __name__=="__main__":
    model=sys.argv[1]; n,k=int(sys.argv[2]),int(sys.argv[3])
    m,s,u=fit(n,k,model)
    print(f"{model:8s} ({n},{k}) {n*k+1:3d} corners: margin {m:+7.2f} mm  [{s} stable, {u} unstable]  {'WORKS' if m>0 and s==1 and u==1 else 'no'}",flush=True)
