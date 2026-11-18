import os, sys, numpy as np, time
REPO=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../monostable-search')
sys.path.insert(0,REPO); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import edged, prescreen
from sphere_metrics import *
from scipy.spatial import ConvexHull
a=np.load(REPO+'/genomes-edged/mono-e2.npy')
X=edged.body(a,3,4,6)['X']; B=Body(X,4); P=B.P            # principal frame, mm at 90, COM origin
# --- overhang over cut planes through the centre of mass
H=ConvexHull(P); F=H.simplices; c0=P[F].mean(1)
n=np.cross(P[F[:,1]]-P[F[:,0]],P[F[:,2]]-P[F[:,0]]); ar=np.linalg.norm(n,axis=1)/2; n/=np.linalg.norm(n,axis=1)[:,None]
fl=(n*c0).sum(1)<0; n[fl]*=-1
D,_=icosphere(5); D=D[D[:,2]>=0]
worst=[]
for c in D:
    side=c0@c; up=np.where(side>=0,1,-1)
    dn=(n@c)*up                          # component of normal along each half's build direction
    worst.append(dn.min())
worst=np.array(worst); j=np.argmax(worst)
ang=lambda v: np.degrees(np.arcsin(-v)) if v<0 else 0.0
print('best plane through G: worst downward tilt %.1f deg below horizontal (0 = no overhang); normal'%ang(worst[j]), D[j])
print('share of planes with overhang <= 45 deg: %.1f%%'%(100*(worst>=-np.sin(np.radians(45))).mean()))
# the across cut used by prescreen: x = least-inertia axis projected off the rest normal
Pf=prescreen.to_frame(P)      # printing frame, mm at 36
xa=np.array([1.,0,0]); 
c=np.linalg.lstsq(P*0.4,Pf,rcond=None)[0][:,0]; c/=np.linalg.norm(c)
side=c0@c; dn=(n@c)*np.where(side>=0,1,-1); print('across cut (prescreen frame): worst overhang %.1f deg; dist from best plane normal %.1f deg'%(ang(dn.min()), np.degrees(np.arccos(abs(c@D[j])))))
# --- printed hulls, slips, extra rests and stall
t=time.time(); hv=prescreen.layered(Pf); print('layered',time.time()-t)
for case in ('al','sy','sz'):
    Y=prescreen.printed(hv,case); Pp=prescreen.prep(Y/0.4)
    er=prescreen.extra_rests(Pp)
    st=prescreen.stall(Pp,mus=(0.05,0.15,0.3))
    print(f'{case}: hull pts {len(Y)}  extra rests >2um: {len(er)} {np.round(er[:5]*1000,1)} um  predicted stall at mu 0.05/0.15/0.3: '+'/'.join(f'{100*x:.1f}%' for x in st), flush=True)
    np.save(f'e2_printed_{case}.npy',Y)
