"""lever of the exact smooth faces of mono-e2 (no facets): local minima of |tangential part of x-G| over the surface,
refined by Nelder-Mead; plus the crease minimum from e2_crease.py"""
import os, sys, numpy as np
from scipy.optimize import minimize
REPO=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../monostable-search')
sys.path.insert(0,REPO); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import edged
from sphere_metrics import persist, icosphere, edges
a=np.load(REPO+'/genomes-edged/mono-e2.npy'); K,L=3,4
g=edged.grid(L,7); A=a.reshape(K,g.nb); sc=g.scale
F=lambda U: (edged.Ybasis(L,U)*sc)@A.T
LR=F(g.N); r=np.exp(LR.min(1)); V=(r**3*g.w).sum()/3; G=((r**4*g.w)[:,None]*g.N).sum(0)/(4*V)
s=edged.body(a,K,L,6)['s']
def lever(U, k=None):
    U=U/np.linalg.norm(U,axis=1)[:,None]; LL=F(U); kk=LL.argmin(1) if k is None else k
    e=1e-6; t1=np.cross(U,[0.3,0.5,0.8]); t1/=np.linalg.norm(t1,axis=1)[:,None]; t2=np.cross(U,t1)
    def fk(W): W=W/np.linalg.norm(W,axis=1)[:,None]; return F(W)[np.arange(len(U)),kk]
    g1=(fk(U+e*t1)-fk(U-e*t1))/(2*e); g2=(fk(U+e*t2)-fk(U-e*t2))/(2*e)
    n=U-g1[:,None]*t1-g2[:,None]*t2; n/=np.linalg.norm(n,axis=1)[:,None]
    R=np.exp(LL[np.arange(len(U)),kk])[:,None]*U-G
    gap=np.sort(LL,1)[:,1]-LL.min(1)
    return np.linalg.norm(R-(R*n).sum(1)[:,None]*n,axis=1)*s, n, kk, gap, np.linalg.norm(R,axis=1)*s
N,Fc=g.N,g.F; E=edges(Fc)
lv,n,kk,gap,dist=lever(N)
rest_n=n[np.argmin(np.where(gap>0,lv+1e3*(dist-dist.min()),1e9))]
pm=persist(lv,E)
res=[]
for d,v in pm[:40]:
    u0=N[v]; k0=kk[v]
    e1=np.cross(u0,[1,0,0]); e1/=np.linalg.norm(e1); e2=np.cross(u0,e1)
    f=lambda p: lever((u0+p[0]*e1+p[1]*e2)[None])[0][0]
    o=minimize(f,[0,0],method='Nelder-Mead',options=dict(xatol=1e-9,fatol=1e-9,maxiter=600))
    uu=u0+o.x[0]*e1+o.x[1]*e2; lv1,n1,k1,gap1,d1=lever(uu[None])
    tilt=np.degrees(np.arccos(np.clip(n1[0]@rest_n,-1,1)))
    res.append((lv1[0],tilt,d1[0],k1[0],gap1[0],d))
seen=[]
print('smooth-face lever minima (mm at 90 | at 36), tilt from rest, centre-of-mass height, piece, log-gap to other piece')
for lv1,tilt,d1,k1,gap1,d in sorted(res):
    if any(abs(tilt-t0)<0.3 and abs(d1-h0)<0.01 for t0,h0 in seen): continue
    seen.append((tilt,d1)); print(f'  {lv1:.5f} | {0.4*lv1:.5f}   tilt {tilt:6.1f}   h {d1:.3f}   piece {k1}   gap {gap1:.4f}')
