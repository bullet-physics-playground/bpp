import numpy as np, shapes
from scipy.spatial import ConvexHull
from gen import fib, surface
from basins import basins
Uf,Ff=shapes.icosphere(7)
Uh,Fh=fib(25000)
for form in (1,2):
    for beta in (0.03,0.04,0.05,0.06,0.07,0.08,0.10):
        Vf=surface(Uf,form,beta); vol,com,I=shapes.mass_props(Vf,Ff)
        s=9.0/np.ptp(Vf-com,axis=0).max()
        V=(surface(Uh,form,beta)-com)*s
        H=ConvexHull(V); P=V[H.vertices]
        B=basins(P,thresh=1e-4)    # 1 µm
        rmin=(np.linalg.norm(V,axis=1)).min(); rmax=np.linalg.norm(V,axis=1).max()
        print(f"form {form} beta {beta:.2f}: basins>1µm {len(B)}  depths µm {[round(b[0]*1e4,1) for b in B[1:4]]}  top-rest {(rmax-B[0][2])*10:.1f} mm  off-hull {100*(1-len(P)/len(V)):.0f}%",flush=True)
