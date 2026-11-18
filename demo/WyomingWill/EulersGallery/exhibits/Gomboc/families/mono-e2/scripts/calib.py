import os, sys, numpy as np, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sphere_metrics import *
fn=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../gomboc-meshes/')+'gomboc-hull.lua'
X=load_lua_points(fn); t=time.time()
B=Body(X,7); print('time',time.time()-t, 'npts',len(B.P))
print('rest h',B.h.min(),'top',B.h.max(),'rmax/rmin',B.rmax/B.rmin, 'counts',B.counts())
for mu in (0.0,0.03,0.05):
  for hm in ('rest','local'):
    print(mu,hm,[round(100*B.weak_share(mu,s,h_mode=hm)[0],1) for s in (1.0,1.4,1.5)])
print('rocking 20deg ring / cap', B.rocking())
