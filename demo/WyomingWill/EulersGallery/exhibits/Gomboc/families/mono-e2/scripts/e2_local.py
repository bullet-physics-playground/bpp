"""smooth local check: distance from the centre of mass over the exact radial surface, fine grid in a cap
around a direction; local minima / maxima and their persistence depths"""
import os, sys, numpy as np
REPO=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../monostable-search')
sys.path.insert(0,REPO); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import edged, smooth
from sphere_metrics import persist
a=np.load(REPO+'/genomes-edged/mono-e2.npy'); K,L=3,4
g7=edged.grid(L,7); A=a.reshape(K,g7.nb); sc=g7.scale
def rho(U):
    LR=(edged.Ybasis(L,U)*sc)@A.T; return np.exp(LR.min(1)), LR.argmin(1)
# centre of mass by quadrature on level 7 and level 8-ish check (level 7 only; level 8 memory)
r7,_=rho(g7.N); V=(r7**3*g7.w).sum()/3; G=((r7**4*g7.w)[:,None]*g7.N).sum(0)/(4*V)
B=edged.body(a,K,L,6); s=B['s']
print('scale mm/unit',s, 'G (units)',G)
def cap(center, radius_deg, n):
    c=center/np.linalg.norm(center); u=np.cross(c,[1,0,0]); u/=np.linalg.norm(u); v=np.cross(c,u)
    t=np.radians(np.linspace(-radius_deg,radius_deg,n)); T1,T2=np.meshgrid(t,t)
    U=c+np.tan(T1)[...,None]*u+np.tan(T2)[...,None]*v; U=U.reshape(-1,3); U/=np.linalg.norm(U,axis=1)[:,None]
    return U
def grid_edges(n):
    idx=np.arange(n*n).reshape(n,n); E=[np.c_[idx[:,:-1].ravel(),idx[:,1:].ravel()], np.c_[idx[:-1,:].ravel(),idx[1:,:].ravel()],
       np.c_[idx[:-1,:-1].ravel(),idx[1:,1:].ravel()]]
    return np.concatenate(E)
def check(center, rad, n, label):
    U=cap(center,rad,n); r,pc=rho(U); X=r[:,None]*U-G; d=np.linalg.norm(X,axis=1)*s
    E=grid_edges(n)
    # exclude minima on the cap boundary
    idx=np.arange(n*n).reshape(n,n); border=np.zeros(n*n,bool); border[idx[0]]=border[idx[-1]]=border[idx[:,0]]=border[idx[:,-1]]=True
    mins=[(dd*1000,v) for dd,v in persist(d,E) if not border[v]]
    maxs=[(dd*1000,v) for dd,v in persist(-d,E) if not border[v]]
    cu=np.degrees(np.arccos(np.clip(U@ (center/np.linalg.norm(center)),-1,1)))
    print(label, f'cap {rad} deg, {n}x{n} ({2*rad/(n-1)*60:.2f} arcmin), pieces {np.unique(pc)}')
    print('  minima (depth um, deg from centre, distance mm):',[(round(min(x,1e9),3), round(cu[v],2), round(d[v],4)) for x,v in mins[:5]])
    print('  maxima:',[(round(min(x,1e9),3), round(cu[v],2), round(d[v],4)) for x,v in maxs[:5]])
    return U,d,mins,maxs
# rest direction: minimum of distance on level-7 grid
d7=np.linalg.norm(r7[:,None]*g7.N-G,axis=1); u0=g7.N[np.argmin(d7)]; t0=g7.N[np.argmax(d7)]
print('rest dir',u0,'top dir',t0, 'angle', np.degrees(np.arccos(u0@t0)))
check(u0,8,801,'REST'); check(u0,3,901,'REST fine')
check(t0,6,801,'TOP')
