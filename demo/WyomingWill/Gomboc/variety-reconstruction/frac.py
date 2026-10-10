"""How much of the total mass can be spread evenly (over the faces, or along the
edges) before a corner-weighted spiral polyhedron stops working?"""
import numpy as np
import opt21s as o
from optnk import make_verts
from skel import com
def margin(V, f, model):
    c=(1-f)*V.mean(0)+f*com(V,model)
    m=o.margins_c(V,c); return min(m.values())*90/np.ptp(V,axis=0).max()
for name,(n,k,fn) in {"21":(4,5,"nk_4_5.npy"),"26":(5,5,"nk_5_5.npy"),"37":(6,6,"nk_6_6.npy")}.items():
    V=make_verts(n,k)(np.load(fn)); row=[]
    for model in ("faces","edges"):
        lo,hi=0.0,1.0
        if margin(V,1.0,model)>0: row.append(f"{model}: any"); continue
        for _ in range(40):
            mid=(lo+hi)/2
            if margin(V,mid,model)>0: lo=mid
            else: hi=mid
        row.append(f"{model}: up to {lo*100:.1f}% of the mass")
    print(f"{name} corners (point-mass fit): "+";  ".join(row),flush=True)
