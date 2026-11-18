import os, sys, numpy as np, json
REPO=os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../monostable-search')
sys.path.insert(0,REPO); sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import edged
from sphere_metrics import *
a=np.load(REPO+'/genomes-edged/mono-e2.npy')
out={}
for lev in [int(x) for x in sys.argv[1:]] or (5,6,7):
    Bd=edged.body(a,3,4,lev); X=Bd['X']
    B=Body(X,7)
    ext=np.ptp(B.P,0)
    ws={f'{m}_{s}':round(100*B.weak_share(m,s,h_mode='rest')[0],2) for m in (0.0,0.05) for s in (1.0,1.4,1.5)}
    wl={f'{m}_{s}':round(100*B.weak_share(m,s,h_mode='local')[0],2) for m in (0.0,0.05) for s in (1.0,1.4,1.5)}
    r={'level':lev,'npts':len(X),'hullverts':len(B.P),'vol_cm3':B.vol/1000,'rest_h':B.h.min(),'top_h':B.h.max(),
       'rmax':B.rmax,'rmax_over_rmin':B.rmax/B.rmin,'extents':ext.tolist(),'counts':[list(map(int,c)) for c in B.counts()],
       'angle_rest_top':float(np.degrees(np.arccos(B.rest@B.top))),
       'mins':[(float(d)*1000,) for d,_ in B.mins[1:4]],'maxs':[(float(d)*1000,) for d,_ in B.maxs[1:4]],
       'weak_rest':ws,'weak_local':wl,'rock':{t:list(map(float,B.rocking(t))) for t in (10,15,20,25)},
       'conv_um':Bd['conv']*1000}
    print(json.dumps(r,default=float)); out[lev]=r
    np.save(f'e2_L{lev}_pts.npy',X)
json.dump(out,open(f'e2_metrics_{"_".join(map(str,out))}.json','w'),default=float,indent=1)
