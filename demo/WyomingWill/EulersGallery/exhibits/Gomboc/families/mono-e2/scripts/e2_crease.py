"""trace mono-e2's crease (pieces 0|1) exactly and look for equilibria on it:
an equilibrium on a crease = radial vector (p-G) perpendicular to the crease tangent AND inside the cone of the
two face normals."""
import os, sys, numpy as np
REPO=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../monostable-search')
sys.path.insert(0,REPO); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import edged
a=np.load(REPO+'/genomes-edged/mono-e2.npy'); K,L=3,4
g=edged.grid(L,7); A=a.reshape(K,g.nb); sc=g.scale
F=lambda U: (edged.Ybasis(L,U)*sc)@A.T
LR=F(g.N); piece=LR.argmin(1); r=np.exp(LR.min(1)); V=(r**3*g.w).sum()/3; G=((r**4*g.w)[:,None]*g.N).sum(0)/(4*V)
s=edged.body(a,K,L,6)['s']
print('pieces present',np.unique(piece,return_counts=True))
ea,eb=g.E.T; cut=piece[ea]!=piece[eb]; ca,cb=ea[cut],eb[cut]; k1,k2=piece[ca],piece[cb]
print('crease edges',cut.sum(), 'pairs',set(zip(*np.unique(np.sort(np.c_[k1,k2],1),axis=0).T)))
# bisection on great-circle arc
lo=np.zeros(len(ca)); hi=np.ones(len(ca))
def U_at(t): 
    U=(1-t)[:,None]*g.N[ca]+t[:,None]*g.N[cb]; return U/np.linalg.norm(U,axis=1)[:,None]
idx=np.arange(len(ca))
for _ in range(40):
    m=(lo+hi)/2; Lm=F(U_at(m)); f=Lm[idx,k1]-Lm[idx,k2]     # <0 on k1 side
    lo=np.where(f<0,m,lo); hi=np.where(f<0,hi,m)
U=U_at((lo+hi)/2); Lc=F(U); rc=np.exp(Lc[idx,k1]); P=rc[:,None]*U
# order along the crease: nearest-neighbour chain
from scipy.spatial import cKDTree
n=len(P); used=np.zeros(n,bool); order=[0]; used[0]=True; T=cKDTree(P)
for _ in range(n-1):
    d,j=T.query(P[order[-1]],k=12); j=[x for x in j if not used[x]]
    if not j: 
        rem=np.where(~used)[0]; jj=rem[np.argmin(np.linalg.norm(P[rem]-P[order[-1]],axis=1))]; print('jump',np.linalg.norm(P[jj]-P[order[-1]])*s); j=[jj]
    order.append(j[0]); used[j[0]]=True
P=P[order]; U=U[order]; K1=k1[order]; K2=k2[order]
close=np.linalg.norm(P[0]-P[-1])*s; print('crease points',n,'loop closure gap mm',close, 'length mm', np.linalg.norm(np.diff(P,axis=0),axis=1).sum()*s)
# analytic tangent: on the sphere t_u = u x grad_S(f_a - f_b) (a<b, consistent orientation), lifted to the surface
ka=np.minimum(K1,K2); kb=np.maximum(K1,K2)
def sgrad(U,k):
    e=1e-6; t1=np.cross(U,[0.3,0.5,0.8]); t1/=np.linalg.norm(t1,axis=1)[:,None]; t2=np.cross(U,t1)
    def fk(V): V=V/np.linalg.norm(V,axis=1)[:,None]; return F(V)[np.arange(len(U)),k]
    return ((fk(U+e*t1)-fk(U-e*t1))/(2*e))[:,None]*t1+((fk(U+e*t2)-fk(U-e*t2))/(2*e))[:,None]*t2
