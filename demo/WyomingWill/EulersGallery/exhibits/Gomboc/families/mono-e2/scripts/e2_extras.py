import os, sys, numpy as np
REPO=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../monostable-search')
sys.path.insert(0,REPO); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import edged
from sphere_metrics import *
a=np.load(REPO+'/genomes-edged/mono-e2.npy')
lev=int(sys.argv[1]); dl=int(sys.argv[2])
Bd=edged.body(a,3,4,lev); X=Bd['X']
B=Body(X,dl)
print('counts',B.counts())
# crease points are X[n0:]; tilt and distance of the support point to the nearest crease point (body frame)
vV,G,I,H=hull_mass(X); w,R=np.linalg.eigh(I); R[:,2]*=np.linalg.det(R)
C=(X[Bd['n0']:]-G)@R
from scipy.spatial import cKDTree
kt=cKDTree(C); t=B.tilt()
for name,L in (('min',B.mins),('max',B.maxs)):
  for d,v in L[:6]:
    p=B.P[B.k[v]]; print(name, f'depth {d*1000:.2f} um  tilt {t[v]:.1f}  h {B.h[v]:.4f}  crease dist {kt.query(p)[0]:.2f} mm  lever {B.lever[v]*1000:.1f} um')
