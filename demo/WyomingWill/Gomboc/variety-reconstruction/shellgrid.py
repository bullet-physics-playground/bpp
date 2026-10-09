import numpy as np, opt21s as o
from optnk import make_verts
for n,k in ((4,5),(5,5),(6,6)):
    p=np.load(f"nk_{n}_{k}.npy"); V=make_verts(n,k)(p); V=V*9.0/np.ptp(V,axis=0).max()
    print(f"({n},{k}) {len(V)} vertices, point masses only: margin {o.margins_c(V,V.mean(0))and min(list(o.margins_c(V,V.mean(0)).values()))*10:.2f} mm")
    for t in (0.1,0.3,0.5,1.0):
        row=[]
        for ins in (0.0,0.2,0.4):
            o.T_MM=t; o.M_CORNER=0.0052; o.INSET=ins
            _,ms,c,_,_=o.mass_model(V); m=o.margins_c(V,c); mm=min(m['face'],m['vert'],m['bottom'],m['top'])*10
            row.append(f"weights {ins*10:.0f} mm in: {mm:+.2f}")
        print(f"   shell {t} mm ({ms[len(V):].sum()*1e3:4.1f} g): "+";  ".join(row))
