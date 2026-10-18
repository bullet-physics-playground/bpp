import numpy as np, sys
from core import *
import sym
from opt2 import unpack
def check(x,n,k,t):
    R,Z,H,zs=unpack(x,n)
    V=ring_verts(k,R,Z,H); fs,_=faces_of(V)
    mp=mass_props(V,fs,t,zs); base=[i for i,f in enumerate(fs) if f[0][2]<-0.9999][0]
    sm=summary_margin(V,fs,mp['com'],base,0); st,un=equilibria(V,fs,mp['com'])
    print(f"3D: faces {len(fs)} verts {len(V)} mass {mp['M']:.1f} g com {np.round(mp['com'],4)} margin face {sm['face']*10:.3f} vert {sm['vert']*10:.3f} mm; stable {len(st)} unstable {len(un)} base-depth {sm['base']*10:.1f} mm")
    P=sym.profile(R,Z,H,k)
    print("profile (apothem, z):", np.round(P,3).tolist())
    for (nr,nz),d in sym.seg_lines(P): print("  seg normal angle from down %.1f deg, n_z %.3f"%(np.degrees(np.arccos(-nz)),nz))
    print("face margins mm", np.round(sym.face_margins(P,mp['com'][2])*10,2), "vertex", np.round(sym.vertex_margins(R,Z,H,k,mp['com'][2])*10,2))
    return V,fs,mp
if __name__=="__main__":
    n,k,t=int(sys.argv[2]),int(sys.argv[3]),float(sys.argv[4])/10
    check(np.load(sys.argv[1]),n,k,t)