ga=sgrad(U,ka); gb=sgrad(U,kb); tu=np.cross(U,ga-gb); tu/=np.linalg.norm(tu,axis=1)[:,None]
Tg=tu+(ga*tu).sum(1)[:,None]*U; Tg/=np.linalg.norm(Tg,axis=1)[:,None]
R=P-G; Rn=R/np.linalg.norm(R,axis=1)[:,None]
phi=(Rn*Tg).sum(1)                       # sin of angle radial vs normal plane of the crease
# face normals of each piece at the crease point: n ∝ u - grad_S f  (r = exp f)
def normal(U,k):
    e=1e-6; out=[]
    t1=np.cross(U,[0.3,0.5,0.8]); t1/=np.linalg.norm(t1,axis=1)[:,None]; t2=np.cross(U,t1)
    f0=F(U)[np.arange(len(U)),k]
    def fk(V): V=V/np.linalg.norm(V,axis=1)[:,None]; return F(V)[np.arange(len(U)),k]
    g1=(fk(U+e*t1)-fk(U-e*t1))/(2*e); g2=(fk(U+e*t2)-fk(U-e*t2))/(2*e)
    nn=U-g1[:,None]*t1-g2[:,None]*t2; return nn/np.linalg.norm(nn,axis=1)[:,None]
N1=normal(U,K1); N2=normal(U,K2)
# is Rn inside the cone of N1,N2 (after projecting into their plane)?
Mb=np.cross(N1,N2); Mb/=np.linalg.norm(Mb,axis=1)[:,None]
Rp=Rn-(Rn*Mb).sum(1)[:,None]*Mb
inside=((np.cross(N1,Rp)*Mb).sum(1)*(np.cross(Rp,N2)*Mb).sum(1))>0
dihedral=np.degrees(np.arccos(np.clip((N1*N2).sum(1),-1,1)))
dist=np.linalg.norm(R,axis=1)*s
sm=np.convolve(np.r_[phi[-4:],phi,phi[:4]],np.ones(9)/9,'valid')
sc_=np.where(np.sign(sm[:-1])!=np.sign(sm[1:]))[0]
print('dihedral (deg, exterior angle between normals): min %.2f  median %.2f  max %.2f'%(dihedral.min(),np.median(dihedral),dihedral.max()))
print('radial direction inside the normal cone at %.1f%% of crease points'%(100*inside.mean()))
print('sign changes of phi (radial perpendicular to crease):')
for i in sc_: print(f'   i {i}  dist {dist[i]:.4f} mm  inside cone {inside[i]}  dihedral {dihedral[i]:.2f}')
ins=np.where(inside)[0]
print('distance along crease: max %.4f  min %.4f mm'%(dist.max(),dist.min()))
# margin: smallest |phi| over in-cone points away from the top (more than 10 deg of arc)
top=np.argmax(dist); arc=np.degrees(np.arccos(np.clip(Rn@Rn[top],-1,1)))
far=inside&(arc>10)
print('min |phi| (rad) on in-cone crease points >10 deg from the top: %.4f, lever there %.3f mm at 90'%(np.abs(phi[far]).min(), (np.abs(phi[far])*dist[far]).min()))
np.savez('e2_crease.npz',P=(P-G)*s,inside=inside,dist=dist,phi=phi,dihedral=dihedral)
# weak spot: smooth lever on both faces in a cap around the crease minimum
i0=np.argmin(dist); u0=U[i0]
c=u0; e1=np.cross(c,[1,0,0]); e1/=np.linalg.norm(e1); e2=np.cross(c,e1)
nn=1201; t=np.radians(np.linspace(-6,6,nn)); T1,T2=np.meshgrid(t,t)
UU=(c+np.tan(T1)[...,None]*e1+np.tan(T2)[...,None]*e2).reshape(-1,3); UU/=np.linalg.norm(UU,axis=1)[:,None]
LL=F(UU); kk=LL.argmin(1); gap=np.sort(LL,1)[:,1]-LL.min(1)
nrm=normal(UU,kk); RR=np.exp(LL.min(1))[:,None]*UU-G
lev=np.linalg.norm(RR-(RR*nrm).sum(1)[:,None]*nrm,axis=1)*s
away=gap>2e-4
print('weak spot: crease min at %.4f mm from G; smooth lever in a 6 deg cap (faces, off the crease): min %.4f mm at 90 = %.4f mm at 36'%(dist[i0],lev[away].min(),0.4*lev[away].min()))
j=np.argmin(np.where(away,lev,np.inf)); print('  at', np.degrees(np.arccos(UU[j]@c)),'deg from the crease minimum, piece',kk[j],'height',np.linalg.norm(RR[j])*s)
